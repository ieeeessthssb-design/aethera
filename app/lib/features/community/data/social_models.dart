class SocialProfile {
  const SocialProfile({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.isVerified,
    required this.expertApprovalStatus,
    required this.isPublic,
    required this.showPhone,
    required this.showEmail,
    this.email,
    this.phoneNumber,
    this.bio,
    this.location,
    this.photoUrl,
    this.specialties,
    this.experienceYears,
  });

  final String userId;
  final String fullName;
  final String role;
  final bool isVerified;
  final String expertApprovalStatus;
  final String? email;
  final String? phoneNumber;
  final String? bio;
  final String? location;
  final String? photoUrl;
  final String? specialties;
  final int? experienceYears;
  final bool isPublic;
  final bool showPhone;
  final bool showEmail;

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      userId: json['user_id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'farmer',
      isVerified: json['is_verified'] as bool? ?? false,
      expertApprovalStatus: json['expert_approval_status'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      photoUrl: json['photo_url'] as String?,
      specialties: json['specialties'] as String?,
      experienceYears: json['experience_years'] as int?,
      isPublic: json['is_public'] as bool? ?? true,
      showPhone: json['show_phone'] as bool? ?? false,
      showEmail: json['show_email'] as bool? ?? false,
    );
  }
}


class SocialPost {
  const SocialPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final String? imageUrl;

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'].toString(),
      authorId: json['author_id'].toString(),
      authorName: json['author_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      imageUrl: json['image_url'] as String?,
    );
  }
}


class SocialConnection {
  const SocialConnection({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String requesterId;
  final String recipientId;
  final String status;
  final DateTime createdAt;

  factory SocialConnection.fromJson(Map<String, dynamic> json) {
    return SocialConnection(
      id: json['id'].toString(),
      requesterId: json['requester_id'].toString(),
      recipientId: json['recipient_id'].toString(),
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class SocialConversation {
  const SocialConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.createdAt,
  });

  final String id;
  final String otherUserId;
  final String otherUserName;
  final DateTime createdAt;

  factory SocialConversation.fromJson(Map<String, dynamic> json) {
    return SocialConversation(
      id: json['id'].toString(),
      otherUserId: json['other_user_id'].toString(),
      otherUserName: json['other_user_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class SocialMessage {
  const SocialMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory SocialMessage.fromJson(Map<String, dynamic> json) {
    return SocialMessage(
      id: json['id'].toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'].toString(),
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}
class PersonSearchResult {
  const PersonSearchResult({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.isVerified,
  });

  final String userId;
  final String fullName;
  final String role;
  final bool isVerified;

  factory PersonSearchResult.fromJson(Map<String, dynamic> json) {
    return PersonSearchResult(
      userId: json['user_id'].toString(),
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'farmer',
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}
