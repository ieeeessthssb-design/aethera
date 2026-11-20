import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/colors.dart';

enum Lang { ar, fr }

/// [arabic, french] dictionary, ported 1:1 from the web app (src/lib/i18n.tsx).
const Map<String, List<String>> _d = {
  // nav
  'nav.Dashboard': ['لوحة القيادة', 'Tableau de bord'],
  'nav.My Farm': ['ضيعتي', 'Ma ferme'],
  'nav.Guide Me': ['وجّهني', 'Guidez-moi'],
  'nav.Quick Assist': ['مساعدة سريعة', 'Aide rapide'],
  'nav.Diagnose': ['تشخيص', 'Diagnostic'],
  'nav.Irrigation': ['السقي', 'Irrigation'],
  'nav.Crop Plan': ['برنامج الزراعة', 'Plan de culture'],
  'nav.Alerts': ['التنبيهات', 'Alertes'],
  'nav.Risk Radar': ['رادار المخاطر', 'Radar des risques'],
  'nav.Risk Review': ['مراجعة المخاطر', 'Revue des risques'],
  'nav.Knowledge Hub': ['المعرفة', 'Savoirs'],
  'nav.Community': ['المجتمع', 'Communauté'],
  'nav.Experts': ['الخبراء', 'Experts'],
  'nav.Profile': ['حسابي', 'Profil'],
  'nav.Cases': ['الحالات', 'Dossiers'],
  'nav.Knowledge Base': ['قاعدة المعرفة', 'Base de savoirs'],
  'nav.Contributions': ['المساهمات', 'Contributions'],
  'nav.Messages': ['الرسائل', 'Messages'],
  'nav.Users': ['المستخدمون', 'Utilisateurs'],
  'nav.Knowledge Validation': ['التحقق من المعرفة', 'Validation'],
  'nav.Reports': ['التقارير', 'Rapports'],
  'nav.More': ['المزيد', 'Plus'],
  // auth
  'signIn': ['دخول', 'Se connecter'],
  'signUp': ['حساب جديد', 'Créer un compte'],
  'signOut': ['خروج', 'Se déconnecter'],
  'email': ['البريد الإلكتروني', 'E-mail'],
  'password': ['كلمة السر', 'Mot de passe'],
  'google': ['الدخول بـ Google', 'Continuer avec Google'],
  'checkEmail': [
    'ثبّت بريدك باش تكمّل التسجيل.',
    "Vérifiez votre e-mail pour confirmer l'inscription."
  ],
  'needSignIn': [
    'لازم تدخل لحسابك باش تستعمل هذا.',
    'Connectez-vous pour utiliser cette fonction.'
  ],
  // radar
  'radarTitle': ['رادار المخاطر الجهوية', 'Radar des risques régionaux'],
  'radarDesc': [
    'تنبيهات محتملة مبنية على بلاغات الفلاحين القريبين. موش تأكيد لوباء.',
    "Risques potentiels basés sur les signalements d'agriculteurs proches. Ce n'est pas une preuve d'épidémie."
  ],
  'reportProblem': ['بلّغ على مشكلة', 'Signaler un problème'],
  'potentialRisk': ['خطر محتمل', 'Risque potentiel'],
  'reports': ['بلاغات', 'signalements'],
  'similarReports': ['بلاغات متشابهة', 'signalements similaires'],
  'severity': ['الخطورة', 'Gravité'],
  'updated': ['آخر تحديث', 'Mis à jour'],
  'source': ['المصدر: بلاغات الفلاحين', "Source : signalements d'agriculteurs"],
  'demoData': ['بيانات تجريبية', 'Données de démonstration'],
  'noAlerts': ['ما فماش تنبيهات توّا.', 'Aucune alerte pour le moment.'],
  'preventive': ['خطوات وقائية', 'Mesures préventives'],
  'seeToo': ['نشوف فيها زادة', 'Je vois la même chose'],
  'notOnFarm': ['موش في ضيعتي', 'Pas chez moi'],
  'thanksResponse': ['شكرا، تسجّل جوابك.', 'Merci, réponse enregistrée.'],
  'viewRadar': ['شوف الرادار', 'Voir le radar'],
  'nearYou': ['قريب منك', 'Près de vous'],
  'myReports': ['بلاغاتي', 'Mes signalements'],
  'noReports': ['ما بعثتش بلاغات.', 'Aucun signalement envoyé.'],
  'inCluster': ['داخل في تنبيه', 'Lié à une alerte'],
  'waiting': ['في الانتظار', 'En attente'],
  'infoRequested': [
    'الخبير يطلب معلومات زايدة: ابعث تصويرة.',
    "L'expert demande plus d'informations : envoyez une photo."
  ],
  // report form
  'crop': ['الزرّيعة', 'Culture'],
  'symptom': ['نوع المشكلة', 'Type de problème'],
  'details': ['وصف الأعراض', 'Description des symptômes'],
  'photo': ['تصويرة (اختياري)', 'Photo (facultatif)'],
  'governorate': ['الولاية', 'Gouvernorat'],
  'locality': ['المعتمدية / المنطقة', 'Délégation / localité'],
  'observedOn': ['نهار شفتها', "Date d'observation"],
  'submit': ['ابعث', 'Envoyer'],
  'sent': ['تبعث البلاغ', 'Signalement envoyé'],
  'privacyNote': [
    'الفلاحين الآخرين يشوفو كان الولاية وعدد البلاغات. اسمك وبلاصتك ما يظهروش.',
    'Les autres agriculteurs ne voient que le gouvernorat et le nombre de signalements. Votre nom et position restent privés.'
  ],
  // expert
  'reviewTitle': ['مراجعة التنبيهات', 'Revue des alertes'],
  'notExpert': [
    'هذي الصفحة للخبراء المعتمدين برك.',
    'Page réservée aux experts agréés.'
  ],
  'markVerified': ['مؤكّد من خبير', 'Vérifié par expert'],
  'markUnconfirmed': ['غير مؤكّد', 'Non confirmé'],
  'markDismissed': ['مرفوض', 'Rejeté'],
  'startReview': ['ابدأ المراجعة', 'Commencer la revue'],
  'requestInfo': ['اطلب معلومات', 'Demander des infos'],
  'expertNote': ['ملاحظة الخبير', "Note de l'expert"],
  'stepsOnePerLine': [
    'الخطوات الوقائية (وحدة في كل سطر)',
    'Mesures préventives (une par ligne)'
  ],
  'saved': ['تسجّل', 'Enregistré'],
  'responses': ['أجوبة الفلاحين', 'Réponses des agriculteurs'],
  // notifications
  'notifications': ['الإشعارات', 'Notifications'],
  'newRiskNear': [
    'خطر محتمل جديد في ولايتك',
    'Nouveau risque potentiel dans votre gouvernorat'
  ],
  'setGov': [
    'اختار ولايتك باش توصلك التنبيهات',
    'Choisissez votre gouvernorat pour recevoir les alertes'
  ],
  // voice / sensors (kept for parity with the web dictionary)
  'talkTitle': ['احكي مع Aethera', 'Parler à Aethera'],
  'talkDesc': [
    'اضغط على الميكرو واسأل بالدارجة.',
    'Appuyez sur le micro et posez votre question.'
  ],
  'listening': ['نسمع فيك...', "J'écoute..."],
  'tapToTalk': ['اضغط وتكلّم', 'Appuyez pour parler'],
  'youSaid': ['قلت', 'Vous avez dit'],
  'answer': ['الجواب', 'Réponse'],
  'typeInstead': ['ولا اكتب سؤالك هنا', 'Ou tapez votre question ici'],
  'ask': ['اسأل', 'Demander'],
  'replay': ['عاود', 'Rejouer'],
  'pause': ['وقّف شوية', 'Pause'],
  'resume': ['كمّل', 'Reprendre'],
  'stop': ['وقّف', 'Arrêter'],
  'noSpeech': [
    'المتصفح هذا ما يدعمش التعرف على الصوت. استعمل الكتابة.',
    'Ce navigateur ne gère pas la reconnaissance vocale. Utilisez le texte.'
  ],
  'micDenied': [
    'ما عطيتش الإذن للميكرو. تنجم تكتب سؤالك.',
    'Accès au micro refusé. Vous pouvez taper votre question.'
  ],
  'noTts': [
    'القراءة بالصوت موش متوفرة هنا.',
    "La lecture audio n'est pas disponible ici."
  ],
  'thinking': ['نخمّم...', 'Je réfléchis...'],
  'aiError': ['صار مشكل. عاود جرّب.', 'Une erreur est survenue. Réessayez.'],
  'sensor': ['رطوبة التربة', 'Humidité du sol'],
  'sensorNone': ['ما فماش قراءة', 'Aucune mesure'],
  'sensorStale': ['قديمة', 'ancienne'],
  'addReading': ['زيد قراءة', 'Ajouter une mesure'],
  'online': ['يحتاج الإنترنت', 'Nécessite Internet'],
  // shared form actions
  'describeProblem': ['صِف مشكلتك...', 'Décrivez votre problème...'],
  'uploadPhoto': ['حمّل تصويرة', 'Importer une photo'],
  'voiceQuestion': ['سؤال بالصوت', 'Question vocale'],
  'voiceSend': ['ابعث', 'Envoyer'],
  'voiceStop': ['كمّلت، وقّف', 'Terminer'],
  'voiceRepeat': ['عاود احكي', 'Répéter'],
  'voiceListening': ['نسمع فيك…', 'Je vous écoute…'],
  'voiceReview': [
    'هذا اللي فهمناه. كان مش صحيح، اضغط «عاود احكي».',
    'Voici ce que nous avons compris. Si ce n\'est pas correct, appuyez sur « Répéter ».'
  ],
  'voiceErrUnavailable': [
    'التعرّف على الصوت مش متوفّر في هذا المتصفّح. جرّب Chrome ولا Edge، ولا اكتب سؤالك.',
    'La reconnaissance vocale n\'est pas disponible ici. Essayez Chrome ou Edge, ou écrivez votre question.'
  ],
  'voiceErrMic': [
    'الميكروفون ممنوع. فعّلو من إعدادات المتصفّح وعاود.',
    'Micro refusé. Autorisez-le dans les paramètres du navigateur, puis réessayez.'
  ],
  'voiceErrHeard': [
    'ما سمعناش مليح. عاود احكي.',
    'Je n\'ai rien compris. Parlez à nouveau.'
  ],
  'voiceErrNetwork': [
    'مشكل في الإنترنت. عاود بعد شوية، ولا اكتب سؤالك.',
    'Problème de réseau. Réessayez, ou écrivez votre question.'
  ],
  'voiceErrGeneric': [
    'صار مشكل. عاود ولا اكتب سؤالك.',
    'Un problème est survenu. Réessayez ou écrivez votre question.'
  ],
  'listen': ['اسمع', 'Écouter'],
  'listenStop': ['وقّف القراءة', 'Arrêter la lecture'],
  'photoNeeded': [
    'زيد تصويرة باش تنجّم تحلّل.',
    'Ajoutez une photo pour lancer l\'analyse.'
  ],
  'useFarmContext': [
    'استعمل معلومات ضيعتي',
    'Utiliser le contexte de ma ferme'
  ],
};

