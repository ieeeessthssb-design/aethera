import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<({String t, bool done})> _todo = [
    (t: 'Check irrigation — drip line B', done: false),
    (t: 'Inspect tomato leaves (lower canopy)', done: false),
    (t: 'Fertilization due in 2 days (potassium)', done: false),
    (t: "Record yesterday's water use", done: true),
  ];

  static const _actions = [
    (
      '/guide',
      '🌱',
      'Guide Me',
      'Help me manage my crops step by step.',
      AppColors.secondary
    ),
    (
      '/assist',
      '⚡',
      'Quick Assist',
      'I already know farming. Give me the answer quickly.',
      AppColors.warningSoft
    ),
    (
      '/diagnose',
      '📷',
      'Diagnose My Crop',
      'Upload a photo and check what might be wrong.',
      AppColors.sand
    ),
    (
      '/consult',
      '👨‍🔬',
      'Ask an Expert',
      'Send my case to a verified agricultural expert.',
      AppColors.successSoft
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final demo = context.demo;
    final head =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tuesday, 6 October · Sousse',
          style: body(color: AppColors.mutedForeground)),
      Text('Good morning, Amine 👋',
          style: display(size: md ? 36 : 30, height: 1.2)),
    ]);

    return AppShell(
      role: Role.farmer,
      path: '/dashboard',
      child: ListenableBuilder(
        listenable: demo,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: md
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [Expanded(child: head), const ProtoTag()])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        head,
                        const SizedBox(height: 12),
                        const ProtoTag()
                      ]),
          ),
          if (demo.caseStatus != CaseStatus.none)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Tappable(
                radius: 16,
                color: AppColors.secondary,
                onTap: () => go(context, '/consult'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: .3),
                          width: 2),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(LucideIcons.stethoscope,
                        size: 24, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Case #2048 — tomato leaves',
                                style: body(w: FontWeight.w700)),
                            Text(
                                demo.caseStatus == CaseStatus.resolved
                                    ? 'Expert action plan is ready'
                                    : 'A verified expert is reviewing your case',
                                style: body(
                                    size: 14,
                                    color: AppColors.mutedForeground)),
                          ]),
                    ),
                    const Icon(LucideIcons.arrowRight, size: 24),
                  ]),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Tappable(
              radius: 16,
              color: AppColors.warningSoft,
              onTap: () => go(context, '/alerts'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Icon(LucideIcons.droplets,
                      size: 24, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(TextSpan(style: body(), children: [
                      TextSpan(
                          text: 'Water alert:',
                          style: body(w: FontWeight.w700)),
                      const TextSpan(
                          text: ' soil moisture is below your target range. '),
                      TextSpan(
                          text: 'Irrigation recommended today.',
                          style: body(color: AppColors.mutedForeground)),
                    ])),
                  ),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.arrowRight, size: 20),
                ]),
              ),
            ),
          ),
          ResponsiveGrid(
              cols: colsFor(context, sm: 2, lg: 4),
              gap: 12,
              children: [
                for (final (k, v) in const [
                  ('Farm', '2.5 hectares'),
                  ('Main crop', 'Tomato'),
                  ('Irrigation', 'Drip irrigation'),
                  ('Water status', 'Limited')
                ])
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k,
                              style: body(
                                  size: 14, color: AppColors.mutedForeground)),
                          Text(v,
                              style: display(
                                  size: 20,
                                  color: v == 'Limited'
                                      ? AppColors.warning
                                      : AppColors.foreground)),
                        ]),
                  ),
              ]),
          const SizedBox(height: 24),
          ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 16, children: [
            for (final a in _actions)
              Tappable(
                radius: 16,
                color: a.$5,
                onTap: () => go(context, a.$1),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.$2,
                            style:
                                const TextStyle(fontSize: 36, height: 40 / 36)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.$3, style: display(size: 20)),
                                Text(a.$4,
                                    style:
                                        body(color: AppColors.mutedForeground)),
                              ]),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(LucideIcons.arrowRight,
                                size: 24,
                                color: AppColors.foreground
                                    .withValues(alpha: .4))),
                      ]),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          ResponsiveGrid(
              cols: colsFor(context, lg: 3),
              gap: 20,
              children: [_today(), _weather(), _water(context)]),
          const SizedBox(height: 20),
          ResponsiveGrid(cols: colsFor(context, lg: 3), gap: 20, children: [
            _alerts(context),
            GridCell(span: 2, child: _progress(context))
          ]),
          const SizedBox(height: 20),
          AppCard(
            child: Builder(builder: (context) {
              final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your path as an experienced farmer',
                        style: body(w: FontWeight.w700)),
                    Text('Fast answers, expert backup when needed.',
                        style:
                            body(size: 14, color: AppColors.mutedForeground)),
                  ]);
              const journey = Journey(steps: ['Ask', 'Diagnose', 'Act']);
              const trust = TrustLabel(Trust.expert);
              return md
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          Expanded(child: intro),
                          journey,
                          const SizedBox(width: 16),
                          trust
                        ])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          intro,
                          const SizedBox(height: 16),
                          journey,
                          const SizedBox(height: 16),
                          trust
                        ]);
            }),
          ),
        ]),
      ),
    );
  }

  Widget _today() => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Today'),
          for (var i = 0; i < _todo.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Tappable(
                radius: 12,
                onTap: () => setState(
                    () => _todo[i] = (t: _todo[i].t, done: !_todo[i].done)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    Icon(
                        _todo[i].done
                            ? LucideIcons.checkCircle2
                            : LucideIcons.circle,
                        size: 24,
                        color: _todo[i].done
                            ? AppColors.primary
                            : AppColors.mutedForeground),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(_todo[i].t,
                            style: body(
                                color: _todo[i].done
                                    ? AppColors.mutedForeground
                                    : AppColors.foreground,
                                decoration: _todo[i].done
                                    ? TextDecoration.lineThrough
                                    : null))),
                  ]),
                ),
              ),
            ),
        ]),
      );

  Widget _weather() {
    Widget tile(IconData i, String t) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(12)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(i, size: 16, color: AppColors.foreground),
                  Text(t, style: body(size: 14))
                ]),
          ),
        );
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Weather & farm conditions',
            icon: Icon(LucideIcons.sun, size: 20, color: AppColors.accent)),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('31°', style: display(size: 48, height: 1)),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Sunny · tomorrow 36°',
                      style: body(color: AppColors.mutedForeground)))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          tile(LucideIcons.thermometer, 'Max 36°'),
          const SizedBox(width: 8),
          tile(LucideIcons.droplets, 'Hum. 64%'),
          const SizedBox(width: 8),
          tile(LucideIcons.wind, '12 km/h')
        ]),
        const SizedBox(height: 16),
        Tinted(
          color: AppColors.warningSoft,
          child: Text.rich(TextSpan(style: body(size: 14), children: [
            TextSpan(
                text: 'Effect on your farm:',
                style: body(size: 14, w: FontWeight.w700)),
            const TextSpan(
                text:
                    ' heat increases tomato water demand ~20–30%. Irrigate early morning; warm humid nights raise early blight risk.'),
          ])),
        ),
      ]),
    );
  }

  Widget _water(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Water',
              icon: Icon(LucideIcons.droplets,
                  size: 20, color: AppColors.chart3)),
          Text('Estimated soil moisture',
              style: body(size: 14, color: AppColors.mutedForeground)),
          const SizedBox(height: 4),
          Row(children: [
            const Expanded(child: Bar(fraction: .22, fill: AppColors.warning)),
            const SizedBox(width: 12),
            Text('22%', style: body(w: FontWeight.w700))
          ]),
          const SizedBox(height: 4),
          Text('Target range 28–35%',
              style: body(size: 12, color: AppColors.mutedForeground)),
          const SizedBox(height: 16),
          Tinted(
            color: AppColors.secondary,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recommended today', style: body(size: 14)),
              Text('18 mm', style: display(size: 24))
            ]),
          ),
          const SizedBox(height: 12),
          Text('Last irrigation: yesterday 06:30 · 14 mm',
              style: body(size: 14, color: AppColors.mutedForeground)),
          const SizedBox(height: 12),
          const TextLink('Open irrigation →', path: '/irrigation'),
        ]),
      );

  Widget _alerts(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Alerts',
              icon: Icon(LucideIcons.bell, size: 20, color: AppColors.accent)),
          for (final (i, (e, t)) in const [
            ('🌡️', 'High heat expected tomorrow'),
            ('🦠', 'Possible disease risk detected'),
            ('💧', 'Irrigation recommended today')
          ].indexed)
            InkWell(
              onTap: () => go(context, '/alerts'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    border: i < 2
                        ? const Border(
                            bottom: BorderSide(color: AppColors.border))
                        : null),
                child: Row(children: [
                  Text(e, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t, style: body()))
                ]),
              ),
            ),
        ]),
      );

  Widget _progress(BuildContext context) {
    const stages = [
      'Prep',
      'Planting',
      'Early growth',
      'Flowering',
      'Fruiting',
      'Harvest'
    ];
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Crop progress — Tomato (planted 18 Jul)'),
        const SizedBox(height: 12),
        Stack(children: [
          Positioned.fill(
            top: 12,
            bottom: null,
            child: SizedBox(
              height: 6,
              child: Stack(children: [
                Container(
                    decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(999))),
                FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: .62,
                    child: Container(
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999)))),
              ]),
            ),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < stages.length; i++)
              Expanded(
                child: Column(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: i == 4
                            ? AppColors.accent
                            : (i <= 3 ? AppColors.primary : AppColors.muted),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 4)),
                  ),
                  const SizedBox(height: 8),
                  Text(stages[i],
                      textAlign: TextAlign.center,
                      style: body(size: 12, w: FontWeight.w500)),
                ]),
              ),
          ]),
        ]),
        const SizedBox(height: 20),
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Text('Day 80 of ~125 · Fruit development started',
                  style: body(size: 14)),
              const TextLink('View crop plan →', path: '/plan'),
            ]),
      ]),
    );
  }
}
