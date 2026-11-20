import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/knowledge_hub.dart';
import '../widgets/toast.dart';

enum KStatus { draft, underReview, expertVerified, outdated, archived }

extension on KStatus {
  String get label => switch (this) {
        KStatus.draft => 'Draft',
        KStatus.underReview => 'Under Review',
        KStatus.expertVerified => 'Expert Verified',
        KStatus.outdated => 'Outdated',
        KStatus.archived => 'Archived'
      };
  (Color, Color) get colors => switch (this) {
        KStatus.draft => (AppColors.muted, AppColors.foreground),
        KStatus.underReview => (AppColors.warningSoft, AppColors.foreground),
        KStatus.expertVerified => (AppColors.successSoft, AppColors.success),
        KStatus.outdated => (AppColors.dangerSoft, AppColors.destructive),
        KStatus.archived => (AppColors.muted, AppColors.mutedForeground),
      };
}

class _Row {
  _Row(this.t, this.type, this.from, this.s);
  final String t, type, from;
  KStatus s;
}

Widget _statusPill(KStatus s) {
  final (bg, fg) = s.colors;
  return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child:
          Text(s.label, style: body(size: 12, w: FontWeight.w600, color: fg)));
}

class ValidationQueue extends StatefulWidget {
  const ValidationQueue({super.key});
  @override
  State<ValidationQueue> createState() => _ValidationQueueState();
}

class _ValidationQueueState extends State<ValidationQueue> {
  final List<_Row> _rows = [
    _Row('Copper use limits on tomato', 'Pending expert validation',
        'Dr. L. Trabelsi', KStatus.underReview),
    _Row('Citric acid to unclog drippers', 'Community submission',
        'Rim B., farmer', KStatus.draft),
    _Row('AI answer: pepper wilting in Kairouan (41%)',
        'AI recommendation needing review', 'AI engine', KStatus.underReview),
    _Row('Whitefly thresholds (2019 bulletin)', 'Source', 'Extension office',
        KStatus.outdated),
    _Row('Tomato irrigation under water scarcity', 'Knowledge item',
        'M. Gharbi', KStatus.expertVerified),
  ];

  void _set(_Row r, KStatus s, String msg) {
    setState(() => r.s = s);
    showToast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final d = context.demo;
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) {
        final all = [
          if (d.published)
            _Row(
                'Case #2048: early blight + over-irrigation',
                'From expert case review',
                'Dr. L. Trabelsi',
                KStatus.expertVerified),
          ..._rows
        ];
        Widget act(String t, VoidCallback on, {bool primary = false}) =>
            Tappable(
              radius: 8,
              color: primary ? AppColors.primary : Colors.transparent,
              onTap: on,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      border:
                          primary ? null : Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(t,
                      style: body(
                          size: 14,
                          w: FontWeight.w600,
                          color: primary
                              ? AppColors.primaryForeground
                              : AppColors.foreground))),
            );
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final s in KStatus.values) _statusPill(s)]),
              const SizedBox(height: 12),
              VStack(gap: 12, children: [
                for (final r in all)
                  AppCard(
                    child: Builder(builder: (context) {
                      final info = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.t, style: body(w: FontWeight.w700)),
                            Text('${r.type} · ${r.from}',
                                style: body(
                                    size: 14, color: AppColors.mutedForeground))
                          ]);
                      final actions =
                          Wrap(spacing: 6, runSpacing: 6, children: [
                        act('Approve',
                            () => _set(r, KStatus.expertVerified, 'Approved'),
                            primary: true),
                        act('Reject', () => _set(r, KStatus.draft, 'Rejected')),
                        act(
                            'Request Review',
                            () => _set(
                                r, KStatus.underReview, 'Review requested')),
                        act('Archive',
                            () => _set(r, KStatus.archived, 'Archived')),
                      ]);
                      return context.isMd
                          ? Row(children: [
                              Expanded(child: info),
                              const SizedBox(width: 12),
                              _statusPill(r.s),
                              const SizedBox(width: 12),
                              Flexible(child: actions)
                            ])
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  info,
                                  const SizedBox(height: 12),
                                  _statusPill(r.s),
                                  const SizedBox(height: 12),
                                  actions
                                ]);
                    }),
                  ),
              ]),
            ]);
      },
    );
  }
}

class AdminOverview extends StatelessWidget {
  const AdminOverview({super.key});
  @override
  Widget build(BuildContext context) => ResponsiveGrid(
          cols: colsFor(context, sm: 2, lg: 4),
          gap: 12,
          children: const [
            Stat(label: 'Farmers', value: '3,482', sub: '+212 this month'),
            Stat(label: 'Verified experts', value: '46'),
            Stat(label: 'Open cases', value: '27', sub: 'Avg. 3.4 h response'),
            Stat(
                label: 'Knowledge items',
                value: '1,214',
                sub: '89% expert verified'),
          ]);
}

