
from pathlib import Path
from typing import Annotated
from uuid import UUID, uuid4

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse
from sqlalchemy import and_, case, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.social import (
    Connection,
    Conversation,
    SocialMessage,
    SocialPost,
    UserProfile,
)
from app.models.user import User
from app.schemas.social import (
    ConnectionCreate,
    ConnectionPublic,
    ConnectionRespond,
    ConversationPublic,
    MessagePublic,
    PersonSearchResult,
    PostCreate,
    PostPublic,
    ProfilePublic,
    ProfileUpdate,
)


router = APIRouter(prefix="/social", tags=["Social"])

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]

MESSAGE_UPLOAD_DIR = (
    Path(__file__).resolve().parents[2] / "uploads" / "messages"
)
MESSAGE_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

MAX_MESSAGE_IMAGE_SIZE = 8 * 1024 * 1024


# ---------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------

async def get_profile(
    db: AsyncSession,
    user_id: UUID,
) -> UserProfile:
    profile = await db.get(UserProfile, user_id)

    if profile is None:
        profile = UserProfile(user_id=user_id)
        db.add(profile)
        await db.flush()

    return profile


def profile_result(
    user: User,
    profile: UserProfile,
    owner: bool,
) -> ProfilePublic:
    return ProfilePublic(
        user_id=user.id,
        full_name=user.full_name,
        role=user.role,
        is_verified=user.is_verified,
        expert_approval_status=user.expert_approval_status,
        email=user.email if owner or profile.show_email else None,
        phone_number=(
            user.phone_number
            if owner or profile.show_phone
            else None
        ),
        bio=profile.bio,
        location=profile.location,
        photo_url=profile.photo_url,
        specialties=profile.specialties,
        experience_years=profile.experience_years,
        is_public=profile.is_public,
        show_phone=profile.show_phone,
        show_email=profile.show_email,
    )


async def require_accepted_connection(
    db: AsyncSession,
    first_id: UUID,
    second_id: UUID,
) -> None:
    connection = await db.scalar(
        select(Connection).where(
            Connection.status == "accepted",
            or_(
                and_(
                    Connection.requester_id == first_id,
                    Connection.recipient_id == second_id,
                ),
                and_(
                    Connection.requester_id == second_id,
                    Connection.recipient_id == first_id,
                ),
            ),
        )
    )

    if connection is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be connected before messaging.",
        )


async def require_messaging_permission(
    db: AsyncSession,
    first_id: UUID,
    second_id: UUID,
) -> None:
    first = await db.get(User, first_id)
    second = await db.get(User, second_id)

    if first is None or second is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    if not first.is_active or not second.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Messaging is unavailable for inactive accounts.",
        )

    farmer_expert_pair = (
        first.role == "farmer" and second.role == "expert"
    ) or (
        first.role == "expert" and second.role == "farmer"
    )

    if farmer_expert_pair:
        expert = first if first.role == "expert" else second

        if expert.expert_approval_status != "approved":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only approved experts can receive direct messages.",
            )

        return

    await require_accepted_connection(db, first_id, second_id)


def inspect_image(data: bytes) -> tuple[str, str] | None:
    """Return (extension, media_type) for supported image formats."""
    if data.startswith(b"\xff\xd8\xff"):
        return ".jpg", "image/jpeg"

    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png", "image/png"

    if (
        len(data) >= 12
        and data[:4] == b"RIFF"
        and data[8:12] == b"WEBP"
    ):
        return ".webp", "image/webp"

    return None


# ---------------------------------------------------------
# Profiles
# ---------------------------------------------------------

@router.get(
    "/profile/me",
    response_model=ProfilePublic,
)
async def my_profile(
    db: DbSession,
    user: CurrentUser,
):
    profile = await get_profile(db, user.id)
    await db.commit()

    return profile_result(user, profile, True)


