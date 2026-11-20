import 'dart:async';

import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/photo_picker.dart';
import '../widgets/toast.dart';
import '../widgets/voice_input.dart';

const _pipe = [
  'Understanding question',
  'Retrieving verified knowledge',
  'Applying farm context',
  'Estimating confidence'
];

class AssistScreen extends StatefulWidget {
  const AssistScreen({super.key});
  @override
  State<AssistScreen> createState() => _AssistScreenState();
}

class _AssistScreenState extends State<AssistScreen> {
  final _q = TextEditingController(
      text: 'My tomato leaves are turning yellow. What should I check?');
  PickedPhoto? _photo;
  bool _ctx = true;
  String _phase = 'idle';
  int _step = 0;
  final List<Timer> _timers = [];
  late final VoiceController _voice = VoiceController(_q);

  @override
  void initState() {
    super.initState();
    _q.addListener(_onText);
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
    for (final t in _timers) {
      t.cancel();
    }
    _q.removeListener(_onText);
    _voice.removeListener(_onText);
    _voice.dispose();
    _q.dispose();
    super.dispose();
  }

  void _ask() {
    _voice.stopSpeaking();
    _voice.reset();
    setState(() {
      _phase = 'thinking';
      _step = 0;
    });
    for (var i = 0; i < _pipe.length; i++) {
      _timers.add(Timer(Duration(milliseconds: 600 * (i + 1)),
          () => mounted ? setState(() => _step = i + 1) : null));
    }
    _timers.add(Timer(Duration(milliseconds: 600 * _pipe.length + 300),
        () => mounted ? setState(() => _phase = 'done') : null));
  }

