/// Backend configuration. The values are the *public* (publishable) Supabase
/// credentials of the web app, so the mobile app talks to the same backend.
/// Override at build time with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://vxhracbhqaflhqjcovzi.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_WESi6f6vAThToS32NGf0Dw_KcVRPeb-');
  static const String oauthRedirect = 'io.aethera.app://login-callback/';
  static bool get hasBackend =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.length > 10;
}