@router.patch(
    "/profile/me",
    response_model=ProfilePublic,
)
async def update_my_profile(
    payload: ProfileUpdate,
    db: DbSession,
    user: CurrentUser,
):
    profile = await get_profile(db, user.id)
    updates = payload.model_dump(exclude_unset=True)

    for key, value in updates.items():
        setattr(profile, key, value)

    await db.commit()
    await db.refresh(profile)

    return profile_result(user, profile, True)


@router.get(
    "/people/search",
    response_model=list[PersonSearchResult],
)
async def search_people(
    db: DbSession,
    user: CurrentUser,
    q: str = Query(min_length=2, max_length=255),
):
    term = q.strip()

    if len(term) < 2:
        return []

    if "@" in term:
        search_filter = User.email.ilike(term)
    else:
        search_filter = User.full_name.ilike(f"%{term}%")

    result = await db.scalars(
        select(User)
        .where(
            User.id != user.id,
            User.is_active.is_(True),
            User.role.in_(("farmer", "expert")),
            search_filter,
            or_(
                User.role == "farmer",
                User.expert_approval_status == "approved",
            ),
        )
        .order_by(User.full_name.asc())
        .limit(20)
    )

    return [
        PersonSearchResult(
            user_id=person.id,
            full_name=person.full_name,
            role=person.role,
            is_verified=person.is_verified,
        )
        for person in result.all()
    ]


@router.get(
    "/profile/{user_id}",
    response_model=ProfilePublic,
)
async def view_profile(
    user_id: UUID,
    db: DbSession,
    user: CurrentUser,
):
    target = await db.get(User, user_id)

    if target is None or not target.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found.",
        )

    profile = await get_profile(db, target.id)

    if target.id != user.id and not profile.is_public:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found.",
        )

    await db.commit()

    return profile_result(
        target,
        profile,
        target.id == user.id,
    )


# ---------------------------------------------------------
# Community posts
# ---------------------------------------------------------

POST_UPLOAD_DIR = (
    Path(__file__).resolve().parents[2] / "uploads" / "posts"
)
POST_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def post_result(post: SocialPost, author_name: str) -> PostPublic:
    return PostPublic(
        id=post.id,
        author_id=post.author_id,
        author_name=author_name,
        body=post.body,
        image_url=(
            f"/social/posts/{post.id}/image"
            if post.image_path else None
        ),
        created_at=post.created_at,
    )


@router.post(
    "/posts",
    response_model=PostPublic,
    status_code=status.HTTP_201_CREATED,
)
async def create_post(
    db: DbSession,
    user: CurrentUser,
    body: str = Form(default=""),
    photo: UploadFile | None = File(default=None),
):
    if user.role not in ("farmer", "expert"):
        raise HTTPException(status_code=403, detail="Posting is not allowed.")

    if user.role == "expert" and user.expert_approval_status != "approved":
        raise HTTPException(status_code=403, detail="Expert approval is required.")

    clean_body = body.strip()
    image_path = None

    if photo is not None:
        try:
            data = await photo.read(MAX_MESSAGE_IMAGE_SIZE + 1)
        finally:
            await photo.close()

        if not data:
            raise HTTPException(status_code=400, detail="Uploaded image is empty.")
        if len(data) > MAX_MESSAGE_IMAGE_SIZE:
            raise HTTPException(status_code=413, detail="Images must be 8 MB or smaller.")

        image_info = inspect_image(data)
        if image_info is None:
            raise HTTPException(
                status_code=400,
                detail="Only JPG, PNG, and WebP images are supported.",
            )

        extension, _ = image_info
        image_path = f"{uuid4().hex}{extension}"
        (POST_UPLOAD_DIR / image_path).write_bytes(data)

    if not clean_body and image_path is None:
        raise HTTPException(
            status_code=422,
            detail="Write something or attach an image.",
        )

    post = SocialPost(
        author_id=user.id,
        body=clean_body,
        image_path=image_path,
    )

    try:
        db.add(post)
        await db.commit()
        await db.refresh(post)
    except Exception:
        await db.rollback()
        if image_path:
            (POST_UPLOAD_DIR / image_path).unlink(missing_ok=True)
        raise

    return post_result(post, user.full_name)


