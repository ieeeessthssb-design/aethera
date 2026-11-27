
import logging
from email.message import EmailMessage
from html import escape

import aiosmtplib

from app.core.config import settings

logger = logging.getLogger(__name__)


def _verification_email_content(
    code: str,
    language: str,
) -> tuple[str, str, str]:

    translations = {
        "en": {
            "subject": "Verify your AETHERA account",
            "greeting": "Hi there!",
            "intro": "Thanks for joining AETHERA. Please use the verification code below to confirm your email address.",
            "label": "YOUR VERIFICATION CODE",
            "expiry": "This code expires in 10 minutes. If it expires, you can request a new one.",
            "security": "For your security, never share this code with anyone.",
            "ignore": "If you didn't request this code, you can safely ignore this email.",
            "footer": "Growing a smarter future.",
            "team": "The AETHERA Team",
            "copy": "Select and copy your code",
        },
        "fr": {
            "subject": "Vérifiez votre compte AETHERA",
            "greeting": "Bonjour !",
            "intro": "Merci d'avoir rejoint AETHERA. Utilisez le code ci-dessous pour confirmer votre adresse e-mail.",
            "label": "VOTRE CODE DE VÉRIFICATION",
            "expiry": "Ce code expire dans 10 minutes. Vous pouvez en demander un nouveau après son expiration.",
            "security": "Pour votre sécurité, ne partagez jamais ce code.",
            "ignore": "Si vous n'avez pas demandé ce code, ignorez cet e-mail.",
            "footer": "Cultivons un avenir plus intelligent.",
            "team": "L'équipe AETHERA",
            "copy": "Sélectionnez et copiez votre code",
        },
        "ar": {
            "subject": "تأكيد حسابك في آثيرة",
            "greeting": "مرحباً بك!",
            "intro": "شكراً لانضمامك إلى آثيرة. استخدم رمز التحقق أدناه لتأكيد بريدك الإلكتروني.",
            "label": "رمز التحقق الخاص بك",
            "expiry": "تنتهي صلاحية هذا الرمز خلال 10 دقائق. يمكنك طلب رمز جديد بعد انتهاء صلاحيته.",
            "security": "من أجل أمانك، لا تشارك هذا الرمز مع أي شخص.",
            "ignore": "إذا لم تطلب هذا الرمز، يمكنك تجاهل هذه الرسالة.",
            "footer": "نزرع اليوم مستقبلاً أكثر ذكاءً.",
            "team": "فريق آثيرة",
            "copy": "يمكنك تحديد الرمز ونسخه",
        },
    }

    lang = language if language in translations else "en"
    t = translations[lang]

    direction = "rtl" if lang == "ar" else "ltr"
    alignment = "right" if lang == "ar" else "left"

    safe_code = escape(str(code))

    plain_text = f"""{t['greeting']}

{t['intro']}

{t['label']}: {code}

{t['expiry']}

{t['security']}

{t['ignore']}

{t['footer']}
{t['team']}
"""

    html_content = f"""\
<!DOCTYPE html>
<html lang="{lang}" dir="{direction}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light">
    <title>{escape(t['subject'])}</title>
</head>
<body style="
    margin: 0;
    padding: 30px 12px;
    background-color: #e9eeeb;
    font-family: Arial, Helvetica, sans-serif;
    color: #28372e;
">
    <table role="presentation" width="100%" cellspacing="0"
           cellpadding="0" border="0">
        <tr>
            <td align="center">

                <table role="presentation" width="100%" cellspacing="0"
                       cellpadding="0" border="0"
                       style="
                           max-width: 560px;
                           background-color: #ffffff;
                           border-radius: 12px;
                           overflow: hidden;
                       ">

                    <!-- Brand header -->
                    <tr>
                        <td style="
                            padding: 30px 32px 24px;
                            text-align: {alignment};
                        ">
                            <div style="
                                color: #214c39;
                                font-size: 27px;
                                font-weight: 800;
                                letter-spacing: 2px;
                            ">
                                AETHERA
                            </div>
                            <div style="
                                margin-top: 5px;
                                color: #829489;
                                font-size: 10px;
                                letter-spacing: 2px;
                            ">
                                SMART AGRICULTURE
                            </div>
                        </td>
                    </tr>

                    <tr>
                        <td style="padding: 0 32px;">
                            <div style="
                                height: 1px;
                                background-color: #e9eee9;
                            "></div>
                        </td>
                    </tr>

                    <!-- Email content -->
                    <tr>
                        <td style="
                            padding: 32px;
                            text-align: {alignment};
                        ">
                            <h1 style="
                                margin: 0 0 16px;
                                color: #214c39;
                                font-size: 25px;
                                line-height: 1.4;
                            ">
                                {escape(t['greeting'])}
                            </h1>

                            <p style="
                                margin: 0 0 28px;
                                color: #58645c;
                                font-size: 15px;
                                line-height: 1.8;
                            ">
                                {escape(t['intro'])}
                            </p>

                            <!-- OTP code box -->
                            <table role="presentation" width="100%"
                                   cellspacing="0" cellpadding="0" border="0"
                                   style="
                                       background-color: #eff5f0;
                                       border: 1px solid #e0ebe2;
                                       border-radius: 10px;
                                   ">
                                <tr>
                                    <td align="center"
                                        style="padding: 25px 12px;">
                                        <div style="
                                            margin-bottom: 13px;
                                            color: #607568;
                                            font-size: 11px;
                                            font-weight: bold;
                                            letter-spacing: 2px;
                                        ">
                                            {escape(t['label'])}
                                        </div>

                                        <div dir="ltr" style="
                                            color: #214c39;
                                            font-family: Arial, sans-serif;
                                            font-size: 34px;
                                            font-weight: 800;
                                            letter-spacing: 9px;
                                            line-height: 1.5;
                                            overflow-wrap: anywhere;
                                        ">
                                            {safe_code}
                                        </div>

                                        <div style="
                                            margin-top: 12px;
                                            color: #819187;
                                            font-size: 11px;
                                        ">
                                            {escape(t['copy'])}
                                        </div>
                                    </td>
                                </tr>
                            </table>

                            <p style="
                                margin: 26px 0 15px;
                                color: #58645c;
                                font-size: 14px;
                                line-height: 1.8;
                            ">
                                {escape(t['expiry'])}
                            </p>

                            <p style="
                                margin: 0 0 15px;
                                color: #58645c;
                                font-size: 14px;
                                line-height: 1.8;
                            ">
                                {escape(t['security'])}
                            </p>

                            <p style="
                                margin: 0;
                                color: #849087;
                                font-size: 12px;
                                line-height: 1.7;
                            ">
                                {escape(t['ignore'])}
                            </p>
                        </td>
                    </tr>

                    <!-- Footer -->
                    <tr>
                        <td style="
                            padding: 24px 32px 30px;
                            background-color: #f3f6f3;
                            text-align: center;
                        ">
                            <div style="
                                color: #214c39;
                                font-size: 15px;
                                font-weight: bold;
                            ">
                                {escape(t['footer'])}
                            </div>

                            <div style="
                                margin-top: 8px;
                                color: #819187;
                                font-size: 12px;
                            ">
                                {escape(t['team'])}
                            </div>
                        </td>
                    </tr>

                </table>

                <p style="
                    margin: 20px 0 0;
                    color: #94a098;
                    font-size: 11px;
                    text-align: center;
                ">
                    © AETHERA. All rights reserved.
                </p>

            </td>
        </tr>
    </table>
</body>
</html>
"""

    return t["subject"], plain_text, html_content


async def send_verification_email(
    recipient_email: str,
    code: str,
    language: str = "en",
) -> None:

    if not settings.smtp_username:
        raise RuntimeError("SMTP username is not configured.")

    if not settings.smtp_password:
        raise RuntimeError("SMTP password is not configured.")

    sender = settings.smtp_from_email or settings.smtp_username

    subject, plain_text, html_content = _verification_email_content(
        code,
        language,
    )

    message = EmailMessage()
    message["From"] = sender
    message["To"] = recipient_email
    message["Subject"] = subject

    message.set_content(plain_text)
    message.add_alternative(html_content, subtype="html")

    try:
        await aiosmtplib.send(
            message,
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            username=settings.smtp_username,
            password=settings.smtp_password,
            start_tls=True,
        )

        logger.info("Verification email sent successfully.")

    except Exception:
        logger.exception(
            "SMTP delivery failed. Host=%s, Port=%s",
            settings.smtp_host,
            settings.smtp_port,
        )
        raise
