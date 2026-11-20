// Shared voice UI used by BOTH "Aide rapide" (assist.dart) and
// "Diagnostic" (diagnose.dart). It does not ask any AI: it only fills the
// screen's existing question field and triggers the screen's existing action.
import 'package:flutter/material.dart';

import '../core/scope.dart';
import '../core/voice_service.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import 'ab.dart';

enum VoicePhase { idle, listening, review }

/// Owns the speech recogniser / reader for one screen.
/// [text] is the screen's existing question controller.
class VoiceController extends ChangeNotifier {
  VoiceController(this.text);

  final TextEditingController text;
  final VoiceService _svc = VoiceService();

  VoicePhase phase = VoicePhase.idle;
  VoiceError? error;
  bool speaking = false;

  /// true when the current question text was dictated (not typed).
  /// Sent with the case so the expert knows how it was given.
  bool spoken = false;
  bool _disposed = false;
  int _session = 0;

  /// The field is read-only while recording or reviewing a transcript:
  /// the only way to change a spoken question is "Répéter".
  bool get locked => phase != VoicePhase.idle;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start(String lang) async {
    await stopSpeaking();
    final session = ++_session;
    error = null;
    spoken = false;
    text.clear();
    phase = VoicePhase.listening;
    _emit();
    try {
      await _svc.startListening(
        lang: lang,
        onText: (t) {
          if (session != _session || _disposed) return;
          text.value = TextEditingValue(
              text: t, selection: TextSelection.collapsed(offset: t.length));
        },
        onEnded: () {
          if (session == _session) _finish();
        },
        onError: (e) {
          if (session != _session) return;
          error = e;
          phase = VoicePhase.idle;
          _emit();
        },
      );
    } on VoiceException catch (e) {
      if (session != _session) return;
      error = e.error;
      phase = VoicePhase.idle;
      _emit();
    } catch (_) {
      if (session != _session) return;
      error = VoiceError.generic;
      phase = VoicePhase.idle;
      _emit();
    }
  }

  /// Farmer taps "terminer" (or the device detects the end of speech).
  Future<void> stop() => _finish();

  Future<void> _finish() async {
    if (phase != VoicePhase.listening) return;
    final session = _session;
    final heard = await _svc.stopListening();
    if (session != _session || _disposed) return;
    final t = heard.trim().isNotEmpty ? heard.trim() : text.text.trim();
    if (t.isEmpty) {
      text.clear();
      error = VoiceError.notUnderstood;
      phase = VoicePhase.idle;
    } else {
      text.text = t;
      spoken = true;
      phase = VoicePhase.review;
    }
    _emit();
  }

  /// "Répéter": throw the transcript away and speak again.
  Future<void> repeat(String lang) async {
    ++_session;
    await _svc.cancelListening();
    await start(lang);
  }

  /// The farmer switched language (Tunisian <-> French): stop everything and
  /// clear the question so he can speak again in the new language.
  Future<void> languageChanged() async {
    ++_session;
    await _svc.cancelListening();
    await _svc.stopSpeaking();
    text.clear();
    spoken = false;
    phase = VoicePhase.idle;
    error = null;
    speaking = false;
    _emit();
  }

  /// The farmer typed in the field: the text is no longer a dictation.
  void markTyped() => spoken = false;

  /// Call after the question was sent through the screen's existing flow.
  void reset() {
    ++_session;
    phase = VoicePhase.idle;
    error = null;
    _emit();
  }

  Future<void> toggleSpeak(String answer, String lang) async {
    if (speaking) {
      await stopSpeaking();
      return;
    }
    speaking = true;
    _emit();
    try {
      await _svc.speak(answer, lang);
    } catch (_) {}
    if (!_disposed) {
      speaking = false;
      _emit();
    }
  }

  Future<void> stopSpeaking() async {
    if (!speaking) return;
    await _svc.stopSpeaking();
    speaking = false;
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    _svc.dispose();
    super.dispose();
  }
}