@router.get("/feed", response_model=list[PostPublic])
async def get_feed(db: DbSession, user: CurrentUser):
    result = await db.execute(
        select(SocialPost, User.full_name)
        .join(User, User.id == SocialPost.author_id)
        .outerjoin(UserProfile, UserProfile.user_id == User.id)
        .where(
            User.is_active.is_(True),
            or_(
                SocialPost.author_id == user.id,
                UserProfile.user_id.is_(None),
                UserProfile.is_public.is_(True),
            ),
        )
        .order_by(SocialPost.created_at.desc())
        .limit(100)
    )
    return [post_result(post, name) for post, name in result.all()]


@router.get(
    "/people/{user_id}/posts",
    response_model=list[PostPublic],
)
async def get_person_posts(
    user_id: UUID,
    db: DbSession,
    user: CurrentUser,
):
    target = await db.get(User, user_id)
    if target is None or not target.is_active:
        raise HTTPException(status_code=404, detail="Profile not found.")

    profile = await get_profile(db, target.id)
    if target.id != user.id and not profile.is_public:
        raise HTTPException(status_code=404, detail="Profile not found.")

    result = await db.execute(
        select(SocialPost, User.full_name)
        .join(User, User.id == SocialPost.author_id)
        .where(
            SocialPost.author_id == user_id,
            User.is_active.is_(True),
        )
        .order_by(SocialPost.created_at.desc())
        .limit(100)
    )
    return [post_result(post, name) for post, name in result.all()]


@router.get("/posts/{post_id}/image")
async def get_post_image(
    post_id: UUID,
    db: DbSession,
    user: CurrentUser,
):
    post = await db.get(SocialPost, post_id)
    if post is None or not post.image_path:
        raise HTTPException(status_code=404, detail="Image not found.")

    author = await db.get(User, post.author_id)
    profile = await get_profile(db, post.author_id)

    if (
        author is None
        or not author.is_active
        or (post.author_id != user.id and not profile.is_public)
    ):
        raise HTTPException(status_code=404, detail="Image not found.")

    image_file = POST_UPLOAD_DIR / post.image_path
    if not image_file.is_file():
        raise HTTPException(status_code=404, detail="Image file not found.")

    media_type = {
        ".jpg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(image_file.suffix.lower())

    if media_type is None:
        raise HTTPException(status_code=415, detail="Unsupported image format.")

    return FileResponse(path=image_file, media_type=media_type)
# ---------------------------------------------------------
# Connection requests
# ---------------------------------------------------------

@router.post(
    "/connections",
    response_model=ConnectionPublic,
    status_code=status.HTTP_201_CREATED,
)
async def send_connection_request(
    payload: ConnectionCreate,
    db: DbSession,
    user: CurrentUser,
):
    recipient_id = payload.recipient_id

    if recipient_id == user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot connect to yourself.",
        )

    recipient = await db.get(User, recipient_id)

    if recipient is None or not recipient.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    allowed_roles = ("farmer", "expert")

    if (
        user.role not in allowed_roles
        or recipient.role not in allowed_roles
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Connection not allowed.",
        )

    if (
        recipient.role == "expert"
        and recipient.expert_approval_status != "approved"
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This expert is not approved.",
        )

    existing = await db.scalar(
        select(Connection).where(
            or_(
                and_(
                    Connection.requester_id == user.id,
                    Connection.recipient_id == recipient.id,
                ),
                and_(
                    Connection.requester_id == recipient.id,
                    Connection.recipient_id == user.id,
                ),
            )
        )
    )

    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A connection request already exists.",
        )

    connection = Connection(
        requester_id=user.id,
        recipient_id=recipient.id,
        status="pending",
    )

    db.add(connection)
    await db.commit()
    await db.refresh(connection)

    return connection


