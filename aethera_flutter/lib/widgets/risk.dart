import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import 'ab.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final (bg, fg) = switch (status) {
      'detected' => (AppColors.warningSoft, AppColors.foreground),
      'under_review' => (AppColors.sand, AppColors.foreground),
      'verified' => (AppColors.primary, AppColors.primaryForeground),
      _ => (AppColors.muted, AppColors.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (status == 'verified') ...[
          Icon(LucideIcons.shieldCheck, size: 14, color: fg),
          const SizedBox(width: 4)
        ],
        Flexible(
            child: Text(l.label(status),
                style: body(
                    size: 12,
                    w: FontWeight.w700,
                    color: fg,
                    decoration: status == 'dismissed'
                        ? TextDecoration.lineThrough
                        : null))),
      ]),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.children = const []});
  final RiskAlert alert;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final a = alert;
    final sevBg = switch (a.severity) {
      'high' => AppColors.dangerSoft,
      'medium' => AppColors.warningSoft,
      _ => AppColors.secondary
    };
    final bar = a.severity == 'high'
        ? AppColors.destructive
        : (a.severity == 'medium' ? AppColors.accent : AppColors.primary);
    return AppCard(
      startBar: bar,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.t('potentialRisk').toUpperCase(),
                  style: body(
                      size: 12,
                      w: FontWeight.w700,
                      color: AppColors.mutedForeground,
                      letterSpacing: 0.6)),
              StatusBadge(a.status),
              if (a.isDemo)
                DashedBox(
                    radius: 999,
                    color: AppColors.border,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(l.t('demoData'), style: body(size: 12))),
            ]),
        const SizedBox(height: 8),
        Text('${l.label(a.crop)} · ${l.label(a.symptomCategory)}',
            style: display(size: 18)),
        const SizedBox(height: 4),
        Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('📍 ${a.governorate}',
                  style: body(size: 14, color: AppColors.mutedForeground)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.users,
                    size: 16, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Text('${a.reportCount} ${l.t('similarReports')}',
                    style: body(size: 14, color: AppColors.mutedForeground)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                    color: sevBg, borderRadius: BorderRadius.circular(4)),
                child: Text('${l.t('severity')}: ${l.label(a.severity)}',
                    style: body(size: 14, w: FontWeight.w600)),
              ),
              Text('${l.t('updated')}: ${l.fmtDate(a.lastReportAt)}',
                  style: body(size: 14, color: AppColors.mutedForeground)),
            ]),
        const SizedBox(height: 4),
        Text(l.t('source'),
            style: body(size: 12, color: AppColors.mutedForeground)),
        if (a.status == 'verified' && (a.expertNote ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Tinted(
              color: AppColors.secondary,
              child: Text(a.expertNote!, style: body(size: 14))),
        ],
        ...children,
      ]),
    );
  }
}

class SignInCta extends StatelessWidget {
  const SignInCta({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AppCard(
      child: Column(children: [
        Text(l.t('needSignIn'), textAlign: TextAlign.center, style: body()),
        const SizedBox(height: 12),
        AppButton(label: l.t('signIn'), onPressed: () => go(context, '/auth')),
      ]),
    );
  }
}

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  List<Map<String, dynamic>> _items = [];
  String? _loadedFor;

