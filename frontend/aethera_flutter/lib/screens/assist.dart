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

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _q.dispose();
    super.dispose();
  }

  void _ask() {
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
    context.demo.set(
        caseStatus: CaseStatus.submitted,
        expertVerdict: '',
        expertPlan: [],
        published: false);
    showToast(context, 'Case #2048 sent to a verified expert',
        kind: ToastKind.success);
    go(context, '/consult');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final md = context.isMd;
    final photo = _photo;

    final composer = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _q,
          minLines: 3,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
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
                  variant: BtnVariant.outline,
                  icon: LucideIcons.mic,
                  label: l.t('voiceQuestion'),
                  onPressed: () => showToast(context,
                      'Voice input — Arabic / Tunisian Derja supported (prototype)')),
              AppButton(
                variant: _ctx ? BtnVariant.soft : BtnVariant.outline,
                icon: LucideIcons.mapPin,
                trailingIcon: _ctx ? LucideIcons.check : null,
                label: l.t('useFarmContext'),
                onPressed: () => setState(() => _ctx = !_ctx),
              ),
              AppButton(
                  variant: BtnVariant.accent,
                  icon: LucideIcons.zap,
                  label: l.t('ask'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  onPressed:
                      _q.text.isEmpty || _phase == 'thinking' ? null : _ask),
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

    final cause = [
      ('Water stress', 'Soil moisture 22%, below target, and high heat.'),
      ('Nutrient deficiency', 'Nitrogen or magnesium during fruit load.'),
      (
        'Disease',
        photo != null
            ? 'Photo shows lesions — possible early blight.'
            : 'Fungal leaf spot common in humid nights.'
      ),
    ];
    final answer = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              TrustLabel(Trust.ai),
              Confidence(level: Conf.medium, value: 68)
            ]),
        const SizedBox(height: 16),
        Text('Possible causes', style: display(size: 20)),
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
        Text('What to do now', style: display(size: 20)),
        const SizedBox(height: 8),
        for (final (i, t) in const [
          'Check soil moisture at 15–20 cm near the drippers',
          'Inspect lower leaves: uniform yellowing vs. spots with rings',
          'Compare affected and healthy plants in the same row'
        ].indexed)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NumDot(i + 1),
                const SizedBox(width: 12),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(t, style: body())))
              ])),
        const SizedBox(height: 12),
        Tinted(
          color: AppColors.secondary,
          child: Text.rich(TextSpan(style: body(size: 14), children: [
            TextSpan(
                text: 'Important:', style: body(size: 14, w: FontWeight.w700)),
            const TextSpan(
                text:
                    ' This recommendation is based on your crop profile and verified agricultural knowledge.')
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
