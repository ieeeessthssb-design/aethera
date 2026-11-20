import 'package:flutter/material.dart';

import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';
import '../widgets/risk.dart';
import '../widgets/toast.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});
  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  List<RiskAlert> _alerts = [];
  Map<String, bool> _mine = {};
  List<RiskReportRow> _myReports = [];
  String _gov = '';
  String? _filter;
  String? _loadedFor;

  Future<void> _load(String uid) async {
    final c = Backend.client;
    if (c == null) return;
    try {
      final a = await c
          .from('risk_alerts')
          .select('*')
          .neq('status', 'dismissed')
          .order('last_report_at', ascending: false);
      if (mounted) setState(() => _alerts = a.map(RiskAlert.fromMap).toList());
    } catch (_) {}
    try {
      final r = await c
          .from('alert_responses')
          .select('alert_id, sees_it')
          .eq('user_id', uid);
      if (mounted)
        setState(() => _mine = {
              for (final x in r) x['alert_id'].toString(): x['sees_it'] == true
            });
    } catch (_) {}
    try {
      final r = await c
          .from('risk_reports')
          .select('id, crop, governorate, observed_on, alert_id')
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      if (mounted)
        setState(() => _myReports = r.map(RiskReportRow.fromMap).toList());
    } catch (_) {}
    try {
      final p = await c
          .from('profiles')
          .select('governorate')
          .eq('id', uid)
          .maybeSingle();
      if (mounted) setState(() => _gov = (p?['governorate'] as String?) ?? '');
    } catch (_) {}
  }

  Future<void> _saveGov(String g) async {
    final l = context.l;
    setState(() => _gov = g);
    try {
      await Backend.client
          ?.from('profiles')
          .update({'governorate': g}).eq('id', context.auth.user!.id);
      if (mounted) showToast(context, l.t('saved'), kind: ToastKind.success);
    } catch (_) {}
  }

  Future<void> _respond(RiskAlert a, bool sees) async {
    final l = context.l;
    final c = Backend.client;
    final uid = context.auth.user?.id;
    if (c == null || uid == null) return;
    try {
      try {
        await c.from('alert_responses').upsert(
            {'alert_id': a.id, 'user_id': uid, 'sees_it': sees},
            onConflict: 'alert_id,user_id');
      } catch (_) {
        // fallback when no unique constraint exists
        if (_mine.containsKey(a.id)) {
          await c
              .from('alert_responses')
              .update({'sees_it': sees})
              .eq('alert_id', a.id)
              .eq('user_id', uid);
        } else {
          await c
              .from('alert_responses')
              .insert({'alert_id': a.id, 'user_id': uid, 'sees_it': sees});
        }
      }
      if (!mounted) return;
      setState(() => _mine = {..._mine, a.id: sees});
      showToast(context, l.t('thanksResponse'), kind: ToastKind.success);
    } catch (_) {
      if (mounted) showToast(context, l.t('aiError'), kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final auth = context.auth;
    return AppShell(
      role: Role.farmer,
      path: '/radar',
      child: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final user = auth.user;
          if (user != null && _loadedFor != user.id) {
            _loadedFor = user.id;
            WidgetsBinding.instance.addPostFrameCallback((_) => _load(user.id));
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                    eyebrow: l.navLabel('Risk Radar'),
                    title: l.t('radarTitle'),
                    desc: l.t('radarDesc'),
                    actions: [
                      AppButton.link(context, '/report', l.t('reportProblem'),
                          variant: BtnVariant.accent)
                    ]),
                if (!auth.ready)
                  const SizedBox.shrink()
                else if (user == null)
                  const SignInCta()
                else
                  _content(context),
              ]);
        },
      ),
    );
  }

  Widget _content(BuildContext context) {
    final l = context.l;
    final byGov = <String, List<RiskAlert>>{};
    for (final a in _alerts) {
      byGov.putIfAbsent(a.governorate, () => []).add(a);
    }
    final shown = _filter != null
        ? _alerts.where((a) => a.governorate == _filter).toList()
        : _alerts;
    int level(String g) {
      final x = byGov[g];
      if (x == null) return 0;
      return x.any((a) => a.severity == 'high')
          ? 3
          : (x.any((a) => a.severity == 'medium') ? 2 : 1);
    }

    Widget choice(String text, bool on, VoidCallback tap) => Tappable(
          radius: 12,
          color: on ? AppColors.secondary : Colors.transparent,
          onTap: tap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(
                    color: on ? AppColors.primary : AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(12)),
            child: Text(text, style: body(w: FontWeight.w600)),
          ),
        );

    final map = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ResponsiveGrid(
            cols: colsFor(context, base: 3, sm: 4, md: 6),
            gap: 6,
            children: [
              for (final g in kGovernorates)
                Builder(builder: (context) {
                  final lv = level(g);
                  final bg = lv == 3
                      ? AppColors.dangerSoft
                      : (lv == 2
                          ? AppColors.warningSoft
                          : (lv == 1
                              ? AppColors.secondary
                              : AppColors.background));
                  final sel = _filter == g;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = sel ? null : g),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel || _gov == g
                                ? AppColors.primary
                                : AppColors.border,
                            width: sel ? 2 : 1),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g,
                                style: body(
                                    size: 12,
                                    w: FontWeight.w600,
                                    color: lv == 0
                                        ? AppColors.mutedForeground
                                        : AppColors.foreground)),
                            if (lv > 0)
                              Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                      '${byGov[g]!.fold<int>(0, (s, a) => s + a.reportCount)} ${l.t('reports')}',
                                      style:
                                          body(size: 12, w: FontWeight.w700))),
                          ]),
                    ),
                  );
                }),
            ]),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 6, children: [
          for (final (k, c) in [
            ('low', AppColors.secondary),
            ('medium', AppColors.warningSoft),
            ('high', AppColors.dangerSoft)
          ])
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(4)),
                child: Text(l.label(k), style: body(size: 12))),
        ]),
      ]),
    );

    final list = <Widget>[
      if (shown.isEmpty)
        AppCard(
            child: Text(l.t('noAlerts'),
                style: body(color: AppColors.mutedForeground))),
      for (final a in shown)
        AlertCard(alert: a, children: [
          if (a.preventiveSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.t('preventive'), style: body(size: 14, w: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final (i, s) in a.preventiveSteps.indexed)
              Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child:
                      Text('${i + 1}. ${l.label(s)}', style: body(size: 14))),
          ],
          if (a.infoRequested) ...[
            const SizedBox(height: 12),
            Tinted(
                color: AppColors.warningSoft,
                padding: const EdgeInsets.all(8),
                radius: 8,
                child: Text(l.t('infoRequested'), style: body(size: 14)))
          ],
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            choice(l.t('seeToo'), _mine[a.id] == true, () => _respond(a, true)),
            choice(l.t('notOnFarm'), _mine[a.id] == false,
                () => _respond(a, false))
          ]),
        ]),
    ];

    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      map,
      for (final w in list)
        Padding(padding: const EdgeInsets.only(top: 20), child: w)
    ]);

    final right =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
          child: FieldLabel(l.t('setGov'),
              gap: 8,
              child: AppSelect(
                  height: 44,
                  value: _gov,
                  options: ['', ...kGovernorates],
                  labelOf: (v) => v.isEmpty ? '—' : v,
                  onChanged: _saveGov))),
      const SizedBox(height: 20),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.t('myReports'), style: display(size: 16)),
          const SizedBox(height: 8),
          if (_myReports.isEmpty)
            Text(l.t('noReports'),
                style: body(size: 14, color: AppColors.mutedForeground))
          else
            for (final r in _myReports)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Builder(builder: (context) {
                  final al =
                      _alerts.where((a) => a.id == r.alertId).firstOrNull;
                  return Tinted(
                    padding: const EdgeInsets.all(8),
                    radius: 8,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                                  '${l.label(r.crop)} · ${r.governorate} · ${l.fmtDate(r.observedOn)}',
                                  style: body(size: 14))),
                          const SizedBox(width: 8),
                          if (al != null)
                            StatusBadge(al.status)
                          else
                            Text(
                                r.alertId != null
                                    ? l.t('inCluster')
                                    : l.t('waiting'),
                                style: body(size: 12)),
                        ]),
                  );
                }),
              ),
        ]),
      ),
    ]);

    return ResponsiveGrid(
        cols: colsFor(context, lg: 3),
        gap: 20,
        children: [GridCell(span: 2, child: left), right]);
  }
}
