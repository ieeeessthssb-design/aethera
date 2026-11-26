// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'آثيرة';

  @override
  String get welcomeTitle => 'ازرع بذكاء. واحصد أفضل.';

  @override
  String get welcomeSubtitle => 'مرافقك الذكي في الفلاحة.';

  @override
  String get dashboardTitle => 'نظرة شاملة على ضيعتك';

  @override
  String get dashboardSubtitle => 'كل ما تحتاجه لمتابعة فلاحتك بثقة.';

  @override
  String get greeting => 'مرحبا بيك من جديد!';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get settings => 'الإعدادات';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'حسب الجهاز';

  @override
  String get english => 'الإنجليزية';

  @override
  String get french => 'الفرنسية';

  @override
  String get arabic => 'العربية';

  @override
  String get assistant => 'المساعد الذكي';

  @override
  String get diagnosis => 'تشخيص المحاصيل';

  @override
  String get irrigation => 'الري الذكي';

  @override
  String get community => 'مجتمع الفلاحين';

  @override
  String get profile => 'ملفي الشخصي';

  @override
  String get weather => 'الطقس';

  @override
  String get soilMoisture => 'رطوبة التربة';

  @override
  String get preferences => 'تفضيلات التطبيق';

  @override
  String get chooseLanguage => 'اختار اللغة';

  @override
  String get chooseTheme => 'اختار المظهر';

  @override
  String get backToHome => 'الرجوع للرئيسية';

  @override
  String get home => 'الرئيسية';

  @override
  String get farms => 'ضيعاتي';

  @override
  String get messages => 'الرسائل';

  @override
  String get collapseSidebar => 'طي الشريط الجانبي';

  @override
  String get expandSidebar => 'توسيع الشريط الجانبي';

  @override
  String get openNavigation => 'فتح قائمة التنقل';

  @override
  String get account => 'الحساب';

  @override
  String get managePersonalDetails => 'إدارة معلوماتك الشخصية';

  @override
  String get manageAccountPreferences => 'إدارة حسابك وتفضيلاتك في آثيرة.';

  @override
  String get farmerAccount => 'حساب فلاح';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get personalInformationMessage => 'ستظهر معلومات حسابك الفلاحي هنا.';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get helpSupportMessage =>
      'للحصول على مساعدة بخصوص آثيرة، اتصل بفريق الدعم.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutQuestion => 'تسجيل الخروج؟';

  @override
  String get logoutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get addFarm => 'إضافة ضيعة';

  @override
  String get farmName => 'اسم الضيعة *';

  @override
  String get location => 'الموقع *';

  @override
  String get areaHectares => 'المساحة بالهكتار';

  @override
  String get soilType => 'نوع التربة';

  @override
  String get irrigationType => 'نوع الري';

  @override
  String get saveFarm => 'حفظ الضيعة';

  @override
  String get farmAdded => 'تمت إضافة الضيعة بنجاح!';

  @override
  String get farmLoadError => 'تعذر تحميل الضيعات. تحقق من اتصالك بالإنترنت.';

  @override
  String farmSaveError(String error) {
    return 'تعذر حفظ الضيعة: $error';
  }

  @override
  String get noFarms => 'لا توجد ضيعات مضافة بعد';

  @override
  String get addFirstFarm => 'اضغط على إضافة ضيعة لتسجيل ضيعتك الأولى.';

  @override
  String get yourFarms => 'ضيعاتك';

  @override
  String get manageFarms => 'إدارة أراضيك وأنشطتك الفلاحية.';

  @override
  String get tryAgain => 'أعد المحاولة';

  @override
  String get enterTwoChars => 'يرجى إدخال حرفين على الأقل.';

  @override
  String get enterPositiveNumber => 'أدخل رقماً أكبر من الصفر.';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get area => 'المساحة';

  @override
  String get save => 'حفظ';

  @override
  String get chooseFarm => 'اختر ضيعة';

  @override
  String get locationExample => 'مثال: سوسة، تونس';

  @override
  String get areaExample => 'مثال: 5.5';

  @override
  String get soilExample => 'مثال: طينية، رملية، طميية';

  @override
  String get irrigationExample => 'مثال: الري بالتنقيط أو الرش';

  @override
  String get hectares => 'هكتار';

  @override
  String get fieldIntelligence => 'ذكاء آثيرة الفلاحي';

  @override
  String get fieldTagline => 'كل قرار في الحقل يصنع الفرق.';

  @override
  String get fieldDescription =>
      'اسأل عن الري وأعراض المحاصيل والعناية بالمزرعة.';

  @override
  String get exploreTools => 'اكتشف أدواتك';

  @override
  String get talkToAethera => 'تحدث مع آثيرة';

  @override
  String get voiceAssistantDescription =>
      'اضغط مطولاً على الميكروفون للتحدث بالدارجة التونسية.';

  @override
  String get voiceTitle => 'المساعد الفلاحي';

  @override
  String get voiceListening => 'نستمع إليك… تحدث الآن';

  @override
  String get voiceSpeaking => 'آثيرة تجيبك…';

  @override
  String get voiceWelcome => 'مرحبا بك في آثيرة';

  @override
  String get voiceListeningHint => 'اترك الميكروفون عندما تنتهي من الكلام.';

  @override
  String get voiceInstruction => 'اضغط مطولاً على الميكروفون للتحدث.';

  @override
  String get voicePressHold => 'اضغط مطولاً للتحدث';

  @override
  String get voiceInputHint => 'أو اكتب سؤالك هنا…';

  @override
  String get voiceAsk => 'اسأل آثيرة';

  @override
  String get voiceQuestion => 'سؤالك';

  @override
  String get voiceNoQuestion => 'لم يتم تسجيل أي سؤال بعد.';

  @override
  String get voiceAnswer => 'الإجابة';

  @override
  String get voiceStopAudio => 'إيقاف الصوت';

  @override
  String get voiceListenAnswer => 'استمع إلى الإجابة';

  @override
  String get voiceDisclaimer =>
      'هذه الإرشادات أولية. عند وجود مرض أو آفة غير واضحة، استشر خبيراً فلاحياً قبل استعمال أي علاج.';

  @override
  String get voiceSpeechUnavailable =>
      'التعرّف على الصوت غير متاح. يمكنك كتابة سؤالك بدلاً من ذلك.';

  @override
  String get voiceMicError => 'تعذّر تشغيل الميكروفون.';

  @override
  String get voiceAudioError => 'تعذّر تشغيل الصوت. يمكنك قراءة الإجابة.';

  @override
  String get voiceAnswerWater =>
      'تثبّت من رطوبة التربة قبل الري. تجنّب الإفراط في الماء وراعِ نوع الزراعة والتربة والطقس.';

  @override
  String get voiceAnswerYellow =>
      'قد ينتج اصفرار الأوراق عن نقص الماء أو زيادته أو نقص العناصر الغذائية. افحص رطوبة التربة وحدد الأوراق المتأثرة. قد يتطلب التشخيص الدقيق صورة ومراجعة خبير.';

  @override
  String get voiceAnswerPest =>
      'إذا اشتبهت في مرض أو حشرة، صوّر النبتة والأوراق المصابة. لا تستعمل مبيداً قبل تحديد المشكلة، واعرض الصورة على خبير فلاحي.';

  @override
  String get voiceAnswerTomato =>
      'في زراعة الطماطم، راقب رطوبة التربة وتجنب الإفراط في الري. افحص الأوراق والثمار واستشر خبيراً عند ظهور أعراض.';

  @override
  String get voiceAnswerOlive =>
      'بالنسبة للزيتون، راقب الأوراق والتربة والطقس. تختلف حاجات الري حسب عمر الشجرة ونوع التربة والمرحلة الزراعية.';

  @override
  String get voiceAnswerGeneral =>
      'وصلني سؤالك. يمكنني تقديم إرشادات أولية حول الري والزراعة والأعراض الشائعة. النصائح الذكية المخصصة تتطلب ربط خدمة ذكاء اصطناعي. يمكنك أيضاً التواصل مع خبير فلاحي عبر المجتمع.';

  @override
  String get weatherFarmTitle => 'الطقس في مزرعتك';

  @override
  String get weatherSearchHint => 'ابحث عن مدينة أو منطقة';

  @override
  String get weatherChooseLocation => 'اختر موقع مزرعتك';

  @override
  String get weatherSearchDescription =>
      'ابحث عن المدينة أو المنطقة التي تقع فيها مزرعتك لعرض التوقعات.';

  @override
  String get weatherFeelsLike => 'المحسوس';

  @override
  String get weatherNextHours => 'الساعات القادمة';

  @override
  String get weatherOutlook => 'توقعات 7 أيام';

  @override
  String get weatherChanges => 'تغيرات ملحوظة';

  @override
  String get weatherNoChanges =>
      'لا توجد تغيّرات ملحوظة خلال الـ24 ساعة القادمة.';

  @override
  String get weatherSource =>
      'مصدر بيانات الطقس: Open-Meteo. التوقعات تقديرية وليست مضمونة.';

  @override
  String get weatherRain => 'الأمطار';

  @override
  String get weatherHumidity => 'الرطوبة';

  @override
  String get weatherWind => 'الرياح';

  @override
  String get weatherRainNow => 'الأمطار الآن';

  @override
  String get weatherWindDirection => 'اتجاه الرياح';

  @override
  String get weatherSunrise => 'شروق الشمس';

  @override
  String get weatherSunset => 'غروب الشمس';

  @override
  String get weatherUv => 'أقصى مؤشر أشعة فوق بنفسجية اليوم';

  @override
  String get weatherSelectedLocation => 'الموقع المحدد';

  @override
  String get weatherLoadError =>
      'تعذّر تحميل الطقس. تحقق من اتصال API والموقع.';

  @override
  String get weatherRainProbability => 'مطر';

  @override
  String get weatherOutlookSubtitle => 'توقعات الطقس وتغيرات ظروف الحقل.';

  @override
  String get diagnosisSubtitle => 'التقط صورة للمحصول لتحليله.';

  @override
  String get irrigationSubtitle => 'راجع أدوات وجدولة الري.';

  @override
  String get authGoogleError => 'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.';

  @override
  String get authAcceptTerms => 'يرجى الموافقة على الشروط وسياسة الخصوصية.';

  @override
  String get authEmailVerified =>
      'تم التحقق من البريد الإلكتروني! يرجى تسجيل الدخول.';

  @override
  String get authCodeSent => 'تم إرسال رمز التحقق إلى بريدك الإلكتروني.';

  @override
  String get authNewCodeSent => 'تم إرسال رمز جديد.';

  @override
  String get communityRefresh => 'تحديث المنشورات';

  @override
  String get communitySearch => 'ابحث بالاسم...';

  @override
  String get communityAsk => 'اسأل';

  @override
  String get communityRemovePhoto => 'إزالة الصورة';

  @override
  String get communityAddPhoto => 'إضافة صورة';

  @override
  String get communityAccept => 'قبول';

  @override
  String get communityDecline => 'رفض';

  @override
  String get communityRetry => 'إعادة المحاولة';

  @override
  String get communityConnectionSent => 'تم إرسال طلب التواصل إلى';

  @override
  String get communityImageError => 'تعذّر اختيار الصورة';

  @override
  String get communityPostTooLong => 'لا يمكن أن تتجاوز المنشورات 5000 حرف.';

  @override
  String get communityPostPublished => 'تم نشر منشورك.';

  @override
  String get messageTooLong => 'لا يمكن أن تتجاوز الرسائل 5000 حرف.';

  @override
  String get messageHint => 'اكتب رسالة...';

  @override
  String get messageRetry => 'حاول مرة أخرى';

  @override
  String get expertQueueTitle => 'قائمة مراجعة التشخيصات';

  @override
  String get expertPhotoUnavailable => 'الصورة غير متاحة';

  @override
  String get expertRefresh => 'تحديث القائمة';

  @override
  String get expertCancel => 'إلغاء';

  @override
  String get expertReject => 'رفض';

  @override
  String get expertValidate => 'تأكيد';

  @override
  String get expertLogoutQuestion => 'تسجيل الخروج؟';

  @override
  String get irrigationRetry => 'حاول مرة أخرى';

  @override
  String get irrigationRefresh => 'تحديث الأجهزة';

  @override
  String get irrigationTitle => 'الري الذكي';

  @override
  String get irrigationLoadFarmsError => 'تعذّر تحميل مزارعك.';

  @override
  String get irrigationNoFarms => 'لا توجد مزارع بعد';

  @override
  String get irrigationAddFarmFirst => 'أضف مزرعة أولاً لعرض أجهزة الري.';

  @override
  String get irrigationSelectFarm => 'اختر المزرعة';

  @override
  String get irrigationConnectedDevices => 'الأجهزة المتصلة';

  @override
  String get irrigationLoadDevicesError => 'تعذّر تحميل أجهزة الري.';

  @override
  String get irrigationNoDevices => 'لا توجد أجهزة متصلة';

  @override
  String get irrigationNoDevicesDescription =>
      'لا توجد أجهزة مسجلة لهذه المزرعة حتى الآن.';

  @override
  String get irrigationInfo =>
      'تُعرض قراءات الأجهزة عند توفرها. واجهة API المتصلة لا تدعم حالياً التحكم في الري أو جدولته.';

  @override
  String get irrigationMonitorFarm => 'راقب مزرعتك';

  @override
  String get irrigationMonitorDescription =>
      'اعرض أجهزة الري المتصلة وآخر قراءاتها.';

  @override
  String get irrigationDevice => 'جهاز الري';

  @override
  String get irrigationRegistered => 'مسجل';

  @override
  String get irrigationDeviceIdUnavailable => 'معرّف الجهاز غير متاح';

  @override
  String get irrigationLatestReading => 'آخر قراءة';

  @override
  String get irrigationDeviceIdUnreadable =>
      'لا يملك هذا الجهاز معرّفاً قابلاً للقراءة.';

  @override
  String get irrigationReadingUnavailable => 'آخر قراءة غير متاحة حالياً.';

  @override
  String get irrigationNoReadings => 'لم يتم تسجيل أي قراءات لهذا الجهاز بعد.';

  @override
  String get dashboardOperations => 'عمليات المزرعة';

  @override
  String get dashboardDevices => 'الأجهزة المسجلة';

  @override
  String get dashboardViewIrrigation => 'عرض الري';

  @override
  String get dashboardNoDevices => 'لا توجد أجهزة مسجلة لهذه المزرعة.';

  @override
  String get dashboardDeviceLoadError => 'تعذر تحميل حالة الأجهزة.';

  @override
  String get dashboardActive => 'نشط';

  @override
  String get dashboardInactive => 'غير نشط';

  @override
  String get dashboardLatestMoisture => 'آخر قياس لرطوبة التربة';

  @override
  String get dashboardNoReading => 'لا توجد قراءات للمستشعر بعد';

  @override
  String dashboardReadingTime(String time) {
    return 'سُجل في $time';
  }

  @override
  String get dashboardSimulated => 'قراءة تجريبية';

  @override
  String get dashboardWeatherAction => 'فتح توقعات الطقس';

  @override
  String get dashboardFarmProfile => 'ملف المزرعة';

  @override
  String get dashboardAlerts => 'تنبيهات المزرعة';

  @override
  String get dashboardNoAlerts =>
      'لا توجد تنبيهات نشطة. ستظهر أحداث المستشعرات هنا عند بلوغ الحدود المحددة.';

  @override
  String get dashboardAcknowledge => 'تأكيد الاطلاع';

  @override
  String get dashboardOnline => 'متصل';

  @override
  String get dashboardStale => 'البيانات قديمة';

  @override
  String get dashboardUnknown => 'غير معروف';

  @override
  String get dashboardDisabled => 'معطّل';

  @override
  String get weatherLocationSaved => 'تم حفظ موقع المزرعة.';
}
