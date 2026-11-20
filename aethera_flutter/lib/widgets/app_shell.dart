import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../core/scope.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import 'ab.dart';
import 'risk.dart';

enum Role { farmer, expert, admin }

class NavItem {
  const NavItem(this.to, this.label, this.icon);
  final String to;
  final String label;
  final IconData icon;
}

const Map<Role, List<NavItem>> kNav = {
  Role.farmer: [
    NavItem('/dashboard', 'Dashboard', LucideIcons.layoutDashboard),
    NavItem('/farm', 'My Farm', LucideIcons.tractor),
    NavItem('/guide', 'Guide Me', LucideIcons.sprout),
    NavItem('/assist', 'Quick Assist', LucideIcons.zap),
    NavItem('/diagnose', 'Diagnose', LucideIcons.scanSearch),
    NavItem('/irrigation', 'Irrigation', LucideIcons.droplets),
    NavItem('/plan', 'Crop Plan', LucideIcons.calendarRange),
    NavItem('/radar', 'Risk Radar', LucideIcons.radar),
    NavItem('/alerts', 'Alerts', LucideIcons.bell),
    NavItem('/knowledge', 'Knowledge Hub', LucideIcons.bookOpenCheck),
    NavItem('/community', 'Community', LucideIcons.users),
    NavItem('/consult', 'Experts', LucideIcons.stethoscope),
    NavItem('/profile', 'Profile', LucideIcons.userRound),
  ],
  Role.expert: [
    NavItem('/expert', 'Dashboard', LucideIcons.layoutDashboard),
    NavItem('/expert/review', 'Cases', LucideIcons.folderKanban),
    NavItem('/expert/risks', 'Risk Review', LucideIcons.radar),
    NavItem('/expert/knowledge', 'Knowledge Base', LucideIcons.library),
    NavItem('/expert/contributions', 'Contributions', LucideIcons.award),
    NavItem('/expert/messages', 'Messages', LucideIcons.messageSquare),
    NavItem('/expert/profile', 'Profile', LucideIcons.userRound),
  ],
  Role.admin: [
    NavItem('/admin', 'Dashboard', LucideIcons.layoutDashboard),
    NavItem('/admin/users', 'Users', LucideIcons.users),
    NavItem('/admin/experts', 'Experts', LucideIcons.stethoscope),
    NavItem('/admin/cases', 'Cases', LucideIcons.folderKanban),
    NavItem(
        '/admin/validation', 'Knowledge Validation', LucideIcons.shieldCheck),
    NavItem('/admin/knowledge', 'Knowledge Base', LucideIcons.library),
    NavItem('/admin/reports', 'Reports', LucideIcons.barChart3),
  ],
};

class _Who {
  const _Who(this.name, this.sub, this.init);
  final String name, sub, init;
}

const Map<Role, _Who> _who = {
  Role.farmer: _Who('Amine Ben Salem', 'Sousse · 2.5 ha', 'AB'),
  Role.expert: _Who('Dr. Leila Trabelsi', 'Plant pathologist', 'LT'),
  Role.admin: _Who('Admin Console', 'Knowledge team', 'AD'),
};
const Map<Role, String> kHome = {
  Role.farmer: '/dashboard',
  Role.expert: '/expert',
  Role.admin: '/admin'
};

class Logo extends StatelessWidget {
  const Logo({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () =>
            Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: light ? AppColors.sidebarPrimary : AppColors.primary,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(LucideIcons.leaf,
                size: 20,
                color: light
                    ? AppColors.sidebarPrimaryForeground
                    : AppColors.primaryForeground),
          ),
          const SizedBox(width: 8),
          Text('Aethera',
              style: display(
                  size: 20,
                  color: light
                      ? AppColors.sidebarForeground
                      : AppColors.foreground)),
        ]),
      );
}

/// Top-bar tools: language switch, notification bell, sign in / out.
class _Tools extends StatelessWidget {
  const _Tools();
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final auth = context.auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
        const LangSwitch(),
        const SizedBox(width: 8),
        const NotificationBell(),
        if (auth.user != null)
          _SquareBtn(
              icon: LucideIcons.logOut,
              tooltip: l.t('signOut'),
              onTap: () => auth.signOut())
        else
          Tappable(
            radius: 12,
            color: AppColors.card,
            onTap: () => go(context, '/auth'),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.logIn,
                    size: 16, color: AppColors.foreground),
                if (context.isSm) ...[
                  const SizedBox(width: 8),
                  Text(l.t('signIn'), style: body(size: 14, w: FontWeight.w600))
                ],
              ]),
            ),
          ),
      ]),
    );
  }
}

class _SquareBtn extends StatelessWidget {
  const _SquareBtn({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip ?? '',
        child: Tappable(
          radius: 12,
          color: AppColors.card,
          onTap: onTap,
          child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: AppColors.foreground)),
        ),
      );
}

/// Layout used by every signed-in page: sidebar (≥1024 px), top bar, bottom tab bar + drawer on phones.
class AppShell extends StatefulWidget {
  const AppShell(
      {super.key, required this.role, required this.path, required this.child});
  final Role role;

  /// Current route path (used to highlight the active menu item).
  final String path;
  final Widget child;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  bool _active(String to) {
    final home = kHome[widget.role]!;
    return widget.path == to || (to != home && widget.path.startsWith('$to/'));
  }