class DataTableCard extends StatelessWidget {
  const DataTableCard({super.key, required this.head, required this.rows});
  final List<String> head;
  final List<List<String>> rows;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minWidth: context.vw - (context.isLg ? 288 + 64 : 32) - 2),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: const TableBorder(
                  horizontalInside: BorderSide(color: AppColors.border)),
              children: [
                TableRow(
                    decoration: const BoxDecoration(color: AppColors.muted),
                    children: [
                      for (final h in head)
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(h,
                                style: body(size: 14, w: FontWeight.w600)))
                    ]),
                for (final r in rows)
                  TableRow(children: [
                    for (final c in r)
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(c, style: body(size: 14)))
                  ]),
              ],
            ),
          ),
        ),
      );
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => AppShell(
        role: Role.admin,
        path: '/admin',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageHeader(
              eyebrow: 'Admin',
              title: 'Platform overview',
              actions: [ProtoTag()]),
          const AdminOverview(),
          const SizedBox(height: 32),
          Text('Needs attention', style: display(size: 20)),
          const SizedBox(height: 12),
          const ValidationQueue(),
        ]),
      );
}

const kAdminTitles = {
  'users': 'Users',
  'experts': 'Experts',
  'cases': 'Cases',
  'validation': 'Knowledge Validation',
  'knowledge': 'Knowledge Base',
  'reports': 'Reports'
};

class AdminSectionScreen extends StatelessWidget {
  const AdminSectionScreen({super.key, required this.section});
  final String section;

  @override
  Widget build(BuildContext context) {
    final path = '/admin/$section';
    if (section == 'knowledge'){
      return AppShell(
          role: Role.admin, path: path, child: const KnowledgeHub());}
    Widget bodyW;
    switch (section) {
      case 'validation':
        bodyW = const ValidationQueue();
      case 'users':
        bodyW = const DataTableCard(head: [
          'Farmer',
          'Region',
          'Level',
          'Plan',
          'Joined'
        ], rows: [
          [
            'Amine Ben Salem',
            'Sousse',
            'Experienced',
            'Farmer Plus',
            'Mar 2026'
          ],
          ['Sami K.', 'Sidi Bouzid', 'Beginner', 'Free', 'Aug 2026'],
          ['Rim B.', 'Kalâa Kebira', 'Intermediate', 'Free', 'Jan 2026'],
          [
            'Coop. El Amal (42 seats)',
            'Kairouan',
            '—',
            'Organization',
            'May 2026'
          ],
        ]);
      case 'experts':
        bodyW = const DataTableCard(head: [
          'Expert',
          'Specialty',
          'Cases',
          'Rating',
          'Status'
        ], rows: [
          ['Dr. Leila Trabelsi', 'Plant pathology', '128', '4.9', 'Verified'],
          ['Mohamed Gharbi', 'Irrigation', '94', '4.8', 'Verified'],
          ['Sonia Ayari', 'Soil & fertilization', '71', '4.7', 'Verified'],
          ['Dr. Karim Mansour', 'Entomology', '12', '—', 'Credentials pending'],
        ]);
      case 'cases':
        bodyW = const DataTableCard(head: [
          'Case',
          'Crop',
          'Region',
          'AI conf.',
          'Status'
        ], rows: [
          ['#2048', 'Tomato', 'Sousse', '72%', 'Expert review'],
          ['#2045', 'Pepper', 'Kairouan', '41%', 'Awaiting expert'],
          ['#2039', 'Olive', 'Sfax', '58%', 'Awaiting expert'],
          ['#2031', 'Tomato', 'Monastir', '64%', 'Resolved'],
        ]);
      default:
        bodyW =
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const AdminOverview(),
          const SizedBox(height: 20),
          AppCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI escalation rate (weekly)', style: display(size: 16)),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final (i, v)
                      in const [34, 31, 29, 27, 24, 22, 21].indexed)
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.only(end: i < 6 ? 12 : 0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$v%', style: body(size: 12)),
                              const SizedBox(height: 4),
                              Container(
                                  height: v * 2.4,
                                  decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(8)))),
                              const SizedBox(height: 4),
                              Text('W${i + 34}',
                                  style: body(
                                      size: 12,
                                      color: AppColors.mutedForeground)),
                            ]),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              Text('Fewer escalations as validated knowledge grows.',
                  style: body(size: 14, color: AppColors.mutedForeground)),
            ]),
          ),
        ]);
    }
    return AppShell(
        role: Role.admin,
        path: path,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader(
              eyebrow: 'Admin',
              title: kAdminTitles[section] ?? '',
              actions: const [ProtoTag()]),
          bodyW
        ]));
  }
}