@router.get(
    "/connections",
    response_model=list[ConnectionPublic],
)
async def list_connections(
    db: DbSession,
    user: CurrentUser,
):
    requester = aliased(User)
    recipient = aliased(User)

    result = await db.execute(
        select(
            Connection,
            requester.full_name,
            recipient.full_name,
        )
        .join(
            requester,
            requester.id == Connection.requester_id,
        )
        .join(
            recipient,
            recipient.id == Connection.recipient_id,
        )
        .where(
            or_(
                Connection.requester_id == user.id,
                Connection.recipient_id == user.id,
            )
        )
        .order_by(Connection.created_at.desc())
    )

    return [
        ConnectionPublic(
            id=connection.id,
            requester_id=connection.requester_id,
            recipient_id=connection.recipient_id,
            status=connection.status,
            created_at=connection.created_at,
            requester_name=requester_name,
            recipient_name=recipient_name,
        )
        for connection, requester_name, recipient_name in result.all()
    ]


@router.patch(
    "/connections/{connection_id}",
    response_model=ConnectionPublic,
)
async def respond_to_request(
    connection_id: UUID,
    payload: ConnectionRespond,
    db: DbSession,
    user: CurrentUser,
):
    connection = await db.get(Connection, connection_id)

    if connection is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Request not found.",
        )

    if connection.recipient_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the recipient can respond.",
        )

    if connection.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This request has already been handled.",
        )

    connection.status = payload.status

    await db.commit()
    await db.refresh(connection)

    return connection


# ---------------------------------------------------------
# Conversations
# ---------------------------------------------------------

@router.get(
    "/conversations",
    response_model=list[ConversationPublic],
)
async def list_conversations(
    db: DbSession,
    user: CurrentUser,
):
    other_user_id = case(
        (
            Conversation.user_one_id == user.id,
            Conversation.user_two_id,
        ),
        else_=Conversation.user_one_id,
    )

    result = await db.execute(
        select(Conversation, User)
        .join(
            User,
            User.id == other_user_id,
        )
        .where(
            or_(
                Conversation.user_one_id == user.id,
                Conversation.user_two_id == user.id,
            )
        )
        .order_by(Conversation.created_at.desc())
    )

    return [
        ConversationPublic(
            id=conversation.id,
            other_user_id=other.id,
            other_user_name=other.full_name,
            created_at=conversation.created_at,
        )
        for conversation, other in result.all()
    ]


@router.post(
    "/conversations/{other_user_id}",
    response_model=ConversationPublic,
    status_code=status.HTTP_201_CREATED,
)
async def start_conversation(
    other_user_id: UUID,
    db: DbSession,
    user: CurrentUser,
):
    if other_user_id == user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid recipient.",
        )

    other = await db.get(User, other_user_id)

    if other is None or not other.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found.",
        )

    await require_messaging_permission(
        db,
        user.id,
        other_user_id,
    )

    first, second = sorted(
        (user.id, other_user_id),
        key=str,
    )

    conversation = await db.scalar(
        select(Conversation).where(
            Conversation.user_one_id == first,
            Conversation.user_two_id == second,
        )
    )

    if conversation is None:
        conversation = Conversation(
            user_one_id=first,
            user_two_id=second,
        )

        db.add(conversation)
        await db.commit()
        await db.refresh(conversation)

    return ConversationPublic(
        id=conversation.id,
        other_user_id=other.id,
        other_user_name=other.full_name,
        created_at=conversation.created_at,
    )


# ---------------------------------------------------------
# Messages
# ---------------------------------------------------------

