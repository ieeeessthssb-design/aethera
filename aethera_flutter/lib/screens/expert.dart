import 'package:flutter/material.dart';

import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';
import '../widgets/knowledge_hub.dart';
import '../widgets/risk.dart';
import '../widgets/toast.dart';



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
          .select('*');
      
if (mounted) {
  setState(() {
    _alerts = a.map(RiskAlert.fromMap).toList();
  });
}
} catch (_) {}

try {
      final r = await c
          .from('risk_reports')
          .select(
              'id, crop, governorate, symptoms, locality, observed_on, photo_path, alert_id')
          .not('alert_id', 'is', null);
      if (mounted){
        setState(() => _reports = r.map(RiskReportRow.fromMap).toList());
     } }catch (_) {}
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

// ─ Sections ──

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
