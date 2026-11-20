import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';
import '../widgets/knowledge_hub.dart';
import '../widgets/risk.dart';
import '../widgets/toast.dart';

// ───────────────────────── Dashboard ─────────────────────────

class ExpertDashboardScreen extends StatelessWidget {
  const ExpertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = context.demo;
    const cases = [
      ('2048', 'Tomato disease', 'Sousse', 72, 'Medium', true),
      ('2045', 'Pepper wilting', 'Kairouan', 41, 'High', false),
      ('2039', 'Olive leaf spots', 'Sfax', 58, 'Low', false),
      ('2031', 'Drip salinity', 'Monastir', 64, 'Medium', false),
    ];
    return AppShell(
      role: Role.expert,
      path: '/expert',
      child: ListenableBuilder(
        listenable: d,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageHeader(
              eyebrow: 'Expert workspace',
              title: 'Welcome, Dr. Trabelsi',
              actions: [ProtoTag()]),
          ResponsiveGrid(
              cols: colsFor(context, base: 2, sm: 3, lg: 5),
              gap: 12,
              children: [
                Stat(
                    label: 'New cases',
                    value: d.caseStatus == CaseStatus.submitted ? '4' : '3'),
                const Stat(label: 'Awaiting review', value: '7'),
                Stat(
                    label: 'Resolved',
                    value: d.caseStatus == CaseStatus.resolved ? '129' : '128',
                    sub: 'this season'),
                const Stat(label: 'Avg. response', value: '3.2 h'),
                Stat(
                    label: 'Knowledge contributions',
                    value: d.published ? '35' : '34'),
              ]),
          const SizedBox(height: 32),
          Text('Case queue', style: display(size: 20)),
          const SizedBox(height: 12),
          VStack(gap: 12, children: [
            for (final (id, t, loc, conf, pr, live) in cases)
              AppCard(
                child: Builder(builder: (context) {
                  final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text('Case #$id',
                                  style: body(size: 18, w: FontWeight.w700)),
                              if (live &&
                                  d.caseStatus != CaseStatus.none &&
                                  d.caseStatus != CaseStatus.resolved)
                                const Tag('NEW'),
                              if (live && d.caseStatus == CaseStatus.resolved)
                                const Tag('Resolved',
                                    bg: AppColors.successSoft,
                                    fg: AppColors.success),
                            ]),
                        Text.rich(TextSpan(children: [
                          TextSpan(
                              text: '$t · Location: $loc · AI confidence: ',
                              style: body(
                                  size: 14, color: AppColors.mutedForeground)),
                          TextSpan(
                              text: '$conf%',
                              style: body(size: 14, w: FontWeight.w700)),
                          TextSpan(
                              text: ' · Priority: ',
                              style: body(
                                  size: 14, color: AppColors.mutedForeground)),
                          TextSpan(
                              text: pr,
                              style: body(size: 14, w: FontWeight.w700)),
                        ])),
                      ]);
                  final actions = Wrap(spacing: 8, runSpacing: 8, children: [
                    AppButton.link(context, '/expert/review', 'Review'),
                    AppButton.link(context, '/expert/review', 'Respond',
                        variant: BtnVariant.outline),
                    AppButton(
                        variant: BtnVariant.soft,
                        label: 'Request more information',
                        onPressed: () => showToast(
                            context, 'Information request sent to farmer')),
                  ]);
                  return context.isMd
                      ? Row(children: [
                          Expanded(child: info),
                          const SizedBox(width: 12),
                          Flexible(child: actions)
                        ])
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              info,
                              const SizedBox(height: 12),
                              actions
                            ]);
                }),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ───────────────────────── Case review ─────────────────────────

class ExpertReviewScreen extends StatefulWidget {
  const ExpertReviewScreen({super.key});
  @override
  State<ExpertReviewScreen> createState() => _ExpertReviewScreenState();
}

