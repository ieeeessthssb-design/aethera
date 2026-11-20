import 'package:flutter/material.dart';

import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import 'ab.dart';
import 'fields.dart';

const _cats = [
  'All',
  'Crops',
  'Diseases',
  'Irrigation',
  'Soil',
  'Fertilization',
  'Climate',
  'Pest management',
  'Local practices'
];

class KItem {
  const KItem(
      this.t, this.cat, this.region, this.crop, this.src, this.by, this.date,
      {this.isNew = false});
  final String t, cat, region, crop, src, by, date;
  final bool isNew;
}

const kItems = [
  KItem(
      'Tomato irrigation under water scarcity',
      'Irrigation',
      'Sousse',
      'Tomato',
      'CRDA Sousse field trials',
      'M. Gharbi, irrigation engineer',
      'Mar 2026'),
  KItem('Recognising early blight vs. nutrient yellowing', 'Diseases', 'Sahel',
      'Tomato', 'INRAT plant pathology guide', 'Dr. L. Trabelsi', 'Jan 2026'),
  KItem(
      'Managing salinity in drip-irrigated sandy-loam',
      'Soil',
      'Sousse / Monastir',
      'Vegetables',
      'Regional soil survey',
      'S. Ayari, soil scientist',
      'Nov 2025'),
  KItem('Whitefly & TYLCV prevention in summer tomato', 'Pest management',
      'Nabeul', 'Tomato', 'Extension bulletin', 'Dr. K. Mansour', 'Jun 2025'),
  KItem('Potassium fertigation during fruit set', 'Fertilization', 'Tunisia',
      'Tomato', 'Fertigation handbook', 'S. Ayari', 'Feb 2026'),
  KItem(
      'Shade nets for July transplants',
      'Local practices',
      'Msaken',
      'Tomato',
      'Farmer practice, expert-reviewed',
      'Dr. L. Trabelsi',
      'Aug 2025'),
  KItem('Heatwave preparation for open-field crops', 'Climate', 'Centre-East',
      'All', 'Met data + agronomy review', 'Dr. K. Mansour', 'May 2026'),
  KItem('Onion planting windows in Kairouan', 'Crops', 'Kairouan', 'Onion',
      'CRDA Kairouan', 'M. Gharbi', 'Sep 2025'),
];

class KnowledgeHub extends StatefulWidget {
  const KnowledgeHub({super.key});
  @override
  State<KnowledgeHub> createState() => _KnowledgeHubState();
}

class _KnowledgeHubState extends State<KnowledgeHub> {
  String _cat = 'All';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final demo = context.demo;
    return ListenableBuilder(
      listenable: demo,
      builder: (context, _) {
        final extra = demo.published
            ? [
                const KItem(
                    'Case #2048: early blight confirmed under heat + over-irrigation',
                    'Diseases',
                    'Sousse',
                    'Tomato',
                    'Expert-reviewed farmer case',
                    'Dr. L. Trabelsi',
                    'Oct 2026',
                    isNew: true)
              ]
            : <KItem>[];
        final list = [...extra, ...kItems]
            .where((i) =>
                (_cat == 'All' || i.cat == _cat) &&
                i.t.toLowerCase().contains(_q.toLowerCase()))
            .toList();
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                  eyebrow: 'Trusted Knowledge Hub',
                  title: 'Knowledge you can act on',
                  desc:
                      'Not a blog. Every item is reviewed, sourced, dated and tied to a region and crop.',
                  actions: [ProtoTag()]),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v),
                    style: body(),
                    decoration: fieldDecoration(
                            hint: 'Search verified knowledge…',
                            padding: const EdgeInsets.symmetric(horizontal: 16))
                        .copyWith(
                      fillColor: AppColors.card,
                      prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(LucideIcons.search,
                              size: 20, color: AppColors.mutedForeground)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 52),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final c in _cats)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _cat = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: _cat == c
                                    ? AppColors.primary
                                    : AppColors.card,
                                border: _cat == c
                                    ? null
                                    : Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(999)),
                            child: Text(c,
                                style: body(
                                    size: 14,
                                    w: FontWeight.w600,
                                    color: _cat == c
                                        ? AppColors.primaryForeground
                                        : AppColors.foreground)),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              ResponsiveGrid(cols: colsFor(context, md: 2), gap: 16, children: [
                for (final i in list)
                  AppCard(
                    borderColor: i.isNew ? AppColors.accent : AppColors.border,
                    borderWidth: i.isNew ? 2 : 1,
                    startBar: AppColors.success,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const TrustLabel(Trust.expert),
                                  if (i.isNew)
                                    const Tag('NEW from case review'),
                                  Text(i.cat,
                                      style: body(
                                          size: 12,
                                          color: AppColors.mutedForeground)),
                                ]),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 4),
                              child: Text(i.t, style: display(size: 18))),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child: Text.rich(
                                                kv('Region', i.region))),
                                        const SizedBox(width: 16),
                                        Expanded(
                                            child:
                                                Text.rich(kv('Crop', i.crop)))
                                      ]),
                                  const SizedBox(height: 4),
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                            child:
                                                Text.rich(TextSpan(children: [
                                          TextSpan(
                                              text: 'Source: ',
                                              style: body(
                                                  size: 14,
                                                  color: AppColors
                                                      .mutedForeground)),
                                          TextSpan(
                                              text: i.src,
                                              style: body(size: 14))
                                        ]))),
                                        const SizedBox(width: 16),
                                        Expanded(
                                            child:
                                                Text.rich(TextSpan(children: [
                                          TextSpan(
                                              text: 'Date: ',
                                              style: body(
                                                  size: 14,
                                                  color: AppColors
                                                      .mutedForeground)),
                                          TextSpan(
                                              text: i.date,
                                              style: body(size: 14))
                                        ]))),
                                      ]),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Verified by agricultural expert · ${i.by}',
                                      style: body(
                                          size: 12,
                                          color: AppColors.mutedForeground)),
                                ]),
                          ),
                        ]),
                  ),
              ]),
              const SizedBox(height: 32),
              AppCard(
                color: AppColors.secondary,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(LucideIcons.shieldCheck,
                            size: 24, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Why we trust this',
                                style: display(size: 20)))
                      ]),
                      const SizedBox(height: 16),
                      ResponsiveGrid(
                          cols: colsFor(context, sm: 2, lg: 4),
                          gap: 16,
                          children: [
                            for (final (ic, t, x) in const [
                              (
                                LucideIcons.fileCheck2,
                                'Named sources',
                                'Every item cites where it comes from.'
                              ),
                              (
                                LucideIcons.shieldCheck,
                                'Expert review',
                                'Validated by a credentialed specialist.'
                              ),
                              (
                                LucideIcons.mapPin,
                                'Local fit',
                                'Tagged by region, crop and season.'
                              ),
                              (
                                LucideIcons.refreshCw,
                                'Kept current',
                                'Re-reviewed; outdated items are flagged.'
                              ),
                            ])
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(ic,
                                        size: 24, color: AppColors.primary),
                                    const SizedBox(height: 4),
                                    Text(t, style: body(w: FontWeight.w700)),
                                    Text(x, style: body(size: 14))
                                  ]),
                          ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(LucideIcons.users, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Community experience lives in the Community — it only enters this hub after expert validation.',
                                style: body(size: 14)))
                      ]),
                    ]),
              ),
            ]);
      },
    );
  }
}
