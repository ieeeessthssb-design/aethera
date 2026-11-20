import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/translated_text.dart';

const _stages = [
  'Submitted',
  'Expert reviewing',
  'Expert response',
  'Resolved'
];

int _idx(CaseStatus s) => switch (s) {
      CaseStatus.none => -1,
      CaseStatus.submitted => 0,
      CaseStatus.reviewing => 1,
      CaseStatus.responded => 2,
      CaseStatus.resolved => 3
    };

class ConsultScreen extends StatelessWidget {
  const ConsultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = context.demo;
    return AppShell(
      role: Role.farmer,
      path: '/consult',
      child: ListenableBuilder(
        listenable: d,
        builder: (context, _) {
          final cur = _idx(d.caseStatus);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                    eyebrow: 'Ask → AI → Expert → Final decision',
                    title: 'Expert consultation',
                    desc:
                        "When AI confidence isn't enough, a verified expert reviews your case.",
                    actions: [ProtoTag()]),
                if (cur < 0) _empty(context) else _case(context, d, cur),
              ]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    const experts = [
      ('Dr. Leila Trabelsi', 'Plant pathology · INRAT', '4.9', '~3 h'),
      ('Mohamed Gharbi', 'Irrigation engineer · CRDA Sousse', '4.8', '~5 h'),
      ('Sonia Ayari', 'Soil & fertilization', '4.7', '~6 h')
    ];
    return ResponsiveGrid(cols: colsFor(context, md: 3), gap: 20, children: [
      for (final (n, r, s, t) in experts)
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.secondary, shape: BoxShape.circle),
                  child: Text(n.split(' ').last[0],
                      style: body(w: FontWeight.w700))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(n, style: body(w: FontWeight.w700)),
                    Text(r,
                        style: body(size: 14, color: AppColors.mutedForeground))
                  ])),
            ]),
            const SizedBox(height: 12),
            Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(LucideIcons.star,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(s, style: body(size: 14))
                  ]),
                  Text('Avg. reply $t', style: body(size: 14)),
                  const Icon(LucideIcons.shieldCheck,
                      size: 16, color: AppColors.primary),
                ]),
          ]),
        ),
      GridCell(
        span: 3,
        child: AppCard(
          child: Column(children: [
            Text(
                'No open case. Start from Quick Assist or Diagnosis — your AI result will be attached automatically.',
                textAlign: TextAlign.center,
                style: body()),
            const SizedBox(height: 16),
            Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton.link(context, '/assist', 'Quick Assist'),
                  AppButton.link(context, '/diagnose', 'Diagnose',
                      variant: BtnVariant.outline)
                ]),
          ]),
        ),
      ),
    ]);
  }

  Widget _case(BuildContext context, DemoStore d, int cur) {
    final tracker = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (i, s) in _stages.indexed)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: i < 3 ? 8 : 0),
                child: Column(children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: i <= cur ? AppColors.primary : AppColors.muted,
                        shape: BoxShape.circle),
                    child: i < cur || cur == 3
                        ? Icon(LucideIcons.check,
                            size: 20, color: AppColors.primaryForeground)
                        : Text('${i + 1}',
                            style: body(
                                w: FontWeight.w700,
                                color: i <= cur
                                    ? AppColors.primaryForeground
                                    : AppColors.mutedForeground)),
                  ),
                  const SizedBox(height: 8),
                  Text(s,
                      textAlign: TextAlign.center,
                      style: body(
                          size: context.isSm ? 14 : 12, w: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
        if (cur < 2) ...[
          const SizedBox(height: 20),
          Tinted(
              color: AppColors.secondary,
              child: Row(children: [
                const Icon(LucideIcons.stethoscope,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Your case has been assigned to a verified agricultural expert — Dr. Leila Trabelsi.',
                        style: body(w: FontWeight.w500)))
              ])),
        ],
      ]),
    );

    final details = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Case #2048 — Yellowing tomato leaves', style: display(size: 20)),
        const SizedBox(height: 12),
        ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 8, children: [
          for (final (k, v) in [
            ('Farmer', 'Amine Ben Salem'),
            ('Location', 'Sousse, Tunisia'),
            ('Crop', 'Tomato · day 80'),
            ('Farm size', '2.5 ha · drip · water limited'),
            // what the farmer really sent (written or dictated)
            (
              'Symptoms',
              (d.submission?.note.isNotEmpty ?? false)
                  ? d.submission!.note
                  : 'Yellow lower leaves, brown ringed spots'
            ),
            (
              'Previous actions',
              (d.submission?.actions.isNotEmpty ?? false)
                  ? d.submission!.actions.join(' · ')
                  : 'Increased irrigation 2 days ago'
            )
          ])
            Tinted(
                radius: 8,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text.rich(kv(k, v))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: d.submission?.photo != null
                  ? Image(
                      image: d.submission!.photo!,
                      width: 128,
                      height: 96,
                      fit: BoxFit.cover,
                      semanticLabel: 'Case photo',
                      errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/tomato-leaf.jpg',
                          width: 128,
                          height: 96,
                          fit: BoxFit.cover))
                  : Image.asset('assets/images/tomato-leaf.jpg',
                      width: 128,
                      height: 96,
                      fit: BoxFit.cover,
                      semanticLabel: 'Case photo')),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI preliminary assessment',
                  style: body(size: 14, color: AppColors.mutedForeground)),
              Text('Early blight (possible)', style: body(w: FontWeight.w700)),
              const SizedBox(height: 4),
              const Confidence(level: Conf.medium, value: 72),
            ]),
          ),
        ]),
      ]),
    );

    final side = cur == 3
        ? AppCard(
            color: AppColors.successSoft,
            borderColor: AppColors.success.withValues(alpha: .4),
            borderWidth: 2,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const TrustLabel(Trust.expert),
              const SizedBox(height: 12),
              Text(
                  d.expertDecision == 'rejected'
                      ? 'Expert correction'
                      : 'Final action plan',
                  style: display(size: 18)),
              TranslatedText(d.expertVerdict, toArabic: context.l.isAr),
              const SizedBox(height: 12),
              for (final (i, p) in d.expertPlan.indexed)
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ',
                              style: body(size: 14, w: FontWeight.w700)),
                          Expanded(
                              child: TranslatedText(p,
                                  toArabic: context.l.isAr))
                        ])),
              const SizedBox(height: 4),
              Text(
                  'Reviewed by Dr. Leila Trabelsi · ${d.published ? 'Added to the Knowledge Hub' : 'Validated answer'}',
                  style: body(size: 12, color: AppColors.mutedForeground)),
            ]),
          )
        : AppCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('What happens next', style: body(w: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      "The expert sees your photos, farm context and the AI's reasoning. You'll get a notification — even offline, it syncs when you reconnect.",
                      style: body(size: 14, color: AppColors.mutedForeground)),
                  const SizedBox(height: 16),
                  AppButton.link(
                      context, '/expert/review', 'Demo: switch to expert view',
                      variant: BtnVariant.soft, expand: true),
                  if (cur == 0) ...[
                    const SizedBox(height: 8),
                    AppButton(
                        variant: BtnVariant.ghost,
                        expand: true,
                        label: 'Simulate expert opening case',
                        onPressed: () =>
                            d.set(caseStatus: CaseStatus.reviewing))
                  ],
                ]),
          );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      tracker,
      const SizedBox(height: 20),
      ResponsiveGrid(
          cols: colsFor(context, lg: 3),
          gap: 20,
          children: [GridCell(span: 2, child: details), side]),
      const SizedBox(height: 24),
      Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextLink('Reset demo scenario',
              onTap: d.reset, color: AppColors.mutedForeground)),
    ]);
  }
}
