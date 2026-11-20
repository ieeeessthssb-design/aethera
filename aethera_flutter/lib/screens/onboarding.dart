import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';

enum _T { text, choice, multi }

class _Step {
  const _Step(this.k, this.q, this.type, {this.opts = const [], this.ph});
  final String k, q;
  final _T type;
  final List<String> opts;
  final String? ph;
}

const _steps = [
  _Step('name', "What's your name?", _T.text, ph: 'e.g. Amine Ben Salem'),
  _Step('exp', 'How much farming experience do you have?', _T.choice,
      opts: ['Beginner', 'Intermediate', 'Experienced']),
  _Step('loc', 'Where is your farm?', _T.choice,
      opts: ['Sousse', 'Sfax', 'Kairouan', 'Nabeul', 'Sidi Bouzid', 'Béja']),
  _Step('size', 'How big is your farm?', _T.choice,
      opts: ['< 1 ha', '1–3 ha', '3–10 ha', '> 10 ha']),
  _Step('crops', 'What are your main crops?', _T.multi, opts: [
    'Tomato',
    'Pepper / Chili',
    'Onion',
    'Potato',
    'Olive',
    'Wheat',
    'Watermelon'
  ]),
  _Step('irr', 'How do you irrigate?', _T.choice, opts: [
    'Drip irrigation',
    'Sprinkler',
    'Surface / furrow',
    'Rain-fed only'
  ]),
  _Step('water', 'How available is water?', _T.choice,
      opts: ['Abundant', 'Moderate', 'Limited', 'Very scarce']),
  _Step('soil', 'Do you know your soil type?', _T.choice,
      opts: ['Sandy', 'Loamy', 'Clay', 'Sandy-loam', "I don't know"]),
  _Step('goal', 'What matters most to you?', _T.multi, opts: [
    'Higher profit',
    'Save water',
    'Easier management',
    'Reduce disease losses',
    'Sell locally'
  ]),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _i = 0;
  final Map<String, Object> _a = {'name': 'Amine Ben Salem'};
  final _name = TextEditingController(text: 'Amine Ben Salem');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<String> _list(String k) => (_a[k] as List<String>?) ?? const [];
  String _str(String k) => (_a[k] as String?) ?? '';

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final done = _i >= _steps.length;
    final s = done ? null : _steps[_i];
    final pct = (_i.clamp(0, _steps.length)) / _steps.length;
    bool can() {
      if (s == null) return true;
      return s.type == _T.multi ? _list(s.k).isNotEmpty : _str(s.k).isNotEmpty;
    }

    Widget card;
    if (!done) {
      final st = s!;
      Widget input;
      if (st.type == _T.text) {
        input = AppTextField(
            controller: _name,
            hint: st.ph,
            height: 56,
            fontSize: 18,
            autofocus: true,
            onChanged: (v) => setState(() => _a[st.k] = v));
      } else {
        input =
            ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 12, children: [
          for (final o in st.opts)
            Builder(builder: (context) {
              final sel = st.type == _T.multi
                  ? _list(st.k).contains(o)
                  : _str(st.k) == o;
              return Tappable(
                radius: 12,
                color: sel ? AppColors.secondary : AppColors.background,
                onTap: () => setState(() {
                  if (st.type == _T.multi) {
                    final cur = List<String>.from(_list(st.k));
                    sel ? cur.remove(o) : cur.add(o);
                    _a[st.k] = cur;
                  } else {
                    _a[st.k] = o;
                  }
                }),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.border,
                          width: 2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(
                        child:
                            Text(o, style: body(size: 18, w: FontWeight.w600))),
                    if (sel)
                      const Icon(LucideIcons.checkCircle2,
                          size: 20, color: AppColors.primary)
                  ]),
                ),
              );
            }),
        ]);
      }
      card = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(st.q, style: display(size: md ? 30 : 24)),
        const SizedBox(height: 24),
        input,
        if (st.k == 'exp')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text.rich(TextSpan(
                style: body(size: 14, color: AppColors.mutedForeground),
                children: [
                  const TextSpan(text: 'Beginners get step-by-step '),
                  TextSpan(
                      text: 'Guide Me',
                      style: body(
                          size: 14,
                          w: FontWeight.w700,
                          color: AppColors.mutedForeground)),
                  const TextSpan(text: '. Experienced farmers go straight to '),
                  TextSpan(
                      text: 'Quick Assist',
                      style: body(
                          size: 14,
                          w: FontWeight.w700,
                          color: AppColors.mutedForeground)),
                  const TextSpan(text: '. You can switch anytime.'),
                ])),
          ),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          AppButton(
              variant: BtnVariant.ghost,
              icon: LucideIcons.arrowLeft,
              label: 'Back',
              onPressed: _i == 0 ? null : () => setState(() => _i = _i - 1)),
          AppButton(
              label: _i == _steps.length - 1 ? 'Finish' : 'Continue',
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              onPressed: can() ? () => setState(() => _i++) : null),
        ]),
      ]);
    } else {
      final crops = _list('crops');
      card = Column(children: [
        const Icon(LucideIcons.checkCircle2,
            size: 64, color: AppColors.primary),
        const SizedBox(height: 16),
        Text('Your Aethera farm profile is ready.',
            textAlign: TextAlign.center, style: display(size: 30)),
        const SizedBox(height: 8),
        Text(
            'Welcome, ${_str('name').isEmpty ? 'farmer' : _str('name')}. Your guidance will now be adapted to ${_str('loc').isEmpty ? 'your region' : _str('loc')}, ${crops.isEmpty ? 'your crops' : crops.join(', ')} and ${_str('water').isEmpty ? 'your' : _str('water').toLowerCase()} water.',
            textAlign: TextAlign.center,
            style: body(color: AppColors.mutedForeground)),
        const SizedBox(height: 24),
        Tinted(
          radius: 16,
          padding: const EdgeInsets.all(16),
          child:
              ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 8, children: [
            for (final st in _steps.skip(1))
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: '${st.q.replaceAll('?', '')}: ',
                    style: body(size: 14, color: AppColors.mutedForeground)),
                TextSpan(
                    text: st.type == _T.multi
                        ? _list(st.k).join(', ')
                        : _str(st.k),
                    style: body(size: 14, w: FontWeight.w700))
              ])),
          ]),
        ),
        const SizedBox(height: 32),
        AppButton(
            label: 'Open my dashboard',
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            onPressed: () => Navigator.of(context).pushReplacementNamed(
                _str('exp') == 'Beginner' ? '/guide' : '/dashboard')),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FieldPattern(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 672),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Logo(),
                            Text(
                                done
                                    ? 'Done'
                                    : 'Step ${_i + 1} of ${_steps.length}',
                                style: body(
                                    size: 14, color: AppColors.mutedForeground))
                          ]),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 10,
                          color: AppColors.muted,
                          alignment: AlignmentDirectional.centerStart,
                          child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 250),
                              widthFactor: pct.toDouble(),
                              child: Container(
                                  decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(999)))),
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppCard(
                          padding: EdgeInsets.all(md ? 40 : 24), child: card),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