List<double> _hueRotate(double deg) {
  final r = deg * 3.141592653589793 / 180;
  final c = _cos(r), s = _sin(r);
  return [
    0.213 + c * 0.787 - s * 0.213,
    0.715 - c * 0.715 - s * 0.715,
    0.072 - c * 0.072 + s * 0.928,
    0,
    0,
    0.213 - c * 0.213 + s * 0.143,
    0.715 + c * 0.285 + s * 0.140,
    0.072 - c * 0.072 - s * 0.283,
    0,
    0,
    0.213 - c * 0.213 - s * 0.787,
    0.715 - c * 0.715 + s * 0.715,
    0.072 + c * 0.928 + s * 0.072,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

double _cos(double x) => _taylor(x, true);
double _sin(double x) => _taylor(x, false);
double _taylor(double x, bool cos) {
  double term = cos ? 1 : x, sum = term;
  for (var n = 1; n < 10; n++) {
    term *= -x * x / (cos ? (2 * n - 1) * (2 * n) : (2 * n) * (2 * n + 1));
    sum += term;
  }
  return sum;
}

class _ExpertReviewScreenState extends State<ExpertReviewScreen> {
  String _verdict = 'correct';
  String _urg = 'Medium';
  final _text = TextEditingController(
      text:
          'Early blight confirmed, worsened by over-irrigation 2 days ago combined with heat. Yellowing is partly water-logging stress, not nitrogen deficiency.');
  final _plan = TextEditingController(
      text:
          'Remove and bag lower infected leaves today\nReturn to 16–18 mm early morning, no evening irrigation\nApply a registered copper or chlorothalonil fungicide per label, once\nRe-inspect in 5 days and send a new photo');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final d = context.demo;
      if (d.caseStatus == CaseStatus.submitted)
        d.set(caseStatus: CaseStatus.reviewing);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _plan.dispose();
    super.dispose();
  }

  void _save(bool publish) {
    final d = context.demo;
    d.set(
        caseStatus: CaseStatus.resolved,
        expertVerdict: _text.text,
        expertPlan: _plan.text.split('\n').where((s) => s.isNotEmpty).toList(),
        published: publish || d.published);
    showToast(
        context,
        publish
            ? 'Published as validated knowledge'
            : 'Validated answer sent to Amine',
        kind: ToastKind.success);
    if (publish) go(context, '/expert/knowledge');
  }

  Widget _kvGrid(List<(String, String)> rows) =>
      ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 8, children: [
        for (final (k, v) in rows)
          Tinted(
              radius: 8,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text.rich(kv(k, v))),
      ]);

  Widget _chips(List<String> opts, String sel, ValueChanged<String> on) => Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final u in opts)
              GestureDetector(
                onTap: () => on(u),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color:
                            sel == u ? AppColors.secondary : Colors.transparent,
                        border: Border.all(
                            color: sel == u
                                ? AppColors.primary
                                : AppColors.border),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(u, style: body(size: 14, w: FontWeight.w600))),
              ),
          ]);

  @override
  Widget build(BuildContext context) {
    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Farmer & farm context', style: display(size: 16)),
        const SizedBox(height: 12),
        _kvGrid(const [
          ('Farmer', 'Amine Ben Salem · experienced'),
          ('Farm', '2.5 ha · sandy-loam, slightly saline'),
          ('Crop', 'Tomato · day 80 · fruiting'),
          ('Irrigation', 'Drip · water limited'),
          ('Weather', '31–36°C, humid nights'),
          ('Previous actions', 'Increased irrigation 2 days ago')
        ]),
      ])),
      const SizedBox(height: 20),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Uploaded photos', style: display(size: 16)),
        const SizedBox(height: 12),
        Row(children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: i < 2 ? 8 : 0),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: i == 1
                          ? Matrix4.diagonal3Values(-1, 1, 1)
                          : Matrix4.identity(),
                      child: i == 2
                          ? ColorFiltered(
                              colorFilter: ColorFilter.matrix(_hueRotate(15)),
                              child: Image.asset(
                                  'assets/images/tomato-leaf.jpg',
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Case photo 3'))
                          : Image.asset('assets/images/tomato-leaf.jpg',
                              fit: BoxFit.cover,
                              semanticLabel: 'Case photo ${i + 1}'),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ])),
      const SizedBox(height: 20),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('AI analysis', style: display(size: 16)),
              const Confidence(level: Conf.medium, value: 72)
            ]),
        const SizedBox(height: 8),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: 'Early blight (possible)', style: body(w: FontWeight.w700)),
          TextSpan(
              text:
                  ' — ringed brown lesions on older leaves. Alternatives considered: Septoria leaf spot, Mg deficiency, water stress.',
              style: body())
        ])),
      ])),
      const SizedBox(height: 20),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Your decision', style: display(size: 16)),
        const SizedBox(height: 12),
        Row(children: [
          for (final (i, (k, l)) in const [
            ('confirm', 'Confirm'),
            ('correct', 'Correct'),
            ('reject', 'Reject')
          ].indexed)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: i < 2 ? 8 : 0),
                child: Tappable(
                  radius: 12,
                  color: _verdict == k
                      ? AppColors.secondary
                      : AppColors.background,
                  onTap: () => setState(() => _verdict = k),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: _verdict == k
                                ? AppColors.primary
                                : AppColors.border,
                            width: 2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('$l diagnosis',
                        textAlign: TextAlign.center,
                        style: body(
                            size: context.isSm ? 16 : 13, w: FontWeight.w600)),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        FieldLabel('Diagnosis note',
            child: AppTextField(controller: _text, maxLines: 3)),
        const SizedBox(height: 12),
        FieldLabel('Recommendation (one action per line)',
            child: AppTextField(controller: _plan, maxLines: 4)),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Urgency:', style: body(size: 14, w: FontWeight.w600)),
              _chips(const ['Low', 'Medium', 'High'], _urg,
                  (v) => setState(() => _urg = v))
            ]),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          AppButton(
              label: 'Save validated answer', onPressed: () => _save(false)),
          AppButton(
              variant: BtnVariant.outline,
              label: 'Request additional information',
              onPressed: () => showToast(
                  context, 'Asked farmer for a photo of stems and fruit')),
        ]),
      ])),
    ]);

    final right =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Previous farmer actions', style: display(size: 16)),
        const SizedBox(height: 12),
        for (final t in const [
          'Oct 4 — irrigation raised to 22 mm',
          'Oct 2 — potassium fertigation',
          'Sep 28 — no spray applied'
        ])
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(t, style: body(size: 14))),
      ])),
      const SizedBox(height: 20),
      AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(LucideIcons.bookOpenCheck,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Relevant sources', style: display(size: 16))
        ]),
        const SizedBox(height: 12),
        for (final t in const [
          'Early blight vs. nutrient yellowing',
          'Tomato irrigation under water scarcity',
          'Similar case #1902, Msaken'
        ])
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text(t, style: body(size: 14)),
                    const TrustLabel(Trust.expert)
                  ])),
      ])),
      const SizedBox(height: 20),
      AppCard(
        color: AppColors.warningSoft,
        borderColor: AppColors.accent,
        borderWidth: 2,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Close the loop', style: display(size: 16)),
          Text(
              'Turn this validated answer into trusted knowledge for other farmers in the Sahel.',
              style: body(size: 14)),
          const SizedBox(height: 12),
          AppButton(
              label: 'Publish as validated knowledge',
              expand: true,
              onPressed: () => _save(true)),
        ]),
      ),
    ]);

    return AppShell(
      role: Role.expert,
      path: '/expert/review',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(
            eyebrow: 'Case review',
            title: 'Case #2048 — Yellowing tomato leaves',
            desc: 'Submitted by Amine Ben Salem · Sousse · today 09:14',
            actions: [ProtoTag(), TrustLabel(Trust.ai)]),
        ResponsiveGrid(
            cols: colsFor(context, lg: 3),
            gap: 20,
            children: [GridCell(span: 2, child: left), right]),
      ]),
    );
  }
}