@router.get(
    "/conversations/{conversation_id}/messages",
    response_model=list[MessagePublic],
)
async def get_messages(
    conversation_id: UUID,
    db: DbSession,
    user: CurrentUser,
):
    conversation = await db.get(
        Conversation,
        conversation_id,
    )

    if conversation is None or user.id not in (
        conversation.user_one_id,
        conversation.user_two_id,
    ):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found.",
        )

    other_id = (
        conversation.user_two_id
        if conversation.user_one_id == user.id
        else conversation.user_one_id
    )

    await require_messaging_permission(
        db,
        user.id,
        other_id,
    )

    result = await db.scalars(
        select(SocialMessage)
        .where(
            SocialMessage.conversation_id == conversation_id,
        )
        .order_by(SocialMessage.created_at.asc())
        .limit(500)
    )

    return [
        MessagePublic(
            id=message.id,
            conversation_id=message.conversation_id,
            sender_id=message.sender_id,
            body=message.body,
            image_url=(
                f"/social/messages/{message.id}/image"
                if message.image_path
                else None
            ),
            created_at=message.created_at,
        )
        for message in result.all()
    ]


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=MessagePublic,
    status_code=status.HTTP_201_CREATED,
)
async def send_message(
    conversation_id: UUID,
    db: DbSession,
    user: CurrentUser,
    body: str = Form(default=""),
    photo: UploadFile | None = File(default=None),
):
    conversation = await db.get(
        Conversation,
        conversation_id,
    )

    if conversation is None or user.id not in (
        conversation.user_one_id,
        conversation.user_two_id,
    ):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found.",
        )

    other_id = (
        conversation.user_two_id
        if conversation.user_one_id == user.id
        else conversation.user_one_id
    )

    await require_messaging_permission(
        db,
        user.id,
        other_id,
    )

    clean_body = body.strip()

    image_path = None

    if photo is not None:
        try:
            image_data = await photo.read(MAX_MESSAGE_IMAGE_SIZE + 1)
        finally:
            await photo.close()

        if not image_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="The uploaded image is empty.",
            )

        if len(image_data) > MAX_MESSAGE_IMAGE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Images must be 8 MB or smaller.",
            )

        image_info = inspect_image(image_data)

        if image_info is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only JPG, PNG, and WebP images are supported.",
            )

        extension, _media_type = image_info
        filename = f"{uuid4().hex}{extension}"
        destination = MESSAGE_UPLOAD_DIR / filename

        destination.write_bytes(image_data)
        image_path = filename

    if not clean_body and image_path is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Write a message or attach an image.",
        )

    message = SocialMessage(
        conversation_id=conversation.id,
        sender_id=user.id,
        body=clean_body,
        image_path=image_path,
    )

    try:
        db.add(message)
        await db.commit()
        await db.refresh(message)
    except Exception:
        await db.rollback()

        if image_path:
            (MESSAGE_UPLOAD_DIR / image_path).unlink(missing_ok=True)

        raise

    return MessagePublic(
        id=message.id,
        conversation_id=message.conversation_id,
        sender_id=message.sender_id,
        body=message.body,
        image_url=(
            f"/social/messages/{message.id}/image"
            if message.image_path
            else None
        ),
        created_at=message.created_at,
    )


@router.get(
    "/messages/{message_id}/image",
)
async def get_message_image(
    message_id: UUID,
    db: DbSession,
    user: CurrentUser,
):
    message = await db.get(SocialMessage, message_id)

    if message is None or not message.image_path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image not found.",
        )

    conversation = await db.get(
        Conversation,
        message.conversation_id,
    )

    if conversation is None or user.id not in (
        conversation.user_one_id,
        conversation.user_two_id,
    ):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image not found.",
        )

    other_id = (
        conversation.user_two_id
        if conversation.user_one_id == user.id
        else conversation.user_one_id
    )

    await require_messaging_permission(
        db,
        user.id,
        other_id,
    )

    image_file = MESSAGE_UPLOAD_DIR / message.image_path

    if not image_file.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image file not found.",
        )

    extension = image_file.suffix.lower()

    media_type = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(extension)

    if media_type is None:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Unsupported image format.",
        )

    return FileResponse(
        path=image_file,
        media_type=media_type,
    )
