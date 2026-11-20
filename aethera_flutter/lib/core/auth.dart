import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend.dart';

/// Equivalent of the useAuth() hook: current user, roles, readiness.
class AuthController extends ChangeNotifier {
  User? user;
  List<String> roles = [];
  bool ready = false;
  StreamSubscription<AuthState>? _sub;

  bool get isExpert => roles.contains('expert') || roles.contains('admin');

  Future<void> init() async {
    final c = Backend.client;
    if (c == null) {
      ready = true;
      notifyListeners();
      return;
    }
    await _load(c.auth.currentUser);
    _sub = c.auth.onAuthStateChange.listen((s) {
      if (s.event == AuthChangeEvent.signedIn ||
          s.event == AuthChangeEvent.signedOut ||
          s.event == AuthChangeEvent.userUpdated) {
        _load(s.session?.user);
      }
    });
  }

  Future<void> _load(User? u) async {
    user = u;
    final c = Backend.client;
    if (u != null && c != null) {
      try {
        final data =
            await c.from('user_roles').select('role').eq('user_id', u.id);
        roles = data.map((r) => r['role'].toString()).toList();
      } catch (_) {
        roles = [];
      }
    } else {
      roles = [];
    }
    ready = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await Backend.client?.auth.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