// ───────────────────────── Risk review ─────────────────────────

class ExpertRisksScreen extends StatefulWidget {
  const ExpertRisksScreen({super.key});
  @override
  State<ExpertRisksScreen> createState() => _ExpertRisksScreenState();
}

class _ExpertRisksScreenState extends State<ExpertRisksScreen> {
  List<RiskAlert> _alerts = [];
  List<RiskReportRow> _reports = [];
  bool _loaded = false;

  Future<void> _load() async {
    final c = Backend.client;
    if (c == null) return;
    try {
      final a = await c
          .from('risk_alerts')
          .select('*')
          .order('last_report_at', ascending: false);
      if (mounted) setState(() => _alerts = a.map(RiskAlert.fromMap).toList());
    } catch (_) {}
    try {
      final r = await c
          .from('risk_reports')
          .select(
              'id, crop, governorate, symptoms, locality, observed_on, photo_path, alert_id')
          .not('alert_id', 'is', null);
      if (mounted)
        setState(() => _reports = r.map(RiskReportRow.fromMap).toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final auth = context.auth;
    return AppShell(
      role: Role.expert,
      path: '/expert/risks',
      child: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          if (auth.isExpert && !_loaded) {
            _loaded = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _load());
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                    eyebrow: l.navLabel('Risk Review'),
                    title: l.t('reviewTitle')),
                if (!auth.ready)
                  const SizedBox.shrink()
                else if (auth.user == null)
                  const SignInCta()
                else if (!auth.isExpert)
                  AppCard(child: Text(l.t('notExpert'), style: body()))
                else
                  VStack(gap: 20, children: [
                    if (_alerts.isEmpty)
                      AppCard(
                          child: Text(l.t('noAlerts'),
                              style: body(color: AppColors.mutedForeground))),
                    for (final a in _alerts)
                      _ReviewItem(
                          key: ValueKey(a.id),
                          alert: a,
                          reports:
                              _reports.where((r) => r.alertId == a.id).toList(),
                          userId: auth.user!.id,
                          onDone: _load),
                  ]),
              ]);
        },
      ),
    );
  }
}

