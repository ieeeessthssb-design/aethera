import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../authentication/data/auth_providers.dart';
import '../../authentication/presentation/auth_screen.dart';
import 'admin_api_service.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  static const forest = Color(0xFF183F32);
  static const ink = Color(0xFF24352C);
  static const muted = Color(0xFF526158);
  static const cream = Color(0xFFF7F6EF);
  static const border = Color(0xFFE2E8DF);

  final AdminApiService _api = AdminApiService();
  Map<String, dynamic> _overview = const {};
  List<Map<String, dynamic>> _pendingExperts = const [];
  List<Map<String, dynamic>> _users = const [];
  bool _loading = true;
  String? _error;
  String? _busyUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await _api.overview();
      final experts = await _api.pendingExperts();
      final users = await _api.users();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _pendingExperts = experts;
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(error, AppLocalizations.of(context)!.adminLoadFailed);
        _loading = false;
      });
    }
  }

  String _messageFor(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    }
    return fallback;
  }

  Future<void> _decideExpert(
    Map<String, dynamic> expert, {
    required bool approve,
  }) async {
    final id = expert['id']?.toString();
    if (id == null) return;
    setState(() => _busyUserId = id);
    try {
      await _api.decideExpert(id, approve: approve);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFor(error, AppLocalizations.of(context)!.adminLoadFailed))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _setUserActive(
    Map<String, dynamic> user,
    bool active,
  ) async {
    final id = user['id']?.toString();
    if (id == null) return;
    setState(() => _busyUserId = id);
    try {
      await _api.setUserActive(id, active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.adminStatusUpdated)),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFor(error, AppLocalizations.of(context)!.adminLoadFailed))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutQuestion),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.adminLogout),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authApiServiceProvider).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: forest,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_rounded, color: forest, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.adminHeader,
                      style: const TextStyle(
                        color: forest,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.adminRetry,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded, color: forest),
                  ),
                  IconButton(
                    tooltip: l10n.adminLogout,
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: forest),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading) const LinearProgressIndicator(color: forest),
              if (_error != null) ...[
                _messageCard(_error!, l10n.adminRetry, _load),
              ] else if (!_loading) ...[
                _sectionTitle(l10n.adminOverview),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: wide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: wide ? 1.7 : 1.45,
                  children: [
                    _metric(l10n.adminTotalUsers, _overview['total_users']),
                    _metric(l10n.adminActiveUsers, _overview['active_users']),
                    _metric(l10n.adminFarmers, _overview['farmers']),
                    _metric(l10n.adminPendingExperts, _overview['pending_experts']),
                  ],
                ),
                const SizedBox(height: 26),
                _sectionTitle(l10n.adminApplications),
                const SizedBox(height: 10),
                if (_pendingExperts.isEmpty)
                  _messageCard(l10n.adminNoApplications, null, null)
                else
                  for (final expert in _pendingExperts)
                    _expertCard(expert, l10n),
                const SizedBox(height: 26),
                _sectionTitle(l10n.adminUsers),
                const SizedBox(height: 10),
                if (_users.isEmpty)
                  _messageCard(l10n.adminNoUsers, null, null)
                else
                  for (final user in _users) _userCard(user, l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) => Text(
        label,
        style: const TextStyle(
          color: forest,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      );

  Widget _metric(String label, dynamic value) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: muted, fontSize: 12)),
            Text(
              '${value ?? 0}',
              style: const TextStyle(
                color: ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  Widget _messageCard(String message, String? action, VoidCallback? onTap) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(message, style: const TextStyle(color: ink)),
            ),
            if (action != null && onTap != null)
              TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      );

  Widget _expertCard(Map<String, dynamic> expert, AppLocalizations l10n) {
    final id = expert['id']?.toString() ?? '';
    final busy = _busyUserId == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (expert['full_name'] ?? expert['name'] ?? '').toString(),
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            expert['email']?.toString() ?? '',
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => _decideExpert(expert, approve: false),
                icon: const Icon(Icons.close_rounded),
                label: Text(l10n.adminReject),
              ),
              FilledButton.icon(
                onPressed: busy ? null : () => _decideExpert(expert, approve: true),
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n.adminApprove),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, AppLocalizations l10n) {
    final id = user['id']?.toString() ?? '';
    final role = user['role']?.toString();
    final roleLabel = role == 'farmer'
        ? l10n.authFarmer
        : role == 'expert'
            ? l10n.authExpert
            : l10n.adminRoleAdmin;
    final active = user['is_active'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: ListTile(
        title: Text(
          (user['full_name'] ?? user['name'] ?? '').toString(),
          style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${user['email'] ?? ''} • $roleLabel • ${active ? l10n.adminUserActive : l10n.adminUserInactive}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
        trailing: Switch.adaptive(
          value: active,
          onChanged: _busyUserId == id ? null : (value) => _setUserActive(user, value),
          activeTrackColor: forest,
        ),
      ),
    );
  }
}
