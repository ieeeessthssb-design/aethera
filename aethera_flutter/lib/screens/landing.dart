import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../core/i18n.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final lg = context.isLg;
    final padX = md ? 32.0 : 16.0;
    Widget wrap(Widget child, {double max = 1152}) => Padding(
        padding: EdgeInsets.symmetric(horizontal: padX),
        child: Center(
            child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: max), child: child)));

    final header = Container(
      decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: .95),
          border: const Border(bottom: BorderSide(color: AppColors.border))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padX, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Logo(),
                    if (md)
                      Row(children: [
                        _NavLink(
                            'How it works',
                            () => Scrollable.ensureVisible(
                                _howKey.currentContext!,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut)),
                        _NavLink(
                            'Knowledge Hub', () => go(context, '/knowledge')),
                        _NavLink('Pricing', () => go(context, '/pricing')),
                        _NavLink(
                            'Architecture', () => go(context, '/architecture')),
                        _NavLink('For experts', () => go(context, '/expert')),
                      ]),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const LangSwitch(),
                      const SizedBox(width: 8),
                      AppButton.link(context, '/onboarding', 'Get Started',
                          padding: EdgeInsets.symmetric(
                              horizontal: md ? 20 : 12, vertical: 10)),
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );

    final heroText =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.mapPin,
              size: 16, color: AppColors.secondaryForeground),
          const SizedBox(width: 8),
          Text('Built for Tunisian farmers',
              style: body(
                  size: 14,
                  w: FontWeight.w600,
                  color: AppColors.secondaryForeground)),
        ]),
      ),
      const SizedBox(height: 20),
      Text.rich(
        TextSpan(
            style: display(
                size: lg ? 60 : (md ? 52 : 36),
                w: FontWeight.w800,
                height: 1.05),
            children: [
              const TextSpan(text: 'Turn agricultural knowledge into the '),
              TextSpan(
                  text: 'right decision',
                  style: display(
                      size: lg ? 60 : (md ? 52 : 36),
                      w: FontWeight.w800,
                      height: 1.05,
                      color: AppColors.primary)),
              const TextSpan(text: ' for your farm.'),
            ]),
      ),
      const SizedBox(height: 20),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 576),
        child: Text(
            "AI-powered agricultural guidance grounded in verified expert knowledge, local experience and your farm's real conditions.",
            style: body(size: 18, color: AppColors.mutedForeground)),
      ),
      const SizedBox(height: 32),
      Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton.link(context, '/onboarding', 'Get Started',
                variant: BtnVariant.accent,
                trailingIcon: LucideIcons.arrowRight,
                fontSize: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 10)),
            AppButton(
              label: 'See How It Works',
              variant: BtnVariant.outline,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              onPressed: () => Scrollable.ensureVisible(_howKey.currentContext!,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut),
            ),
            TextLink('Open the live demo →', path: '/dashboard'),
          ]),
    ]);

    final heroImage = Stack(clipBehavior: Clip.none, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24), boxShadow: kShadowSoft),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.asset('assets/images/hero-farm.jpg',
                    fit: BoxFit.cover,
                    semanticLabel:
                        'Tomato farm with drip irrigation near Sousse')),
          ),
        ),
      ),
      PositionedDirectional(
        bottom: 0,
        start: md ? null : 16,
        end: md ? 24 : 16,
        width: md ? 320 : null,
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('TODAY · SOUSSE',
                  style: body(
                      size: 12,
                      w: FontWeight.w600,
                      color: AppColors.mutedForeground)),
              const TrustLabel(Trust.expert),
            ]),
            const SizedBox(height: 8),
            Text('Irrigate 18 mm before 9:00', style: body(w: FontWeight.w600)),
            Text(
                'High heat (36°C) + soil moisture at 22%. Based on validated drip guidance for tomato.',
                style: body(size: 14, color: AppColors.mutedForeground)),
          ]),
        ),
      ),
    ]);

    final hero = wrap(
      Padding(
        padding: EdgeInsets.symmetric(vertical: lg ? 80 : 48),
        child: lg
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: heroText),
                const SizedBox(width: 40),
                Expanded(child: heroImage)
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [heroText, const SizedBox(height: 40), heroImage]),
      ),
      max: 1280,
    );

    // Ecosystem
    Widget node(IconData i, String t, String d, {bool hl = false}) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: hl ? AppColors.forest : AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Icon(i, size: 40, color: hl ? AppColors.accent : AppColors.primary),
            const SizedBox(height: 12),
            Text(t,
                textAlign: TextAlign.center,
                style: display(
                    size: 20,
                    color: hl
                        ? AppColors.forestForeground
                        : AppColors.foreground)),
            const SizedBox(height: 4),
            Text(d,
                textAlign: TextAlign.center,
                style: body(
                    size: 14,
                    color: hl
                        ? AppColors.forestForeground.withValues(alpha: .8)
                        : AppColors.mutedForeground)),
          ]),
        );
    Widget arrowX() => Padding(
        padding: const EdgeInsets.all(8),
        child: Transform.rotate(
            angle: md ? 0 : 1.5708,
            child: const Icon(LucideIcons.arrowLeftRight,
                size: 28, color: AppColors.earth)));
    final eco = [
      node(LucideIcons.tractor, 'Farmer',
          'Experience, questions, photos, farm data'),
      node(LucideIcons.sparkles, 'Aethera AI',
          'Retrieves verified knowledge, applies farm context',
          hl: true),
      node(LucideIcons.stethoscope, 'Agricultural Experts',
          'Validate knowledge, review hard cases'),
    ];
    Widget pillW(String t, {bool on = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: on ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(999)),
        child: Text(t,
            style: body(
                w: FontWeight.w600,
                color:
                    on ? AppColors.primaryForeground : AppColors.foreground)));
    final formula = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.muted, borderRadius: BorderRadius.circular(16)),
      child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            pillW('Expert Knowledge'),
            Text('+', style: body(w: FontWeight.w600)),
            pillW('Local Knowledge'),
            Text('+', style: body(w: FontWeight.w600)),
            pillW('Farm Data'),
            const Icon(LucideIcons.arrowRight, size: 20),
            pillW('Actionable Recommendation', on: true),
          ]),
    );
    final ecosystem = Container(
      decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: wrap(
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('THE ECOSYSTEM',
              textAlign: TextAlign.center,
              style: body(
                  size: 14,
                  w: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.7)),
          const SizedBox(height: 8),
          Text('From scattered knowledge to the right decision.',
              textAlign: TextAlign.center, style: display(size: md ? 36 : 30)),
          const SizedBox(height: 40),
          if (md)
            IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Expanded(child: eco[0]),
                  arrowX(),
                  Expanded(child: eco[1]),
                  arrowX(),
                  Expanded(child: eco[2])
                ]))
          else
            Column(children: [eco[0], arrowX(), eco[1], arrowX(), eco[2]]),
          const SizedBox(height: 32),
          formula,
        ]),
        max: 1152,
      ),
    );

    // Problem / solution
    final problem = AppCard(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('THE PROBLEM',
            style: body(
                size: 14,
                w: FontWeight.w600,
                color: AppColors.destructive,
                letterSpacing: 0.7)),
        const SizedBox(height: 8),
        Text("Knowledge exists. It's just scattered.",
            style: display(size: 24)),
        const SizedBox(height: 12),
        Text(
            'Advice comes from neighbours, WhatsApp groups, Facebook pages, extension leaflets and apps — often contradictory, rarely specific to your soil, water or season. Farmers are left to decide which source to trust.',
            style: body(color: AppColors.mutedForeground)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (i, t) in [
            (LucideIcons.users, 'Other farmers'),
            (LucideIcons.smartphone, 'Social media'),
            (LucideIcons.fileText, 'Documents'),
            (LucideIcons.stethoscope, 'Experts'),
            (LucideIcons.globe, 'Digital tools')
          ])
            DashedBox(
                radius: 999,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(i, size: 16, color: AppColors.earth),
                  const SizedBox(width: 6),
                  Text(t, style: body(size: 14))
                ])),
        ]),
      ]),
    );
    final solution = AppCard(
      padding: const EdgeInsets.all(28),
      color: AppColors.secondary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('THE SOLUTION',
            style: body(
                size: 14,
                w: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 0.7)),
        const SizedBox(height: 8),
        Text('One trusted bridge between all of them.',
            style: display(size: 24)),
        const SizedBox(height: 12),
        Text(
            "Aethera connects farmers, AI and experts. Every answer is built from expert-verified knowledge, adapted to your farm, shows its confidence — and escalates to a human expert when the AI isn't sure.",
            style: body(
                color: AppColors.secondaryForeground.withValues(alpha: .8))),
        const SizedBox(height: 20),
        for (final t in [
          'Answers cite their sources',
          'Confidence shown on every recommendation',
          'Low confidence → expert review',
          "Experts' answers improve the knowledge base"
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.shieldCheck,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: body(w: FontWeight.w500)))
            ]),
          ),
      ]),
    );
    final ps = wrap(
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: ResponsiveGrid(
                cols: md ? 2 : 1, gap: 24, children: [problem, solution])),
        max: 1152);

    // How it works
    final steps = [
      (
        LucideIcons.tractor,
        'Tell us about your farm',
        'Location, crops, irrigation, water, soil.'
      ),
      (
        LucideIcons.camera,
        'Ask or upload a photo',
        'Type, speak, or photograph the problem.'
      ),
      (
        LucideIcons.database,
        'AI analyzes with trusted knowledge',
        'Verified sources + your farm context.'
      ),
      (
        LucideIcons.clipboardCheck,
        'Get an action plan',
        'Or an expert review when confidence is low.'
      ),
    ];
    final how = Container(
      key: _howKey,
      color: AppColors.forest,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: wrap(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How it works',
              style: display(
                  size: md ? 36 : 30, color: AppColors.forestForeground)),
          const SizedBox(height: 40),
          ResponsiveGrid(cols: md ? 4 : 1, gap: 20, children: [
            for (var i = 0; i < steps.length; i++)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: AppColors.sidebarAccent,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(steps[i].$1,
                                size: 32, color: AppColors.accent),
                            Text('0${i + 1}',
                                style: display(
                                    size: 36,
                                    w: FontWeight.w800,
                                    color: AppColors.forestForeground
                                        .withValues(alpha: .3))),
                          ]),
                      const SizedBox(height: 16),
                      Text(steps[i].$2,
                          style: display(
                              size: 18, color: AppColors.forestForeground)),
                      const SizedBox(height: 4),
                      Text(steps[i].$3,
                          style: body(
                              size: 14,
                              color: AppColors.forestForeground
                                  .withValues(alpha: .8))),
                    ]),
              ),
          ]),
        ]),
        max: 1152,
      ),
    );

    // For every farmer
    Widget persona(IconData i, Color c, String t, String d, List<String> j) =>
        AppCard(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i, size: 36, color: c),
            const SizedBox(height: 12),
            Text(t, style: display(size: 20)),
            const SizedBox(height: 4),
            Text(d, style: body(color: AppColors.mutedForeground)),
            const SizedBox(height: 16),
            Journey(steps: j),
          ]),
        );
    final every = wrap(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DIFFERENT FARMERS NEED DIFFERENT EXPERIENCES',
              style: body(
                  size: 14,
                  w: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.7)),
          const SizedBox(height: 8),
          Text('For every farmer.', style: display(size: md ? 36 : 30)),
          const SizedBox(height: 32),
          ResponsiveGrid(cols: md ? 3 : 1, gap: 20, children: [
            persona(
                LucideIcons.sprout,
                AppColors.primary,
                'New to farming?',
                'Get guided step-by-step support.',
                ['Guide Me', 'Learn', 'Plan', 'Act']),
            persona(
                LucideIcons.zap,
                AppColors.accent,
                'Experienced farmer?',
                'Get fast answers without unnecessary tutorials.',
                ['Ask', 'Diagnose', 'Act']),
            persona(
                LucideIcons.stethoscope,
                AppColors.earth,
                'Difficult problem?',
                'The AI knows its limits and brings in an expert.',
                ['Ask', 'AI', 'Expert', 'Decision']),
          ]),
        ]),
      ),
      max: 1152,
    );

    // Expert + offline
    final expertOffline = wrap(
      Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: ResponsiveGrid(cols: md ? 2 : 1, gap: 20, children: [
          AppCard(
            padding: const EdgeInsets.all(28),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.bookOpenCheck,
                  size: 36, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('An expert network behind every answer',
                  style: display(size: 24)),
              const SizedBox(height: 8),
              Text(
                  'Agronomists, plant pathologists and irrigation specialists validate the knowledge base and review complex cases. Each validated answer becomes trusted knowledge for the next farmer.',
                  style: body(color: AppColors.mutedForeground)),
              const SizedBox(height: 16),
              const Wrap(spacing: 8, runSpacing: 8, children: [
                TrustLabel(Trust.expert),
                TrustLabel(Trust.community),
                TrustLabel(Trust.unverified)
              ]),
            ]),
          ),
          AppCard(
            padding: const EdgeInsets.all(28),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(LucideIcons.wifiOff, size: 36, color: AppColors.earth),
              const SizedBox(height: 12),
              Text('Designed for low connectivity', style: display(size: 24)),
              const SizedBox(height: 8),
              Text(
                  'Farm profile, crop plans and saved guidance stay available offline. Questions and photos queue up and sync automatically when a signal returns.',
                  style: body(color: AppColors.mutedForeground)),
            ]),
          ),
        ]),
      ),
      max: 1152,
    );

    final cta = Padding(
      padding: EdgeInsets.fromLTRB(padX, 0, padX, 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1152),
          child: Container(
            padding: EdgeInsets.all(md ? 64 : 40),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Text('Your farm. Your context. Better decisions.',
                  textAlign: TextAlign.center,
                  style: display(
                      size: md ? 48 : 30,
                      w: FontWeight.w800,
                      color: AppColors.primaryForeground,
                      height: 1.1)),
              const SizedBox(height: 32),
              Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton.link(
                        context, '/onboarding', 'Create my farm profile',
                        variant: BtnVariant.accent,
                        fontSize: 16,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 10)),
                    Tappable(
                      radius: 12,
                      onTap: () => go(context, '/pricing'),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primaryForeground
                                    .withValues(alpha: .3)),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('View pricing',
                            style: body(
                                w: FontWeight.w600,
                                color: AppColors.primaryForeground)),
                      ),
                    ),
                  ]),
            ]),
          ),
        ),
      ),
    );

    final footer = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Text(
          '© 2026 Aethera · Prototype for demonstration — all data simulated.',
          textAlign: TextAlign.center,
          style: body(size: 14, color: AppColors.mutedForeground)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        header,
        Expanded(
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              hero,
              ecosystem,
              ps,
              how,
              every,
              expertOffline,
              cta,
              footer
            ]))),
      ]),
    );
  }
}

final GlobalKey _howKey = GlobalKey();

class _NavLink extends StatelessWidget {
  const _NavLink(this.text, this.onTap);
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
          onTap: onTap,
          child: Text(text, style: body(size: 14, w: FontWeight.w600))));
}
