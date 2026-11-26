import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/toast.dart';

class _Stage {
  const _Stage(
      this.n, this.w, this.irr, this.fert, this.mon, this.risk, this.act);
  final String n, w, irr, fert, mon, risk;
  final List<String> act;
}

const _stages = [
  _Stage(
      'Land preparation',
      'Jul 1–15',
      'Pre-irrigate to field capacity',
      'Well-decomposed manure, ~20–30 t/ha',
      'Soil test pH & salinity',
      'Soil salinity, compaction',
      ['Deep plough', 'Install & test drip lines', 'Lay mulch if available']),
  _Stage('Planting', 'Jul 18', 'Light daily irrigation, 4–6 mm',
      'Starter phosphorus', 'Transplant survival', 'Heat shock, cutworms', [
    'Transplant late afternoon',
    'Space 40 cm × 1.2 m',
    'Shade young plants if > 38°C'
  ]),
  _Stage(
      'Early growth',
      'Jul 19 – Aug 20',
      '6–10 mm every 1–2 days',
      'Nitrogen via fertigation',
      'Leaf colour, whitefly',
      'Whitefly, TYLCV virus',
      ['Stake plants', 'Yellow sticky traps', 'Weed control']),
  _Stage(
      'Flowering',
      'Aug 20 – Sep 20',
      'Steady supply, avoid stress',
      'Calcium + potassium',
      'Flower drop, humidity',
      'Blossom drop in heat',
      ['Keep soil moisture even', 'Avoid excess nitrogen']),
  _Stage(
      'Fruit development',
      'Sep 20 – Oct 25',
      'Peak demand 15–20 mm/day in heat',
      'Potassium-rich fertigation',
      'Leaf spots, fruit cracks',
      'Early blight, blossom-end rot', [
    'Inspect lower leaves weekly',
    'Remove diseased foliage',
    'Fertilize — due in 2 days'
  ]),
  _Stage(
      'Harvest',
      'Oct 25 – Dec',
      'Reduce gradually',
      'None',
      'Fruit colour & firmness',
      'Post-harvest losses',
      ['Harvest at breaker stage for market', 'Grade and store shaded']),
];

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int _sel = 4;

  @override
  Widget build(BuildContext context) {
    final s = _stages[_sel];
    Widget stageBtn(int i) {
      final st = _stages[i];
      final sel = _sel == i;
      final bg = sel
          ? AppColors.primary
          : (i < 4 ? AppColors.secondary : AppColors.card);
      final border = sel
          ? AppColors.primary
          : (i < 4 ? Colors.transparent : AppColors.border);
      final fg = sel ? AppColors.primaryForeground : AppColors.foreground;
      return Tappable(
        radius: 16,
        color: bg,
        onTap: () => setState(() => _sel = i),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              border: Border.all(color: border, width: 2),
              borderRadius: BorderRadius.circular(16)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('STAGE ${i + 1}',
                style: body(
                    size: 12,
                    w: FontWeight.w700,
                    color: fg.withValues(alpha: .7))),
            const SizedBox(height: 4),
            Text(st.n, style: display(size: 16, color: fg, height: 1.25)),
            const SizedBox(height: 8),
            Text(st.w, style: body(size: 12, color: fg.withValues(alpha: .75))),
            if (i == 4) ...[
              const SizedBox(height: 8),
              const Tag('NOW', size: 10)
            ],
          ]),
        ),
      );
    }

    final info = [
      (LucideIcons.droplets, 'Irrigation', s.irr),
      (LucideIcons.flaskConical, 'Fertilization', s.fert),
      (LucideIcons.eye, 'Monitoring', s.mon),
      (LucideIcons.alertTriangle, 'Common risks', s.risk),
    ];

    return AppShell(
      role: Role.farmer,
      path: '/plan',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(
            eyebrow: 'Crop plan',
            title: 'Tomato — Growing Plan',
            desc: 'Sousse · Plot A · 2.5 ha · Drip · Season Jul–Dec 2026',
            actions: [ProtoTag(), TrustLabel(Trust.expert)]),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth < 720 ? 720.0 : c.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: w,
              child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < _stages.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: stageBtn(i))
                      ],
                    ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        ResponsiveGrid(
            cols: colsFor(context, md: 2, lg: 4),
            gap: 16,
            children: [
              for (final (i, t, v) in info)
                AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Icon(i, size: 24, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(t,
                          style:
                              body(size: 14, color: AppColors.mutedForeground)),
                      Text(v, style: body(w: FontWeight.w600))
                    ])),
            ]),
        const SizedBox(height: 16),
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(LucideIcons.listChecks,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Recommended actions — ${s.n}',
                      style: display(size: 18)))
            ]),
            const SizedBox(height: 12),
            ResponsiveGrid(cols: colsFor(context, sm: 3), gap: 8, children: [
              for (final a in s.act)
                Tappable(
                  radius: 12,
                  color: AppColors.muted,
                  onTap: () => showToast(context, 'Added to Today: $a',
                      kind: ToastKind.success),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a, style: body(w: FontWeight.w500)),
                          Text('+ Add to today',
                              style: body(size: 12, color: AppColors.primary))
                        ]),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Text(
                'Values are indicative ranges from validated regional guides and should be adjusted to observed plant and soil conditions.',
                style: body(size: 12, color: AppColors.mutedForeground)),
          ]),
        ),
      ]),
    );
  }
}
