import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _rows(List<(String, String)> rows) => Column(children: [
        for (final (i, (k, v)) in rows.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.border))
                    : null),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k, style: body(color: AppColors.mutedForeground)),
                  const SizedBox(width: 12),
                  Flexible(
                      child: Text(v,
                          textAlign: TextAlign.end,
                          style: body(w: FontWeight.w700))),
                ]),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    return AppShell(
      role: Role.farmer,
      path: '/profile',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader(
            eyebrow: 'Profile',
            title: 'Amine Ben Salem',
            desc: 'Experienced farmer · 14 years · Sousse',
            actions: [
              const ProtoTag(),
              AppButton.link(context, '/farm', 'Edit farm',
                  variant: BtnVariant.outline)
            ]),
        ResponsiveGrid(cols: colsFor(context, md: 2), gap: 20, children: [
          AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('Farmer information', style: display(size: 16)),
                const SizedBox(height: 12),
                _rows(const [
                  ('Phone', '+216 •• ••• 482'),
                  ('Language', 'Tunisian Arabic, French'),
                  ('Experience level', 'Experienced → Quick Assist default'),
                  ('Farm', '2.5 ha · Tomato · Drip'),
                  ('Water availability', 'Limited')
                ]),
              ])),
          AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('Saved plans', style: display(size: 16)),
                const SizedBox(height: 12),
                Tappable(
                  color: AppColors.muted,
                  onTap: () => go(context, '/plan'),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Tomato — Growing Plan 2026 ',
                            style: body(w: FontWeight.w600)),
                        TextSpan(
                            text: '· Stage 5/6',
                            style: body(
                                size: 14, color: AppColors.mutedForeground))
                      ]))),
                ),
                const SizedBox(height: 8),
                Tinted(
                    child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Onion — Winter 2025 ',
                      style: body(w: FontWeight.w600)),
                  TextSpan(
                      text: '· Completed',
                      style: body(size: 14, color: AppColors.mutedForeground))
                ]))),
              ])),
          AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('Consultation history', style: display(size: 16)),
                const SizedBox(height: 12),
                for (final (i, (id, t, s)) in const [
                  ('#2048', 'Yellowing tomato leaves', 'Open'),
                  ('#1712', 'Drip clogging & salinity', 'Resolved'),
                  ('#1340', 'Olive fly timing', 'Resolved')
                ].indexed)
                  InkWell(
                    onTap: () => go(context, '/consult'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                          border: i < 2
                              ? const Border(
                                  bottom: BorderSide(color: AppColors.border))
                              : null),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('$id · $t', style: body())),
                            const SizedBox(width: 8),
                            Text(s,
                                style: body(
                                    size: 14,
                                    w: FontWeight.w600,
                                    color: AppColors.primary))
                          ]),
                    ),
                  ),
              ])),
          AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('Knowledge contributions', style: display(size: 16)),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('Shade nets for July transplants',
                              style: body())),
                      const SizedBox(width: 8),
                      const TrustLabel(Trust.expert)
                    ]),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('Cleaning drippers with citric acid',
                              style: body())),
                      const SizedBox(width: 8),
                      const TrustLabel(Trust.community)
                    ]),
              ])),
        ]),
      ]),
    );
  }
}