  void _navigate(String to) {
    if (_key.currentState?.isDrawerOpen ?? false) Navigator.of(context).pop();
    if (to != widget.path) goTab(context, to);
  }

  Widget _sidebar({required bool drawer}) {
    final l = context.l;
    final items = kNav[widget.role]!;
    final w = _who[widget.role]!;
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: drawer,
        bottom: drawer,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Logo(light: true),
            if (drawer)
              GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(LucideIcons.x,
                      size: 24, color: AppColors.sidebarForeground)),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: AppColors.sidebarAccent.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              for (final r in Role.values)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (drawer) Navigator.of(context).pop();
                      if (r != widget.role) goTab(context, kHome[r]!);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: r == widget.role
                              ? AppColors.sidebarPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        r.name[0].toUpperCase() + r.name.substring(1),
                        style: body(
                            size: 12,
                            w: FontWeight.w600,
                            color: r == widget.role
                                ? AppColors.sidebarPrimaryForeground
                                : AppColors.sidebarForeground
                                    .withValues(alpha: .8)),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: _active(it.to)
                        ? AppColors.sidebarAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _navigate(it.to),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(children: [
                          Icon(it.icon,
                              size: 20,
                              color: _active(it.to)
                                  ? AppColors.sidebarPrimary
                                  : AppColors.sidebarForeground
                                      .withValues(alpha: .8)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(l.navLabel(it.label),
                                style: body(
                                    size: 15,
                                    w: FontWeight.w500,
                                    color: _active(it.to)
                                        ? AppColors.sidebarAccentForeground
                                        : AppColors.sidebarForeground
                                            .withValues(alpha: .8))),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.sidebarAccent.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(12)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(LucideIcons.wifiOff,
                    size: 16, color: AppColors.sidebarPrimary),
                const SizedBox(width: 8),
                Text('Offline-ready',
                    style: body(
                        size: 12,
                        w: FontWeight.w600,
                        color: AppColors.sidebarForeground)),
              ]),
              const SizedBox(height: 4),
              Text('Last synced 08:12 · 3 items queued',
                  style: body(
                      size: 12,
                      color:
                          AppColors.sidebarForeground.withValues(alpha: .75))),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: AppColors.sidebarBorder))),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.sidebarPrimary, shape: BoxShape.circle),
                child: Text(w.init,
                    style: body(
                        w: FontWeight.w700,
                        color: AppColors.sidebarPrimaryForeground)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name,
                          overflow: TextOverflow.ellipsis,
                          style: body(
                              size: 14,
                              w: FontWeight.w600,
                              color: AppColors.sidebarForeground)),
                      Text(w.sub,
                          overflow: TextOverflow.ellipsis,
                          style: body(
                              size: 14,
                              color: AppColors.sidebarForeground
                                  .withValues(alpha: .7))),
                    ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bottomBar() {
    final l = context.l;
    final items = kNav[widget.role]!;
    final bar = widget.role == Role.farmer
        ? items
            .where((i) => const [
                  '/dashboard',
                  '/assist',
                  '/diagnose',
                  '/alerts'
                ].contains(i.to))
            .toList()
        : items.take(4).toList();
    Widget cell(IconData icon, String text, bool on, VoidCallback tap) =>
        Expanded(
          child: InkWell(
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 20,
                    color: on ? AppColors.primary : AppColors.mutedForeground),
                const SizedBox(height: 2),
                Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(
                        size: 11,
                        w: FontWeight.w600,
                        color:
                            on ? AppColors.primary : AppColors.mutedForeground,
                        height: 16 / 11)),
              ]),
            ),
          ),
        );
    return Container(
      decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          for (final it in bar)
            cell(it.icon, l.navLabel(it.label), _active(it.to),
                () => _navigate(it.to)),
          cell(LucideIcons.menu, l.t('nav.More'), false,
              () => _key.currentState?.openDrawer()),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lg = context.isLg;
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(context.isMd ? 32 : 16, lg ? 40 : 24,
          context.isMd ? 32 : 16, lg ? 48 : 112),
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1152),
              child: widget.child)),
    );
    Widget topBar(bool desktop) => Container(
          padding: EdgeInsets.symmetric(
              horizontal: desktop ? 32 : 16, vertical: desktop ? 8 : 12),
          decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: .95),
              border:
                  const Border(bottom: BorderSide(color: AppColors.border))),
          child: SafeArea(
            bottom: false,
            child: Row(
                mainAxisAlignment: desktop
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!desktop) const Flexible(child: Logo()),
                  const _Tools(),
                  if (!desktop) ...[
                    const SizedBox(width: 8),
                    _SquareBtn(
                        icon: LucideIcons.menu,
                        onTap: () => _key.currentState?.openDrawer())
                  ],
                ]),
          ),
        );
    return Scaffold(
      key: _key,
      backgroundColor: AppColors.background,
      drawer: lg
          ? null
          : Drawer(
              width: 320,
              backgroundColor: AppColors.sidebar,
              shape: const RoundedRectangleBorder(),
              child: _sidebar(drawer: true)),
      bottomNavigationBar: lg ? null : _bottomBar(),
      body: lg
          ? Row(children: [
              SizedBox(width: 288, child: _sidebar(drawer: false)),
              Expanded(
                  child: Column(
                      children: [topBar(true), Expanded(child: content)])),
            ])
          : Column(children: [topBar(false), Expanded(child: content)]),
    );
  }
}