const Map<String, List<String>> _labels = {
  'tomato': ['طماطم', 'Tomate'],
  'olive': ['زيتون', 'Olivier'],
  'citrus': ['قوارص', 'Agrumes'],
  'wheat': ['قمح', 'Blé'],
  'potato': ['بطاطا', 'Pomme de terre'],
  'pepper': ['فلفل', 'Piment'],
  'date_palm': ['نخيل', 'Palmier dattier'],
  'grape': ['عنب', 'Vigne'],
  'leaf_spots': ['بقع على الورق', 'Taches sur feuilles'],
  'yellowing': ['اصفرار', 'Jaunissement'],
  'wilting': ['ذبول', 'Flétrissement'],
  'pests': ['حشرات', 'Ravageurs'],
  'fruit_rot': ['تعفّن الثمار', 'Pourriture des fruits'],
  'other': ['أخرى', 'Autre'],
  'detected': ['مكتشف', 'Détecté'],
  'under_review': ['قيد المراجعة', 'En cours de revue'],
  'verified': ['مؤكّد من خبير', 'Vérifié par expert'],
  'unconfirmed': ['غير مؤكّد', 'Non confirmé'],
  'dismissed': ['مرفوض', 'Rejeté'],
  'low': ['ضعيفة', 'Faible'],
  'medium': ['متوسطة', 'Moyenne'],
  'high': ['عالية', 'Élevée'],
  'inspect_leaves': ['افحص الورق السفلاني', 'Inspectez les feuilles basses'],
  'send_photo': ['ابعث تصويرة للخبير', "Envoyez une photo à l'expert"],
  'avoid_evening_irrigation': [
    'ما تسقيش في العشية',
    "Évitez l'irrigation le soir"
  ],
  'check_traps': ['ثبّت في الفخاخ', 'Vérifiez les pièges'],
  'balance_fertilizer': ['عدّل السماد', 'Équilibrez la fertilisation'],
};

