import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/toast.dart';

const List<(String, int, int)> _week = [
  ('Wed', 12, 26),
  ('Thu', 14, 25),
  ('Fri', 0, 22),
  ('Sat', 15, 27),
  ('Sun', 14, 25),
  ('Mon', 14, 23),
  ('Tue', 0, 22)
];

class IrrigationScreen extends StatelessWidget {
  const IrrigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final today = AppCard(
      color: AppColors.forest,
      borderColor: AppColors.border,
      child: DefaultTextStyle(
        style: body(color: AppColors.forestForeground),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Today · Recommended irrigation',
              style: body(
                  size: 14,
                  color: AppColors.forestForeground.withValues(alpha: .8))),
          Text('18 mm',
              style: display(
                  size: 60,
                  w: FontWeight.w800,
                  color: AppColors.forestForeground,
                  height: 1)),
          const SizedBox(height: 8),
          Text.rich(TextSpan(
              style: body(size: 14, color: AppColors.forestForeground),
              children: [
                TextSpan(
                    text: 'Reason:',
                    style: body(
                        size: 14,
                        w: FontWeight.w700,
                        color: AppColors.forestForeground)),
                const TextSpan(text: ' High temperature + low soil moisture')
              ])),
          const SizedBox(height: 4),
          Text('Best window: 05:30 – 08:30 · ~2 h 40 min on your drip line',
              style: body(
                  size: 14,
                  color: AppColors.forestForeground.withValues(alpha: .8))),
          const SizedBox(height: 20),
          AppButton(
              variant: BtnVariant.accent,
              expand: true,
              icon: LucideIcons.droplets,
              label: 'Log as done',
              onPressed: () => showToast(context, 'Irrigation logged: 18 mm',
                  kind: ToastKind.success)),
        ]),
      ),
    );

    final chart = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Recent irrigation & soil moisture', style: display(size: 16)),
        const SizedBox(height: 16),
        SizedBox(
          height: 176,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final (i, (d, mm, sm)) in _week.indexed)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                      end: i < _week.length - 1 ? 12 : 0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(mm == 0 ? '–' : '$mm',
                            style: body(size: 12, w: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                            height: mm * 6.0 + 4,
                            decoration: BoxDecoration(
                                color: AppColors.chart3.withValues(alpha: .7),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)))),
                        const SizedBox(height: 4),
                        Bar(
                            fraction: sm * 2.5 / 100,
                            height: 6,
                            fill: AppColors.warning),
                        const SizedBox(height: 4),
                        Text(d,
                            style: body(
                                size: 12, color: AppColors.mutedForeground)),
                      ]),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Text(
            'Bars: irrigation (mm). Lines: estimated soil moisture (%), modelled from weather + logs.',
            style: body(size: 12, color: AppColors.mutedForeground)),
      ]),
    );

    Widget node(IconData i, String t, String d) => DashedBox(
          radius: 16,
          background: AppColors.background,
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(i, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(t,
                textAlign: TextAlign.center, style: body(w: FontWeight.w700)),
            Text(d,
                textAlign: TextAlign.center,
                style: body(size: 12, color: AppColors.mutedForeground)),
          ]),
        );
    final nodes = [
      node(LucideIcons.radio, 'Soil moisture probe', 'Capacitive, 20 cm depth'),
      node(LucideIcons.cpu, 'ESP32 board', 'Reads every 30 min, solar powered'),
      node(LucideIcons.wifi, 'Wi-Fi / GSM',
          'Buffers offline, sends when online'),
      node(LucideIcons.server, 'Aethera IoT API',
          '→ Farm data → AI recommendation'),
    ];
    Widget arrow() => Padding(
        padding: const EdgeInsets.all(8),
        child: Transform.rotate(
            angle: md ? 0 : 1.5708,
            child: const Icon(LucideIcons.arrowRight,
                size: 24, color: AppColors.earth)));

    final sensorHead =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.muted, borderRadius: BorderRadius.circular(999)),
          child: Text('OPTIONAL · FUTURE',
              style: body(size: 12, w: FontWeight.w700))),
      const SizedBox(height: 8),
      Text('Connect a soil sensor', style: display(size: 20)),
      Text(
          'Aethera works without sensors. A low-cost sensor can make moisture readings real instead of estimated.',
          style: body(size: 14, color: AppColors.mutedForeground)),
    ]);
    final sensorStatus = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.muted, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: AppColors.destructive, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('Soil sensor: Not connected',
            style: body(size: 14, w: FontWeight.w600)),
      ]),
    );
    final sensor = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        md
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: sensorHead),
                const SizedBox(width: 12),
                sensorStatus
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                sensorHead,
                const SizedBox(height: 12),
                sensorStatus
              ]),
        const SizedBox(height: 24),
        if (md)
          IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < nodes.length; i++) ...[
                Expanded(child: nodes[i]),
                if (i < nodes.length - 1) Center(child: arrow())
              ],
            ]),
          )
        else
          Column(children: [
            for (var i = 0; i < nodes.length; i++) ...[
              nodes[i],
              if (i < nodes.length - 1) arrow()
            ]
          ]),
        const SizedBox(height: 20),
        Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
                variant: BtnVariant.outline,
                icon: LucideIcons.sparkles,
                label: 'Connect soil sensor',
                onPressed: () => showToast(
                    context, 'Sensor pairing is planned for a later version'))),
      ]),
    );

    return AppShell(
      role: Role.farmer,
      path: '/irrigation',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(
            eyebrow: 'Irrigation & water',
            title: 'Water management',
            desc: 'Make every litre count on limited water.',
            actions: [ProtoTag()]),
        ResponsiveGrid(
            cols: colsFor(context, sm: 2, lg: 4),
            gap: 16,
            children: const [
              Stat(
                  label: 'Farm water status',
                  value: 'Limited',
                  sub: 'Well quota: 62% remaining'),
              Stat(label: 'Soil moisture', value: '22%', sub: 'Target 28–35%'),
              Stat(
                  label: 'Water used (7 days)',
                  value: '69 mm',
                  sub: '≈ 1,725 m³ on 2.5 ha'),
              Stat(
                  label: 'Estimated water saved',
                  value: '14%',
                  sub: 'vs. fixed schedule'),
            ]),
        const SizedBox(height: 20),
        ResponsiveGrid(
            cols: colsFor(context, lg: 3),
            gap: 20,
            children: [today, GridCell(span: 2, child: chart)]),
        const SizedBox(height: 20),
        sensor,
      ]),
    );
  }
}
