import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/toast.dart';

const _topics = [
  'What should I plant?',
  'How do I prepare my land?',
  'How often should I irrigate?',
  'What fertilizer should I use?',
  'How do I protect my crop?',
  'When should I harvest?'
];
const List<(String, List<String>)> _qs = [
  ('Where is your farm?', ['Sousse', 'Kairouan', 'Nabeul', 'Sfax']),
  ('How big is it?', ['< 1 ha', '1–3 ha', '3–10 ha']),
  ("What's your soil like?", ['Sandy-loam', 'Clay', 'Sandy', 'Not sure']),
  ('How much water do you have?', ['Limited', 'Moderate', 'Abundant']),
  ('Which season are you planting?', ['Spring', 'Summer', 'Autumn', 'Winter']),
  ("What's your budget?", ['Low', 'Medium', 'High']),
  (
    "What's your main objective?",
    [
      'Profitability',
      'Low water consumption',
      'Easy management',
      'Local demand'
    ]
  ),
];
const List<(String, int, List<String>)> _recs = [
  (
    'Tomato',
    89,
    [
      'Suitable conditions for sandy-loam soil in Sousse',
      'Strong local relevance — high demand in Sahel markets',
      'Water requirements compatible with drip irrigation'
    ]
  ),
  ('Onion', 82, ['Lower water needs', 'Easy storage and sale']),
  ('Chili', 76, ['Good value per hectare', 'Higher labour at harvest']),
];

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});
  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String? _topic;
  int _step = 0;
  final List<String?> _ans = List.filled(_qs.length, null);

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final done = _step >= _qs.length;
    Widget body0;
    if (_topic == null) {
      body0 = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What do you want help with?',
            style: display(size: md ? 36 : 30, height: 1.2)),
        const SizedBox(height: 8),
        Text(
            "Pick one. We'll ask a few simple questions and explain everything.",
            style: body(color: AppColors.mutedForeground)),
        const SizedBox(height: 24),
        ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 12, children: [
          for (final (i, t) in _topics.indexed)
            AppCard(
              padding: const EdgeInsets.all(20),
              onTap: () => i == 0
                  ? setState(() => _topic = t)
                  : showToast(
                      context, 'In this prototype, try “What should I plant?”'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(children: [
                  Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.sprout,
                          size: 24, color: AppColors.primary)),
                  const SizedBox(width: 16),
                  Expanded(
                      child:
                          Text(t, style: body(size: 18, w: FontWeight.w600))),
                ]),
              ),
            ),
        ]),
      ]);
    } else if (!done) {
      body0 = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GestureDetector(
              onTap: () => setState(() => _step == 0 ? _topic = null : _step--),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(children: [
                  const Icon(LucideIcons.arrowLeft,
                      size: 16, color: AppColors.mutedForeground),
                  const SizedBox(width: 4),
                  Text('Back',
                      style: body(
                          size: 14,
                          w: FontWeight.w600,
                          color: AppColors.mutedForeground))
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                for (var i = 0; i < _qs.length; i++)
                  Expanded(
                      child: Container(
                          height: 8,
                          margin: EdgeInsetsDirectional.only(
                              end: i < _qs.length - 1 ? 4 : 0),
                          decoration: BoxDecoration(
                              color: i <= _step
                                  ? AppColors.primary
                                  : AppColors.muted,
                              borderRadius: BorderRadius.circular(999)))),
              ]),
            ),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                              child: const Icon(LucideIcons.sprout,
                                  size: 20,
                                  color: AppColors.primaryForeground)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                  color: AppColors.muted,
                                  borderRadius: BorderRadiusDirectional.only(
                                      topEnd: Radius.circular(16),
                                      bottomStart: Radius.circular(16),
                                      bottomEnd: Radius.circular(16))),
                              child: Text(_qs[_step].$1,
                                  style: body(size: 18, w: FontWeight.w600)),
                            ),
                          ),
                        ]),
                    const SizedBox(height: 20),
                    ResponsiveGrid(
                        cols: colsFor(context, sm: 2),
                        gap: 12,
                        children: [
                          for (final o in _qs[_step].$2)
                            Tappable(
                              radius: 12,
                              color: _ans[_step] == o
                                  ? AppColors.secondary
                                  : AppColors.background,
                              onTap: () => setState(() {
                                _ans[_step] = o;
                                _step++;
                              }),
                              child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 56),
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: _ans[_step] == o
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(o,
                                    textAlign: TextAlign.center,
                                    style: body(size: 18, w: FontWeight.w600)),
                              ),
                            ),
                        ]),
                  ]),
            ),
          ]),
        ),
      );
    } else {
      body0 = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Recommended crops for you', style: display(size: 30)),
        const SizedBox(height: 4),
        Text('Based on: ${_ans.whereType<String>().join(' · ')}',
            style: body(color: AppColors.mutedForeground)),
        const SizedBox(height: 20),
        ResponsiveGrid(cols: colsFor(context, md: 3), gap: 16, children: [
          for (final (i, r) in _recs.indexed)
            AppCard(
              borderColor: i == 0 ? AppColors.primary : AppColors.border,
              borderWidth: i == 0 ? 2 : 1,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.$1, style: display(size: 24)),
                          if (i == 0) const Tag('Best match')
                        ]),
                    const SizedBox(height: 12),
                    Text('Suitability',
                        style:
                            body(size: 14, color: AppColors.mutedForeground)),
                    Row(children: [
                      Expanded(child: Bar(fraction: r.$2 / 100)),
                      const SizedBox(width: 12),
                      Text('${r.$2}%',
                          style: body(size: 20, w: FontWeight.w700))
                    ]),
                    const SizedBox(height: 16),
                    Text('Why:', style: body(size: 14, w: FontWeight.w700)),
                    const SizedBox(height: 4),
                    for (final w in r.$3)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(
                                      left: 4, right: 10, top: 1),
                                  child: Text('•', style: body(size: 14))),
                              Expanded(child: Text(w, style: body(size: 14))),
                            ]),
                      ),
                  ]),
            ),
        ]),
        const SizedBox(height: 20),
        AppCard(
          child: Builder(builder: (context) {
            final left = Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const TrustLabel(Trust.ai),
                  Text(
                      'Built from expert-verified crop suitability guides for the Sahel region. Scores are indicative.',
                      style: body(size: 14, color: AppColors.mutedForeground)),
                ]);
            final actions = Wrap(spacing: 8, runSpacing: 8, children: [
              AppButton(
                  label: 'Start over',
                  variant: BtnVariant.ghost,
                  onPressed: () => setState(() {
                        _step = 0;
                        _ans.fillRange(0, _ans.length, null);
                      })),
              AppButton.link(context, '/plan', 'Build my crop plan',
                  variant: BtnVariant.accent),
            ]);
            return md
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Expanded(child: left),
                        const SizedBox(width: 16),
                        actions
                      ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [left, const SizedBox(height: 12), actions]);
          }),
        ),
      ]);
    }
    return AppShell(
      role: Role.farmer,
      path: '/guide',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: Journey(
                          steps: const ['Guide Me', 'Learn', 'Plan', 'Act'],
                          active: done ? 2 : 1)),
                  const SizedBox(width: 8),
                  const ProtoTag()
                ])),
        body0,
      ]),
    );
  }
}
