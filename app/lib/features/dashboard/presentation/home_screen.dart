
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String _heroImage = 'assets/images/backgrounds/tunisian_farm_landscape.png';
  static const String _cropImage = 'assets/images/crop_field.jpg';
  static const String _greenhouseImage = 'assets/images/greenhouse.jpg';
  static const String _irrigationImage = 'assets/images/irrigation.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final strings = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.forestGreen,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AETHERA',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                        ),
                        Text(
                          strings.dashboardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: strings.preferences,
                      onPressed: () => _showPreferences(
                        context,
                        ref,
                        settings,
                      ),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                    const SizedBox(width: 5),
                    CircleAvatar(
                      backgroundColor: AppTheme.mintGreen,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Agricultural photographic hero
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 265,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _heroImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.forestGreen,
                            child: const Icon(
                              Icons.landscape_rounded,
                              color: Colors.white54,
                              size: 70,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.12),
                                Colors.black.withValues(alpha: 0.72),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white38,
                                  ),
                                ),
                                child: Text(
                                  strings.appName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                strings.greeting,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                strings.welcomeTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  height: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.welcomeSubtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Section heading
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.dashboardTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(
                      Icons.spa_rounded,
                      color: AppTheme.forestGreen,
                    ),
                  ],
                ),
              ),
            ),

            // Feature cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _featureCard(
                    context,
                    title: strings.assistant,
                    image: _cropImage,
                    icon: Icons.smart_toy_rounded,
                    description: strings.dashboardSubtitle,
                  ),
                  _featureCard(
                    context,
                    title: strings.diagnosis,
                    image: _greenhouseImage,
                    icon: Icons.eco_rounded,
                    description: strings.dashboardSubtitle,
                  ),
                  _featureCard(
                    context,
                    title: strings.irrigation,
                    image: _irrigationImage,
                    icon: Icons.water_drop_rounded,
                    description: strings.dashboardSubtitle,
                  ),
                  _featureCard(
                    context,
                    title: strings.weather,
                    image: _heroImage,
                    icon: Icons.cloud_rounded,
                    description: strings.dashboardSubtitle,
                  ),
                ]),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 0.92,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 12),
                child: Text(
                  strings.preferences,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 35),
                child: Card(
                  elevation: 0,
                  color: isDark
                      ? const Color(0xFF173629)
                      : const Color(0xFFEAF4EC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _settingsRow(
                          context,
                          icon: Icons.language_rounded,
                          label: strings.chooseLanguage,
                          child: DropdownButton<String>(
                            value: settings.locale.languageCode,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('English'),
                              ),
                              DropdownMenuItem(
                                value: 'fr',
                                child: Text('Français'),
                              ),
                              DropdownMenuItem(
                                value: 'ar',
                                child: Text('العربية'),
                              ),
                            ],
                            onChanged: (language) {
                              if (language != null) {
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .setLanguage(language);
                              }
                            },
                          ),
                        ),
                        const Divider(height: 24),
                        _settingsRow(
                          context,
                          icon: Icons.palette_outlined,
                          label: strings.chooseTheme,
                          child: DropdownButton<ThemeMode>(
                            value: settings.themeMode,
                            underline: const SizedBox(),
                            items: [
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text(strings.light),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text(strings.dark),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text(strings.system),
                              ),
                            ],
                            onChanged: (theme) {
                              if (theme != null) {
                                ref
                                    .read(appSettingsProvider.notifier)
                                    .setTheme(theme);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required String title,
    required String image,
    required IconData icon,
    required String description,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.mintGreen,
              child: Icon(
                icon,
                size: 45,
                color: AppTheme.forestGreen,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.forestGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        child,
      ],
    );
  }

  void _showPreferences(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.preferences,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.chooseLanguage),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.chooseTheme),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}