class _ReviewItem extends StatefulWidget {
  const _ReviewItem(
      {super.key,
      required this.alert,
      required this.reports,
      required this.userId,
      required this.onDone});
  final RiskAlert alert;
  final List<RiskReportRow> reports;
  final String userId;
  final VoidCallback onDone;
  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  late final _note = TextEditingController(text: widget.alert.expertNote ?? '');
  late final _steps =
      TextEditingController(text: widget.alert.preventiveSteps.join('\n'));

  @override
  void dispose() {
    _note.dispose();
    _steps.dispose();
    super.dispose();
  }

  Future<void> _update(Map<String, dynamic> patch) async {
    final l = context.l;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await Backend.client?.from('risk_alerts').update({
        ...patch,
        'expert_note': _note.text.isEmpty ? null : _note.text,
        'preventive_steps': _steps.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'reviewed_by': widget.userId,
        'reviewed_at': now,
        'updated_at': now,
      }).eq('id', widget.alert.id);
      if (!mounted) return;
      showToast(context, l.t('saved'), kind: ToastKind.success);
      widget.onDone();
    } catch (_) {
      if (mounted) showToast(context, l.t('aiError'), kind: ToastKind.error);
    }
  }

  Future<void> _openPhoto(String path) async {
    try {
      final url = await Backend.client!.storage
          .from('report-photos')
          .createSignedUrl(path, 120);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
            backgroundColor: AppColors.card,
            child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain))),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final a = widget.alert;
    return AlertCard(alert: a, children: [
      const SizedBox(height: 12),
      Text('${l.t('responses')}: 👍 ${a.sameCount} · 👎 ${a.notCount}',
          style: body(size: 14, color: AppColors.mutedForeground)),
      if (widget.reports.isNotEmpty) ...[
        const SizedBox(height: 12),
        for (final r in widget.reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Tinted(
              padding: const EdgeInsets.all(8),
              radius: 8,
              child: Text.rich(TextSpan(style: body(size: 14), children: [
                TextSpan(
                    text:
                        '${l.fmtDate(r.observedOn)}${(r.locality ?? '').isNotEmpty ? ' · ${r.locality}' : ''} — ${r.symptoms.isEmpty ? '—' : r.symptoms}'),
                if (r.photoPath != null)
                  WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                          onTap: () => _openPhoto(r.photoPath!),
                          child: const Padding(
                              padding: EdgeInsetsDirectional.only(start: 8),
                              child: Text('📷')))),
              ])),
            ),
          ),
      ],
      const SizedBox(height: 16),
      FieldLabel(l.t('expertNote'),
          child: AppTextField(controller: _note, maxLines: 2)),
      const SizedBox(height: 12),
      FieldLabel(l.t('stepsOnePerLine'),
          child: AppTextField(controller: _steps, maxLines: 3)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (a.status == 'detected')
          AppButton(
              variant: BtnVariant.soft,
              label: l.t('startReview'),
              onPressed: () =>
                  _update({'status': 'under_review', 'info_requested': false})),
        AppButton(
            variant: BtnVariant.outline,
            label: l.t('requestInfo'),
            onPressed: () =>
                _update({'info_requested': true, 'status': 'under_review'})),
        AppButton(
            label: l.t('markVerified'),
            onPressed: () =>
                _update({'status': 'verified', 'info_requested': false})),
        AppButton(
            variant: BtnVariant.outline,
            label: l.t('markUnconfirmed'),
            onPressed: () =>
                _update({'status': 'unconfirmed', 'info_requested': false})),
        AppButton(
            variant: BtnVariant.ghost,
            label: l.t('markDismissed'),
            onPressed: () =>
                _update({'status': 'dismissed', 'info_requested': false})),
      ]),
    ]);
  }
}

