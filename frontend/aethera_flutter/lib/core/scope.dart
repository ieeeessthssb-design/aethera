export 'backend.dart';
export 'demo_store.dart';
export 'i18n.dart';

import 'package:flutter/widgets.dart';

import 'auth.dart';
import 'demo_store.dart';
import 'i18n.dart';

/// App-wide state holders, reachable from any widget.
class AppState {
  AppState({required this.lang, required this.auth, required this.demo});
  final LangController lang;
  final AuthController auth;
  final DemoStore demo;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.state, required super.child});
  final AppState state;
  static AppState of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.state;
  @override
  bool updateShouldNotify(AppScope old) => false;
}

extension AppContext on BuildContext {
  /// Language controller; widgets that call this rebuild when the language changes.
  LangController get l => L.of(this);
  AuthController get auth => AppScope.of(this).auth;
  DemoStore get demo => AppScope.of(this).demo;
}