const List<String> kCrops = [
  'tomato',
  'olive',
  'citrus',
  'wheat',
  'potato',
  'pepper',
  'date_palm',
  'grape'
];
const List<String> kSymptoms = [
  'leaf_spots',
  'yellowing',
  'wilting',
  'pests',
  'fruit_rot',
  'other'
];
const List<String> kGovernorates = [
  'Ariana',
  'Béja',
  'Ben Arous',
  'Bizerte',
  'Gabès',
  'Gafsa',
  'Jendouba',
  'Kairouan',
  'Kasserine',
  'Kébili',
  'Le Kef',
  'Mahdia',
  'La Manouba',
  'Médenine',
  'Monastir',
  'Nabeul',
  'Sfax',
  'Sidi Bouzid',
  'Siliana',
  'Sousse',
  'Tataouine',
  'Tozeur',
  'Tunis',
  'Zaghouan',
];

/// Language state (ar / fr, persisted) – equivalent of LangProvider + useLang().
class LangController extends ChangeNotifier {
  Lang _lang = Lang.fr;
  Lang get lang => _lang;
  bool get isAr => _lang == Lang.ar;
  TextDirection get dir => isAr ? TextDirection.rtl : TextDirection.ltr;
  Locale get locale => Locale(isAr ? 'ar' : 'fr');
  int get _i => isAr ? 0 : 1;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString('aethera-lang');
      if (s == 'ar') _lang = Lang.ar;
      if (s == 'fr') _lang = Lang.fr;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLang(Lang l) async {
    _lang = l;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('aethera-lang', l == Lang.ar ? 'ar' : 'fr');
    } catch (_) {}
  }

  String t(String key) => _d[key]?[_i] ?? key;
  String label(String v) => _labels[v]?[_i] ?? v;
  String navLabel(String label) {
    final k = 'nav.$label';
    return _d.containsKey(k) ? t(k) : label;
  }

  static const _frMonths = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.'
  ];
  static const _arMonths = [
    'جانفي',
    'فيفري',
    'مارس',
    'أفريل',
    'ماي',
    'جوان',
    'جويلية',
    'أوت',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];

  /// "10 oct." / "10 أكتوبر" (day + short month), like toLocaleDateString in the web app.
  String fmtDate(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    return '${d.day} ${(isAr ? _arMonths : _frMonths)[d.month - 1]}';
  }
}

/// Inherited access: `final l = L.of(context);` (rebuilds when the language changes).
class L extends InheritedNotifier<LangController> {
  const L({super.key, required LangController controller, required super.child})
      : super(notifier: controller);
  static LangController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<L>()!.notifier!;
  static LangController read(BuildContext context) =>
      (context.getInheritedWidgetOfExactType<L>()!).notifier!;
}

/// The "تونسي | FR" pill switch.
class LangSwitch extends StatelessWidget {
  const LangSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    Widget seg(Lang v, String text) {
      final on = l.lang == v;
      return Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => l.setLang(v),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: on ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10)),
            child: Text(text,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: on
                        ? AppColors.primaryForeground
                        : AppColors.mutedForeground)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [seg(Lang.ar, 'تونسي'), seg(Lang.fr, 'FR')]),
    );
  }
}
