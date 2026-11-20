import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/auth.dart';
import 'core/scope.dart';
import 'screens/admin.dart';
import 'screens/alerts.dart';
import 'screens/architecture.dart';
import 'screens/assist.dart';
import 'screens/auth.dart';
import 'screens/community.dart';
import 'screens/consult.dart';
import 'screens/dashboard.dart';
import 'screens/diagnose.dart';
import 'screens/expert.dart';
import 'screens/expert_cases.dart';
import 'screens/farm.dart';
import 'screens/guide.dart';
import 'screens/irrigation.dart';
import 'screens/knowledge.dart';
import 'screens/landing.dart';
import 'screens/not_found.dart';
import 'screens/onboarding.dart';
import 'screens/plan.dart';
import 'screens/pricing.dart';
import 'screens/profile.dart';
import 'screens/radar.dart';
import 'screens/report.dart';
import 'theme/text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Backend.init();
  final lang = LangController();
  final demo = DemoStore();
  final auth = AuthController();
  await Future.wait([lang.load(), demo.load()]);
  await auth.init();
  runApp(AethraApp(state: AppState(lang: lang, auth: auth, demo: demo)));
}

Widget _screenFor(String path) {
  final p = path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  switch (p) {
    case '/':
      return const LandingScreen();
    case '/auth':
      return const AuthScreen();
    case '/onboarding':
      return const OnboardingScreen();
    case '/pricing':
      return const PricingScreen();
    case '/architecture':
      return const ArchitectureScreen();
    case '/dashboard':
      return const DashboardScreen();
    case '/farm':
      return const FarmScreen();
    case '/guide':
      return const GuideScreen();
    case '/assist':
      return const AssistScreen();
    case '/diagnose':
      return const DiagnoseScreen();
    case '/irrigation':
      return const IrrigationScreen();
    case '/plan':
      return const PlanScreen();
    case '/radar':
      return const RadarScreen();
    case '/report':
      return const ReportScreen();
    case '/alerts':
      return const AlertsScreen();
    case '/knowledge':
      return const KnowledgeScreen();
    case '/community':
      return const CommunityScreen();
    case '/consult':
      return const ConsultScreen();
    case '/profile':
      return const ProfileScreen();
    case '/expert':
    case '/expert/review':
      return const ExpertCasesPage();
    case '/expert/risks':
      return const ExpertRisksScreen();
    case '/admin':
      return const AdminDashboardScreen();
  }
  final parts = p.split('/').where((s) => s.isNotEmpty).toList();
  if (parts.length == 2 &&
    parts[0] == 'expert' &&
    kExpertSections.contains(parts[1])) {
  return ExpertSectionScreen(section: parts[1]);
}

if (parts.length == 2 &&
    parts[0] == 'admin' &&
    kAdminTitles.containsKey(parts[1])) {
  return AdminSectionScreen(section: parts[1]);
}
  return const NotFoundScreen();
}

class _NoAnimRoute<T> extends PageRouteBuilder<T> {
  _NoAnimRoute(RouteSettings s, Widget child)
      : super(
            settings: s,
            pageBuilder: (_, __, ___) => child,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero);
}

class AethraApp extends StatelessWidget {
  const AethraApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: L(
        controller: state.lang,
        child: Builder(builder: (context) {
          final l = context.l;
          return MaterialApp(
            title: 'Aethera',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(arabic: l.isAr),
            locale: l.locale,
            supportedLocales: const [Locale('ar'), Locale('fr')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            builder: (context, child) =>
                Directionality(textDirection: l.dir, child: child!),
            initialRoute: '/',
            onGenerateRoute: (s) => _NoAnimRoute(s, _screenFor(s.name ?? '/')),
            onUnknownRoute: (s) => _NoAnimRoute(s, const NotFoundScreen()),
          );
        }),
      ),
    );
  }
}