// ───────────────────────── Sections ─────────────────────────

const kExpertSections = ['knowledge', 'contributions', 'messages', 'profile'];

class ExpertSectionScreen extends StatelessWidget {
  const ExpertSectionScreen({super.key, required this.section});
  final String section;

  @override
  Widget build(BuildContext context) {
    Widget bodyW;
    if (section == 'knowledge') {
      bodyW = const KnowledgeHub();
    } else if (section == 'contributions') {
      bodyW = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(title: 'My contributions', actions: [ProtoTag()]),
        VStack(gap: 12, children: [
          for (final (t, k, s) in const [
            (
              'Early blight vs. nutrient yellowing',
              Trust.expert,
              'Jan 2026 · cited 412×'
            ),
            (
              'Shade nets for July transplants',
              Trust.expert,
              'Aug 2025 · cited 96×'
            ),
            (
              'Copper use limits on tomato',
              Trust.unverified,
              'Draft · under review'
            )
          ])
            AppCard(
                child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t, style: body(w: FontWeight.w700)),
                        Text(s,
                            style: body(
                                size: 14, color: AppColors.mutedForeground))
                      ]),
                  TrustLabel(k),
                ])),
        ]),
      ]);
    } else if (section == 'messages') {
      bodyW = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(title: 'Messages', actions: [ProtoTag()]),
        VStack(gap: 12, children: [
          for (final (n, m) in const [
            ('Amine Ben Salem', "Thanks — I'll send new photos in 5 days."),
            ('Sami K.', 'Is it the same problem as Msaken?'),
            ('CRDA Sousse', 'Field visit planned Thursday.')
          ])
            AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(n, style: body(w: FontWeight.w700)),
                  Text(m, style: body(color: AppColors.mutedForeground))
                ])),
        ]),
      ]);
    } else {
      bodyW = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const PageHeader(
            title: 'Dr. Leila Trabelsi',
            desc: 'Plant pathologist · INRAT · 12 years · Sahel region',
            actions: [ProtoTag()]),
        AppCard(
          child:
              ResponsiveGrid(cols: colsFor(context, sm: 3), gap: 8, children: [
            for (final (k, v) in const [
              ('Specialties', 'Solanaceae diseases'),
              ('Rating', '4.9 / 5'),
              ('Verified', 'Credentials checked Mar 2026')
            ])
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k,
                    style: body(size: 14, color: AppColors.mutedForeground)),
                Text(v, style: body(w: FontWeight.w700))
              ]),
          ]),
        ),
      ]);
    }
    return AppShell(role: Role.expert, path: '/expert/$section', child: bodyW);
  }
}
