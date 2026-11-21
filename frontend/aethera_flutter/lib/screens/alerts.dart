import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';

const _alerts = [
  (
    '🌡️',
    'Heat alert',
    'High temperatures expected tomorrow (36°C).',
    AppColors.dangerSoft,
    'Tomorrow',
    [
      'Irrigate early morning (05:30–08:30)',
      'Avoid fertilizing or spraying at midday',
      'Check young fruit for sunscald'
    ],
    '/irrigation'
  ),
  (
    '💧',
    'Water alert',
    'Your soil moisture is below your target range.',
    AppColors.warningSoft,
    'Now',
    ['Apply 18 mm today', 'Check drip line B for clogging'],
    '/irrigation'
  ),
  (
    '🦠',
    'Crop risk',
    'Conditions may increase disease risk (warm, humid nights).',
    AppColors.sand,
    'This week',
    [
      'Inspect lower leaves for ringed spots',
      'Improve airflow; avoid wetting foliage',
      'Use Diagnose if you see symptoms'
    ],
    '/diagnose'
  ),
  (
    '📅',
    'Action reminder',
    'Fertilization stage starts tomorrow.',
    AppColors.secondary,
    'Tomorrow',
    ['Prepare potassium-rich fertigation', 'Follow your crop plan dose'],
    '/plan'
  ),
];

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      role: Role.farmer,
      path: '/alerts',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(
            eyebrow: 'Alerts',
            title: 'What needs your attention',
            desc: 'Personalised for Tomato · Sousse · drip · limited water.',
            actions: [ProtoTag()]),
        VStack(gap: 12, children: [
          for (final (i, a) in _alerts.indexed)
            AppCard(
              padding: EdgeInsets.zero,
              color: a.$4,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _open = _open == i ? -1 : i),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(children: [
                          Text(a.$1,
                              style:
                                  const TextStyle(fontSize: 30, height: 1.2)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      children: [
                                        Text(a.$2,
                                            style: body(
                                                size: 18, w: FontWeight.w700)),
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: AppColors.card,
                                                borderRadius:
                                                    BorderRadius.circular(999)),
                                            child: Text(a.$5,
                                                style: body(
                                                    size: 12,
                                                    w: FontWeight.w600))),
                                      ]),
                                  Text(a.$3, style: body()),
                                ]),
                          ),
                          if (context.isSm)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('What should I do?',
                                    style: body(size: 14, w: FontWeight.w600))),
                          AnimatedRotation(
                              turns: _open == i ? .5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(LucideIcons.chevronDown,
                                  size: 24, color: AppColors.foreground)),
                        ]),
                      ),
                    ),
                    if (_open == i)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: AppColors.foreground
                                        .withValues(alpha: .1)))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final (j, d) in a.$6.indexed)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          NumDot(j + 1, size: 24, fontSize: 12),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Text(d, style: body()))
                                        ])),
                              const SizedBox(height: 8),
                              AppButton.link(context, a.$7, 'Take action'),
                            ]),
                      ),
                  ]),
            ),
        ]),
      ]),
    );
  }
}