  Future<void> _load(String uid) async {
    final c = Backend.client;
    if (c == null) return;
    try {
      final data = await c
          .from('notifications')
          .select('id, read, risk_alerts(crop, governorate)')
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) setState(() => _items = data);
    } catch (_) {}
  }

  Future<void> _open() async {
    final l = context.l;
    final unread = _items.where((i) => i['read'] != true).length;
    final items = List<Map<String, dynamic>>.from(_items);
    if (unread > 0) {
      try {
        await Backend.client
            ?.from('notifications')
            .update({'read': true}).eq('read', false);
        if (mounted){
          setState(() => _items = [
                for (final i in _items) {...i, 'read': true}
              ]);}
      } catch (_) {}
    }
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l.t('notifications'),
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) {
        final lc = L.read(ctx);
        return SafeArea(
          child: Align(
            alignment: AlignmentDirectional.topEnd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
              child: Material(
                color: AppColors.card,
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 288,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lc.t('notifications'),
                            style: body(size: 14, w: FontWeight.w700)),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          Text(lc.t('noAlerts'),
                              style: body(
                                  size: 14, color: AppColors.mutedForeground))
                        else
                          for (final n in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Tappable(
                                color: AppColors.muted,
                                radius: 8,
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  go(context, '/radar');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text.rich(TextSpan(
                                      style: body(size: 14),
                                      children: [
                                        TextSpan(text: lc.t('newRiskNear')),
                                        if (n['risk_alerts'] is Map) ...[
                                          const TextSpan(text: ': '),
                                          TextSpan(
                                              text: lc.label(
                                                  '${(n['risk_alerts'] as Map)['crop']}'),
                                              style: body(
                                                  size: 14,
                                                  w: FontWeight.w700)),
                                          TextSpan(
                                              text:
                                                  ' · ${(n['risk_alerts'] as Map)['governorate']}'),
                                        ],
                                      ])),
                                ),
                              ),
                            ),
                      ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final u = auth.user;
        if (u == null) {
          _loadedFor = null;
          return const SizedBox.shrink();
        }
        if (_loadedFor != u.id) {
          _loadedFor = u.id;
          WidgetsBinding.instance.addPostFrameCallback((_) => _load(u.id));
        }
        final unread = _items.where((i) => i['read'] != true).length;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Tooltip(
            message: context.l.t('notifications'),
            child: Tappable(
              radius: 12,
              color: AppColors.card,
              onTap: _open,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12)),
                child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      const Icon(LucideIcons.bell,
                          size: 20, color: AppColors.foreground),
                      if (unread > 0)
                        PositionedDirectional(
                          top: -4,
                          end: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                                minWidth: 20, minHeight: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: AppColors.destructive,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text('$unread',
                                style: body(
                                    size: 11,
                                    w: FontWeight.w700,
                                    color: AppColors.destructiveForeground,
                                    height: 1)),
                          ),
                        ),
                    ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dashboard card with nearby alerts (kept from the web app; shown where the radar is summarised).
class NearbyAlertsCard extends StatefulWidget {
  const NearbyAlertsCard({super.key});
  @override
  State<NearbyAlertsCard> createState() => _NearbyAlertsCardState();
}

class _NearbyAlertsCardState extends State<NearbyAlertsCard> {
  List<RiskAlert> _alerts = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = Backend.client;
    final uid = context.auth.user?.id;
    if (c == null || uid == null) return;
    try {
      final p = await c
          .from('profiles')
          .select('governorate')
          .eq('id', uid)
          .maybeSingle();
      final gov = p?['governorate'] as String?;
      final base = c.from('risk_alerts').select('*').neq('status', 'dismissed');
      final data = await (gov != null && gov.isNotEmpty
              ? base.eq('governorate', gov)
              : base)
          .order('last_report_at', ascending: false)
          .limit(3);
      if (mounted){
        setState(() => _alerts = data.map(RiskAlert.fromMap).toList());}
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final signedIn = context.auth.user != null;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(LucideIcons.radar, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l.t('radarTitle'), style: display(size: 16))),
          TextLink(l.t('viewRadar'), path: '/radar'),
        ]),
        const SizedBox(height: 12),
        if (!signedIn)
          Text(l.t('needSignIn'),
              style: body(size: 14, color: AppColors.mutedForeground))
        else if (_alerts.isEmpty)
          Text(l.t('noAlerts'),
              style: body(size: 14, color: AppColors.mutedForeground))
        else
          VStack(gap: 8, children: [
            for (final a in _alerts)
              Tinted(
                child: Row(children: [
                  Expanded(
                      child:
                          Text.rich(TextSpan(style: body(size: 14), children: [
                    TextSpan(
                        text: l.label(a.crop),
                        style: body(size: 14, w: FontWeight.w700)),
                    TextSpan(
                        text:
                            ' · ${a.governorate} · ${a.reportCount} ${l.t('reports')}')
                  ]))),
                  const SizedBox(width: 8),
                  StatusBadge(a.status),
                ]),
              ),
          ]),
      ]),
    );
  }
}
