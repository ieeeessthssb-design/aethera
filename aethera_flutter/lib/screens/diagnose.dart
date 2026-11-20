import 'dart:async';

import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';
import '../widgets/photo_picker.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import '../widgets/toast.dart';
import '../widgets/voice_input.dart';

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});
  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen>
    with SingleTickerProviderStateMixin {
  PickedPhoto? _img;
  String _phase = 'form';
  String _crop = 'Tomato';
  String _farm = 'Sousse — Plot A (2.5 ha)';
  final _symptoms = TextEditingController(
      text:
          'Yellowing lower leaves with brown spots. Started 4 days ago, spreading upward.');
  late final AnimationController _scan = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  Timer? _timer;
  late final VoiceController _voice = VoiceController(_symptoms);

  @override
  void initState() {
    super.initState();
    _symptoms.addListener(_onText);
    _voice.addListener(_onText);
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  bool? _lastAr;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ar = context.l.isAr;
    if (_lastAr != null && _lastAr != ar) {
      // language switched: erase the question written/spoken in the old language
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _voice.languageChanged();
      });
    }
    _lastAr = ar;
  }

  @override
  void dispose() {
    _symptoms.removeListener(_onText);
    _voice.removeListener(_onText);
    _voice.dispose();
    _timer?.cancel();
    _scan.dispose();
    _symptoms.dispose();
    super.dispose();
  }

  void _run() {
    _voice.stopSpeaking();
    _voice.reset();
    setState(() => _phase = 'scan');
    _scan.repeat(reverse: true);
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _scan.stop();
      setState(() => _phase = 'result');
    });
  }

  Future<void> _choose(ImageSource src) async {
    final p = await pickPhoto(context, source: src);
    if (p != null && mounted) setState(() => _img = p);
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.l.isAr; // Tunisian Arabic or French, never English
    String t(String fr, String tn) => ar ? tn : fr;
    // Prototype result (stands in for the model / expert answer, which will
    // arrive already in the farmer's language).
    final hTitle = t('DIAGNOSTIC PRÉLIMINAIRE', 'تشخيص أوّلي');
    final issue = t('Problème possible : alternariose (brûlure précoce)',
        'مشكل ممكن: التبقّع المبكّر (Alternaria)');
    final alt = t(
        'Taches foliaires · autres possibilités : septoriose, carence en magnésium',
        'بقع على الأوراق · احتمالات أخرى: سيبتوريا، نقص المغنيزيوم');
    final hSym = t('Symptômes observés', 'الأعراض اللي تلاحظت');
    final syms = [
      t('Taches brunes avec anneaux concentriques',
          'بقع بنية فيها دوائر'),
      t('Jaunissement autour des taches', 'اصفرار حذا البقع'),
      t('Cohérent avec les symptômes décrits (feuilles du bas d\'abord)',
          'يشبه الأعراض اللي وصفتها (الأوراق اللي من تحت لول)'),
    ];
    final hAct = t('Actions immédiates recommandées', 'شنوّة تعمل توّا');
    final acts = [
      t('Inspectez les plantes voisines', 'شوف النباتات اللي حذاه'),
      t('Retirez les feuilles très atteintes', 'نحّي الأوراق المصابة برشا'),
      t('Évitez tout traitement inutile avant confirmation',
          'ما تعالجش بلا فايدة قبل ما يتأكّد التشخيص'),
      t('Surveillez l\'évolution pendant 48 h', 'تابع الوضع على 48 ساعة'),
    ];
    final hWhy = t('Pourquoi ?', 'علاش؟');
    final why = t(
        'Les taches en anneaux sur les vieilles feuilles correspondent à l\'alternariose dans les références vérifiées. Les nuits chaudes et humides à Sousse cette semaine et le stress de la fructification la rendent plausible — mais le manque d\'eau et les carences peuvent ressembler à ça.',
        'البقع اللي فيها دوائر على الأوراق القديمة تشبه التبقّع المبكّر في المراجع الموثوقة. الليالي الساخنة والرطبة في سوسة هالجمعة وإجهاد التثمير يخلّو هذا ممكن — أما العطش ونقص الغذاء ينجّمو يبانو كيفو.');
    final warn = t(
        'L\'analyse d\'image donne une orientation préliminaire et ne remplace pas un diagnostic professionnel quand la confiance est faible ou qu\'il y a un risque de perte importante.',
        'تحليل التصويرة يعطي فكرة أوّلية برك، وما يعوّضش تشخيص الخبير كي تكون الثقة ضعيفة ولا فما خطر على المحصول.');
    final resultSpeech = [
      '$hTitle.',
      '$issue.',
      '$alt.',
      '$hSym.',
      for (final x in syms) '$x.',
      '$hAct.',
      for (final x in acts) '$x.',
'$hTitle.',   
   why,
      warn,
    ].join(' ');

    final upload = AspectRatio(
      aspectRatio: 4 / 3,
      child: DashedBox(
        radius: 12,
        strokeWidth: 2,
        dash: 6,
        gap: 4,
        color: AppColors.input,
        background: AppColors.muted,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(fit: StackFit.expand, children: [
            if (_img != null)
              Image(
                  image: _img!.provider,
                  fit: BoxFit.cover,
                  semanticLabel: 'Tomato leaf')
            else
              Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.upload,
                    size: 40, color: AppColors.mutedForeground),
                const SizedBox(height: 4),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Add a clear photo of the affected leaf',
                        textAlign: TextAlign.center,
                        style: body(color: AppColors.mutedForeground)))
              ])),
            if (_phase == 'scan') ...[
              Container(color: AppColors.forest.withValues(alpha: .3)),
              LayoutBuilder(
                  builder: (context, c) => AnimatedBuilder(
                        animation: _scan,
                        builder: (context, _) => Positioned(
                          left: 0,
                          right: 0,
                          top: Curves.easeInOut.transform(_scan.value) *
                              (c.maxHeight * .95),
                          child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  boxShadow: [
                                    BoxShadow(
                                        color: AppColors.accent
                                            .withValues(alpha: .9),
                                        blurRadius: 20)
                                  ])),
                        ),
                      )),
              PositionedDirectional(
                bottom: 12,
                start: 12,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('Analyzing leaf patterns…',
                        style: body(size: 14, w: FontWeight.w600))),
              ),
            ],
          ]),
        ),
      ),
    );

    final form = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        upload,
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: AppButton(
                  variant: BtnVariant.outline,
                  icon: LucideIcons.upload,
                  label: 'Upload image',
                  onPressed: () => _choose(ImageSource.gallery))),
          const SizedBox(width: 8),
          Expanded(
              child: AppButton(
                  variant: BtnVariant.outline,
                  icon: LucideIcons.camera,
                  label: 'Take photo',
                  onPressed: () => _choose(ImageSource.camera))),
        ]),
        const SizedBox(height: 16),
        ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 12, children: [
          FieldLabel('Crop',
              child: AppSelect(
                  value: _crop,
                  options: const ['Tomato', 'Pepper', 'Potato'],
                  onChanged: (v) => setState(() => _crop = v))),
          FieldLabel('Farm',
              child: AppSelect(
                  value: _farm,
                  options: const ['Sousse — Plot A (2.5 ha)'],
                  onChanged: (v) => setState(() => _farm = v))),
        ]),
        const SizedBox(height: 12),
        FieldLabel('Describe symptoms',
            // spoken text is read-only: only "Répéter" changes it
            child: AppTextField(
                controller: _symptoms,
                maxLines: 3,
                readOnly: _voice.locked,
                onChanged: (_) => _voice.markTyped())),
        VoiceStatus(controller: _voice),
        const SizedBox(height: 16),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...voiceButtons(context, _voice,
                  onSend: _run,
                  busy: _phase == 'scan',
                  canSend: _img != null,
                  sendLabel: _phase == 'scan' ? 'Analyzing…' : 'Analyze crop'),
            ]),
        if (_img == null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.l.t('photoNeeded'),
                  style: body(size: 13, color: AppColors.mutedForeground))),
      ]),
    );

    Widget bullets(List<String> items) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final t in items)
            Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(left: 4, right: 10),
                          child: Text('•', style: body(size: 14))),
                      Expanded(child: Text(t, style: body(size: 14)))
                    ])),
        ]);

    final result = _phase != 'result'
        ? AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(LucideIcons.info,
                      size: 40, color: AppColors.mutedForeground),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                          'Results appear here with a confidence level and clear next steps.',
                          textAlign: TextAlign.center,
                          style: body(color: AppColors.mutedForeground))),
                ]),
              ),
            ),
          )
        : AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const TrustLabel(Trust.ai),
                    const Confidence(level: Conf.medium, value: 72),
                    ListenButton(
                        controller: _voice,
                        text: resultSpeech,
                        lang: ar ? 'ar' : 'fr'),
                  ]),
              const SizedBox(height: 16),
              Text(hTitle,
                  style: body(
                      size: 14,
                      w: FontWeight.w600,
                      color: AppColors.mutedForeground,
                      letterSpacing: 0.7)),
              Text(issue, style: display(size: 30)),
              Text(alt,
                  style: body(size: 14, color: AppColors.mutedForeground)),
              const SizedBox(height: 16),
              Text(hSym, style: display(size: 16)),
              const SizedBox(height: 4),
              bullets(syms),
              const SizedBox(height: 16),
              Text(hAct, style: display(size: 16)),
              const SizedBox(height: 4),
              for (final x in acts)
                Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Tinted(
                        radius: 8,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(x, style: body(size: 14)))),
              const SizedBox(height: 10),
              Text(hWhy, style: display(size: 16)),
              const SizedBox(height: 4),
              Text(why,
                  style: body(size: 14, color: AppColors.mutedForeground)),
              const SizedBox(height: 16),
              Tinted(
                color: AppColors.warningSoft,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.alertTriangle,
                          size: 20, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(warn,
                              style: body(size: 14))),
                    ]),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Request Expert Review',
                expand: true,
                fontSize: 16,
                onPressed: () {
                  final photo = _img;
                  context.demo.set(
                      caseStatus: CaseStatus.submitted,
                      published: false,
                      expertVerdict: '',
                      expertPlan: [],
                      expertDecision: '',
                      submission: FarmerSubmission(
                        origin: 'diagnose',
                        note: _symptoms.text.trim(),
                        spoken: _voice.spoken,
                        lang: ar ? 'ar' : 'fr',
                        crop: _crop == 'Tomato'
                            ? 'Tomate'
                            : _crop == 'Pepper'
                                ? 'Poivron'
                                : 'Pomme de terre',
                        aiPrediction:
                            'Problème possible : alternariose (brûlure précoce)',
                        aiConfidence: .72,
                        aiAnalysis:
                            'Taches foliaires · autres possibilités : septoriose, carence en magnésium.\nLes taches en anneaux sur les vieilles feuilles correspondent à l\'alternariose dans les références vérifiées. Les nuits chaudes et humides à Sousse cette semaine et le stress de la fructification la rendent plausible, mais le manque d\'eau et les carences peuvent ressembler à ça.',
                        aiRecommendation: [
                          'Inspecter les plantes voisines',
                          'Retirer les feuilles très atteintes',
                          'Éviter tout traitement inutile avant confirmation',
                          'Surveiller l\'évolution pendant 48 h',
                        ].join('\n'),
                        farmContext: _farm,
                        actions: [
                          'Diagnostic : symptômes décrits',
                          if (photo != null) 'Photo envoyée : ${photo.name}',
                          'Analyse IA obtenue : confiance moyenne (72 %)',
                          'Revue d\'un expert demandée',
                        ],
                        createdAt: DateTime.now(),
                        photo: photo?.provider,
                        photoName: photo?.name,
                      ));
                  showToast(context, 'Expert review requested',
                      kind: ToastKind.success);
                  go(context, '/consult');
                },
              ),
            ]),
          );

    return AppShell(
      role: Role.farmer,
      path: '/diagnose',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(
            eyebrow: 'Crop diagnosis',
            title: 'What is happening to your crop?',
            actions: [ProtoTag()]),
        ResponsiveGrid(
            cols: colsFor(context, lg: 2), gap: 20, children: [form, result]),
      ]),
    );
  }
}