  void _send() {
    // The farmer's own words (_q) are sent untouched, in the language he used.
    // Everything else is written in French for the expert page.
    final photo = _photo;
    final trail = <String>[
      'Aide rapide : question posée',
      if (photo != null) 'Photo jointe : ${photo.name}',
      if (_ctx) 'Contexte de la ferme inclus',
      'Réponse IA obtenue : confiance moyenne (68 %)',
      'Envoyé à l\'expert',
    ];
    context.demo.set(
        caseStatus: CaseStatus.submitted,
        expertVerdict: '',
        expertPlan: [],
        published: false,
        expertDecision: '',
        submission: FarmerSubmission(
          origin: 'assist',
          note: _q.text.trim(),
          spoken: _voice.spoken,
          lang: context.l.isAr ? 'ar' : 'fr',
          crop: 'Tomate',
          aiPrediction: 'Alternariose (possible)',
          aiConfidence: .68,
          aiAnalysis: [
            'Stress hydrique : humidité du sol à 22 %, sous l\'objectif, et forte chaleur.',
            'Carence en nutriments : azote ou magnésium pendant la charge en fruits.',
            photo != null
                ? 'Maladie : la photo montre des lésions — alternariose possible.'
                : 'Maladie : taches fongiques fréquentes quand les nuits sont humides.',
          ].join('\n'),
          aiRecommendation: [
            'Vérifier l\'humidité du sol à 15–20 cm près des goutteurs',
            'Inspecter les feuilles du bas : jaunissement uniforme ou taches avec anneaux',
            'Comparer les plantes atteintes et saines sur le même rang',
          ].join('\n'),
          farmContext: _ctx
              ? 'Tomate · Sousse · 2,5 ha · Goutte-à-goutte · Eau limitée · Jour 80 (fructification)'
              : '',
          actions: trail,
          createdAt: DateTime.now(),
          photo: photo?.provider,
          photoName: photo?.name,
        ));
    showToast(context, 'Case #2048 sent to a verified expert',
        kind: ToastKind.success);
    go(context, '/consult');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final md = context.isMd;
    final photo = _photo;
    final ar = l.isAr; // Tunisian Arabic or French, never English
    String t(String fr, String tn) => ar ? tn : fr;

    final composer = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _q,
          minLines: 3,
          maxLines: 3,
          readOnly: _voice.locked, // spoken text: only "Répéter" changes it
          onChanged: (_) {
            _voice.markTyped();
            setState(() {});
          },
          style: body(size: 18),
          textDirection: l.dir,
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: l.t('describeProblem'),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.ring, width: 2)),
          ),
        ),
        VoiceStatus(controller: _voice),
        if (photo != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Tinted(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image(
                        image: photo.provider,
                        width: 80,
                        height: 64,
                        fit: BoxFit.cover,
                        semanticLabel: 'Uploaded tomato leaf')),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('${photo.name} · ${photo.sizeLabel}',
                        overflow: TextOverflow.ellipsis,
                        style: body(size: 14))),
                GestureDetector(
                    onTap: () => setState(() => _photo = null),
                    child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(LucideIcons.x,
                            size: 16, color: AppColors.foreground))),
              ]),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton(
                variant: photo != null ? BtnVariant.soft : BtnVariant.outline,
                icon: LucideIcons.camera,
                label: l.t('uploadPhoto'),
                onPressed: () async {
                  final p = await pickPhoto(context);
                  if (p != null && mounted) setState(() => _photo = p);
                },
              ),
              AppButton(
                variant: _ctx ? BtnVariant.soft : BtnVariant.outline,
                icon: LucideIcons.mapPin,
                trailingIcon: _ctx ? LucideIcons.check : null,
                label: l.t('useFarmContext'),
                onPressed: () => setState(() => _ctx = !_ctx),
              ),
              ...voiceButtons(context, _voice,
                  onSend: _ask,
                  busy: _phase == 'thinking',
                  sendLabel: l.t('ask')),
            ]),
        if (_ctx)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                  'Context: Tomato · Sousse · 2.5 ha · Drip · Water limited · Day 80 (fruiting)',
                  style: body(size: 14, color: AppColors.mutedForeground))),
      ]),
    );

    final thinking = AppCard(
      child: Column(children: [
        for (final (i, p) in _pipe.indexed)
          Opacity(
            opacity: i >= _step ? .4 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: i < _step
                      ? const Icon(LucideIcons.check,
                          size: 20, color: AppColors.primary)
                      : i == _step
                          ? const Padding(
                              padding: EdgeInsets.all(2),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary))
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(p, style: body())),
              ]),
            ),
          ),
      ]),
    );

    // Prototype answer (stands in for the model / expert answer, which will
    // arrive already in the farmer's language: Tunisian Arabic or French).
    final cause = [
      (
        t('Stress hydrique', 'عطش النبتة'),
        t('Humidité du sol à 22 %, sous l\'objectif, et forte chaleur.',
            'رطوبة التربة 22%، أقل من المطلوب، والحرارة عالية.')
      ),
      (
        t('Carence en nutriments', 'نقص في الغذاء'),
        t('Azote ou magnésium pendant la charge en fruits.',
            'نقص في الآزوت ولا المغنيزيوم وقت التثمير.')
      ),
      (
        t('Maladie', 'مرض'),
        photo != null
            ? t('La photo montre des lésions — alternariose possible.',
                'التصويرة تبيّن بقع — ممكن التبقّع المبكّر.')
            : t('Taches fongiques fréquentes quand les nuits sont humides.',
                'تبقّع فطري يجي برشا كي تكون الليالي رطبة.')
      ),
    ];
    final steps = [
      t('Vérifiez l\'humidité du sol à 15–20 cm près des goutteurs',
          'شوف رطوبة التربة على عمق 15–20 سم قرب القطّاطات'),
      t('Inspectez les feuilles du bas : jaunissement uniforme ou taches avec anneaux',
          'شوف الأوراق اللي من تحت: اصفرار عادي ولا بقع فيها دوائر'),
      t('Comparez les plantes atteintes et saines sur le même rang',
          'قارن بين النباتات المصابة والصحيحة في نفس الصف'),
    ];
    final hCauses = t('Causes possibles', 'الأسباب الممكنة');
    final hDo = t('À faire maintenant', 'شنوّة تعمل توّا');
    final hImp = t('Important :', 'مهم:');
    final tImp = t(
        ' Cette recommandation se base sur le profil de votre culture et des connaissances agricoles vérifiées.',
        ' هذي النصيحة مبنية على ملف زرعك ومعلومات فلاحية موثوقة.');
    // "اسمع" reads exactly what is displayed, in reading order.
    final speech = [
      '$hCauses.',
      for (final c in cause) '${c.$1}. ${c.$2}',
      '$hDo.',
      for (final x in steps) '$x.',
      '$hImp$tImp',
    ].join(' ');
    final answer = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const TrustLabel(Trust.ai),
              const Confidence(level: Conf.medium, value: 68),
              ListenButton(
                  controller: _voice, text: speech, lang: ar ? 'ar' : 'fr'),
            ]),
        const SizedBox(height: 16),
        Text(hCauses, style: display(size: 20)),
        const SizedBox(height: 8),
        ResponsiveGrid(cols: colsFor(context, sm: 3), gap: 8, children: [
          for (final c in cause)
            Tinted(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.$1, style: body(w: FontWeight.w700)),
                  Text(c.$2,
                      style: body(size: 14, color: AppColors.mutedForeground))
                ])),
        ]),
        const SizedBox(height: 20),
        Text(hDo, style: display(size: 20)),
        const SizedBox(height: 8),
        for (final (i, x) in steps.indexed)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NumDot(i + 1),
                const SizedBox(width: 12),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(x, style: body())))
              ])),
        const SizedBox(height: 12),
        Tinted(
          color: AppColors.secondary,
          child: Text.rich(TextSpan(style: body(size: 14), children: [
            TextSpan(text: hImp, style: body(size: 14, w: FontWeight.w700)),
            TextSpan(text: tImp)
          ])),
        ),
      ]),
    );
    final side =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        color: AppColors.warningSoft,
        borderColor: AppColors.accent.withValues(alpha: .6),
        borderWidth: 2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(LucideIcons.stethoscope, size: 32, color: AppColors.earth),
          const SizedBox(height: 8),
          Text('Need expert confirmation?', style: display(size: 18)),
          Text(
              'Confidence is medium and the crop is in fruiting stage. We recommend expert review before treating.',
              style: body(size: 14)),
          const SizedBox(height: 16),
          AppButton(label: 'Send to Expert', expand: true, onPressed: _send),
          const SizedBox(height: 8),
          Center(
              child: TextLink('Or run a full photo diagnosis →',
                  path: '/diagnose')),
        ]),
      ),
      const SizedBox(height: 20),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(LucideIcons.bookOpenCheck,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Sources used', style: display(size: 16))
          ]),
          const SizedBox(height: 8),
          for (final (t, k) in const [
            ('Tomato nutrient disorders — field guide', Trust.expert),
            (
              'Drip irrigation under water scarcity, Sahel region',
              Trust.expert
            ),
            ('Farmer note, Msaken 2025', Trust.community)
          ])
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [Text(t, style: body(size: 14)), TrustLabel(k)])),
        ]),
      ),
    ]);

    return AppShell(
      role: Role.farmer,
      path: '/assist',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Journey(
                          steps: const ['Ask', 'Diagnose', 'Act'], active: 0)),
                  const SizedBox(width: 8),
                  const ProtoTag()
                ])),
        Text('What do you need?',
            style: display(size: md ? 36 : 30, height: 1.2)),
        const SizedBox(height: 20),
        composer,
        if (_phase == 'thinking') ...[const SizedBox(height: 20), thinking],
        if (_phase == 'done') ...[
          const SizedBox(height: 20),
          ResponsiveGrid(
              cols: colsFor(context, lg: 3),
              gap: 20,
              children: [GridCell(span: 2, child: answer), side]),
        ],
      ]),
    );
  }
}
