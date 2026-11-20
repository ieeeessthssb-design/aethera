import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';

class _Plan {
  const _Plan(this.n, this.p, this.s, this.f, this.cta, {this.hl = false});
  final String n, p, s, cta;
  final List<String> f;
  final bool hl;
}

const _plans = [
  _Plan(
      'Free',
      '0 TND',
      'forever',
      [
        'Basic AI questions',
        'Farm profile',
        'Basic crop guidance',
        'Basic alerts',
        'Community access'
      ],
      'Start free'),
  _Plan(
      'Farmer Plus',
      '9.90 TND',
      '/ month',
      [
        'Personalized crop plans',
        'Advanced diagnosis',
        'Advanced irrigation recommendations',
        'More AI assistance',
        'Priority support'
      ],
      'Try Farmer Plus',
      hl: true),
  _Plan(
      'Expert consultation',
      'Pay per case',
      'from 15 TND',
      [
        'Verified agricultural expert',
        'Photos + AI assessment attached',
        'Written action plan',
        'Follow-up message'
      ],
      'Ask an expert'),
  _Plan(
      'Organizations',
      'Custom',
      'pricing',
      [
        'Cooperatives',
        'Agricultural organizations',
        'NGOs',
        'Agricultural businesses',
        'Sponsor seats for member farmers'
      ],
      'Contact us'),
];

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final padX = md ? 32.0 : 16.0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padX),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Logo(),
                              AppButton.link(context, '/dashboard', 'Open demo',
                                  variant: BtnVariant.outline)
                            ])),
                    const SizedBox(height: 24),
                    Text('Simple, fair pricing',
                        textAlign: TextAlign.center,
                        style: display(
                            size: md ? 48 : 36,
                            w: FontWeight.w800,
                            height: 1.1)),
                    const SizedBox(height: 12),
                    Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 576),
                            child: Text(
                                'Farmers access the knowledge. Organizations help scale it.',
                                textAlign: TextAlign.center,
                                style: body(
                                    size: 18,
                                    color: AppColors.mutedForeground)))),
                    const SizedBox(height: 40),
                    ResponsiveGrid(
                        cols: colsFor(context, md: 2, lg: 4),
                        gap: 20,
                        children: [
                          for (final p in _plans)
                            AppCard(
                              padding: const EdgeInsets.all(24),
                              color:
                                  p.hl ? AppColors.secondary : AppColors.card,
                              borderColor:
                                  p.hl ? AppColors.primary : AppColors.border,
                              borderWidth: p.hl ? 2 : 1,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (p.hl)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: const Tag('Most popular')),
                                    Text(p.n, style: display(size: 20)),
                                    const SizedBox(height: 8),
                                    Text.rich(TextSpan(children: [
                                      TextSpan(
                                          text: p.p,
                                          style: display(
                                              size: 30, w: FontWeight.w800)),
                                      TextSpan(
                                          text: ' ${p.s}',
                                          style: body(
                                              color: AppColors.mutedForeground))
                                    ])),
                                    const SizedBox(height: 20),
                                    for (final f in p.f)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(LucideIcons.check,
                                                    size: 20,
                                                    color: AppColors.primary),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child:
                                                        Text(f, style: body()))
                                              ])),
                                    const Spacer(),
                                    const SizedBox(height: 16),
                                    AppButton.link(
                                        context,
                                        p.n == 'Expert consultation'
                                            ? '/consult'
                                            : '/onboarding',
                                        p.cta,
                                        variant: p.hl
                                            ? BtnVariant.primary
                                            : BtnVariant.outline,
                                        expand: true),
                                  ]),
                            ),
                        ]),
                    const SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(md ? 40 : 32),
                      decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(24)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Not dependent on farmer subscriptions alone',
                                style: display(
                                    size: 24,
                                    color: AppColors.forestForeground)),
                            const SizedBox(height: 8),
                            ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 768),
                                child: Text(
                                    'Revenue blends Farmer Plus, per-consultation fees (shared with experts), organization licences for cooperatives and NGOs, and partnerships with input suppliers and agricultural programmes — keeping the core free for smallholders.',
                                    style: body(
                                        color: AppColors.forestForeground
                                            .withValues(alpha: .85)))),
                          ]),
                    ),
                    const SizedBox(height: 16),
                    Text('Prototype pricing for illustration.',
                        textAlign: TextAlign.center,
                        style:
                            body(size: 12, color: AppColors.mutedForeground)),
                    const SizedBox(height: 40),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
