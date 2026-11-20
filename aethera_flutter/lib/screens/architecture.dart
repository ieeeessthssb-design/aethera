import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';

const _flow = [
  ('Farmer App', 'React + TypeScript · offline-first PWA'),
  ('Backend API', 'Python / FastAPI · secure user authentication'),
  ('Farm Database + Knowledge Base', 'PostgreSQL · pgvector embeddings'),
  (
    'AI / RAG Engine',
    'LLM + retrieval over verified knowledge · crop disease image model · confidence scoring'
  ),
  (
    'Expert Validation',
    'Low-confidence cases routed to experts · answers fed back as knowledge'
  ),
  ('Personalized Recommendation', 'Action plan with sources and confidence'),
];

class ArchitectureScreen extends StatelessWidget {
  const ArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final flow = Column(children: [
      for (final (i, (t, d)) in _flow.indexed) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: i == 3
                  ? AppColors.forest
                  : (i == 4 ? AppColors.secondary : AppColors.card),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(t,
                textAlign: TextAlign.center,
                style: display(
                    size: 18,
                    color: i == 3
                        ? AppColors.forestForeground
                        : AppColors.foreground)),
            Text(d,
                textAlign: TextAlign.center,
                style: body(
                    size: 14,
                    color: (i == 3
                            ? AppColors.forestForeground
                            : AppColors.foreground)
                        .withValues(alpha: .8))),
          ]),
        ),
        if (i < _flow.length - 1)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Icon(LucideIcons.arrowDown,
                  size: 24, color: AppColors.earth)),
      ],
    ]);
    final side =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DashedBox(
        radius: 16,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Optional IoT', style: body(w: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final (i, x) in const [
            'ESP32 + soil moisture sensor',
            'IoT API',
            'Farm Data',
            'AI'
          ].indexed)
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${i > 0 ? '↓ ' : ''}$x', style: body(size: 14))),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('External integrations',
              style: body(size: 14, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Maps & weather APIs, SMS/WhatsApp notifications.',
              style: body(size: 14, color: AppColors.mutedForeground))
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI behaviour', style: body(size: 14, w: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final (i, x) in const [
            'Understand question',
            'Retrieve verified info',
            'Apply farm context',
            'Generate action',
            'Show sources',
            'Estimate confidence',
            'Escalate when low'
          ].indexed)
            Text('${i + 1}. $x',
                style: body(size: 14, color: AppColors.mutedForeground)),
        ]),
      ),
    ]);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
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
                    const SizedBox(height: 16),
                    Text('Technical architecture',
                        style:
                            display(size: 36, w: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 8),
                    Text(
                        'A controlled decision-support system — not an all-knowing AI. The prototype uses mock data in place of these integrations.',
                        style: body(color: AppColors.mutedForeground)),
                    const SizedBox(height: 32),
                    if (md)
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: flow),
                            const SizedBox(width: 24),
                            SizedBox(width: 280, child: side)
                          ])
                    else
                      Column(
                          children: [flow, const SizedBox(height: 24), side]),
                    const SizedBox(height: 40),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
