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

  @override
  void dispose() {
    _timer?.cancel();
    _scan.dispose();
    _symptoms.dispose();
    super.dispose();
  }

  void _run() {
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
            child: AppTextField(controller: _symptoms, maxLines: 3)),
        const SizedBox(height: 16),
        AppButton(
            label: _phase == 'scan' ? 'Analyzing…' : 'Analyze crop',
            expand: true,
            onPressed: _img == null || _phase == 'scan' ? null : _run),
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
                  children: const [
                    TrustLabel(Trust.ai),
                    Confidence(level: Conf.medium, value: 72)
                  ]),
              const SizedBox(height: 16),
              Text('PRELIMINARY DIAGNOSIS',
                  style: body(
                      size: 14,
                      w: FontWeight.w600,
                      color: AppColors.mutedForeground,
                      letterSpacing: 0.7)),
              Text('Possible issue: Early blight', style: display(size: 30)),
              Text.rich(TextSpan(
                  style: body(size: 14, color: AppColors.mutedForeground),
                  children: [
                    TextSpan(
                        text: 'Alternaria',
                        style: body(
                            size: 14,
                            color: AppColors.mutedForeground,
                            style: FontStyle.italic)),
                    const TextSpan(
                        text:
                            ' leaf spot · alternatives: Septoria leaf spot, magnesium deficiency')
                  ])),
              const SizedBox(height: 16),
              Text('Observed symptoms', style: display(size: 16)),
              const SizedBox(height: 4),
              bullets(const [
                'Brown lesions with concentric rings',
                'Yellowing leaves around lesions',
                'Pattern consistent with reported symptoms (lower canopy first)'
              ]),
              const SizedBox(height: 16),
              Text('Recommended immediate actions', style: display(size: 16)),
              const SizedBox(height: 4),
              for (final t in const [
                'Inspect nearby plants',
                'Remove severely affected leaves',
                'Avoid unnecessary treatment until diagnosis is confirmed',
                'Monitor progression over 48 h'
              ])
                Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Tinted(
                        radius: 8,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(t, style: body(size: 14)))),
              const SizedBox(height: 10),
              Text('Why?', style: display(size: 16)),
              const SizedBox(height: 4),
              Text(
                  'Ring-shaped lesions on older leaves match early blight in verified references. Warm, humid nights in Sousse this week and fruiting-stage stress make it plausible — but water stress and nutrient issues can look similar.',
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
                          child: Text(
                              'Image analysis provides preliminary guidance and should not replace professional diagnosis when confidence is low or the situation could cause significant crop loss.',
                              style: body(size: 14))),
                    ]),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Request Expert Review',
                expand: true,
                fontSize: 16,
                onPressed: () {
                  context.demo
                      .set(caseStatus: CaseStatus.submitted, published: false);
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