String voiceLang(BuildContext context) => context.l.isAr ? 'ar' : 'fr';

/// The buttons that replace the old "Question vocale" + "Demander" pair.
/// Meant to be spread into the screen's existing button `Wrap`.
List<Widget> voiceButtons(
  BuildContext context,
  VoiceController c, {
  required VoidCallback onSend,
  required bool busy,
  String? sendLabel,
  bool canSend = true,
}) {
  final l = context.l;
  final lang = voiceLang(context);
  final hasText = c.text.text.trim().isNotEmpty;
  final sendText = sendLabel ?? l.t('voiceSend');

  Widget send() => AppButton(
        variant: BtnVariant.accent,
        icon: LucideIcons.zap,
        label: sendText,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        loading: busy,
        onPressed: (!hasText || busy || !canSend) ? null : onSend,
      );

  switch (c.phase) {
    case VoicePhase.listening:
      return [
        AppButton(
          variant: BtnVariant.accent,
          icon: Icons.stop_rounded,
          label: l.t('voiceStop'),
          onPressed: c.stop,
        ),
      ];
    case VoicePhase.review:
      return [
        AppButton(
          variant: BtnVariant.outline,
          icon: LucideIcons.refreshCw,
          label: l.t('voiceRepeat'),
          onPressed: busy ? null : () => c.repeat(lang),
        ),
        send(),
      ];
    case VoicePhase.idle:
      if (!hasText) {
        return [
          AppButton(
            variant: BtnVariant.primary,
            icon: LucideIcons.mic,
            label: l.t('voiceQuestion'),
            onPressed: busy ? null : () => c.start(lang),
          ),
        ];
      }
      return [
        AppButton(
          variant: BtnVariant.outline,
          icon: LucideIcons.mic,
          label: l.t('voiceQuestion'),
          onPressed: busy ? null : () => c.start(lang),
        ),
        send(),
      ];
  }
}

/// Recording indicator, language hint and error line. Put it under the field.
class VoiceStatus extends StatelessWidget {
  const VoiceStatus({super.key, required this.controller});
  final VoiceController controller;

  String _errKey(VoiceError e) => switch (e) {
        VoiceError.speechUnavailable => 'voiceErrUnavailable',
        VoiceError.micDenied => 'voiceErrMic',
        VoiceError.notUnderstood => 'voiceErrHeard',
        VoiceError.network => 'voiceErrNetwork',
        VoiceError.generic => 'voiceErrGeneric',
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final err = controller.error;
        if (controller.phase == VoicePhase.listening) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Tinted(
              color: AppColors.dangerSoft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const _PulseDot(),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        '${l.t('voiceListening')} (${l.isAr ? 'تونسي' : 'Français'})',
                        style: body(size: 14, w: FontWeight.w600))),
              ]),
            ),
          );
        }
        if (controller.phase == VoicePhase.review) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.t('voiceReview'),
                style: body(size: 13, color: AppColors.mutedForeground)),
          );
        }
        if (err != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Tinted(
              color: AppColors.warningSoft,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(LucideIcons.alertTriangle,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(l.t(_errKey(err)), style: body(size: 14))),
              ]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: .35, end: 1.0).animate(_a),
        child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
                color: AppColors.destructive, shape: BoxShape.circle)),
      );
}

/// "اسمع" / "Écouter": reads [text] (the answer actually displayed).
class ListenButton extends StatelessWidget {
  const ListenButton({
    super.key,
    required this.controller,
    required this.text,
    required this.lang,
  });
  final VoiceController controller;
  final String text;

  /// Language of [text]: 'ar', 'fr' or 'en'.
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => AppButton(
        variant: BtnVariant.soft,
        icon: controller.speaking
            ? Icons.stop_circle_outlined
            : Icons.volume_up_rounded,
        label: controller.speaking ? l.t('listenStop') : l.t('listen'),
        onPressed: () => controller.toggleSpeak(text, lang),
      ),
    );
  }
}
