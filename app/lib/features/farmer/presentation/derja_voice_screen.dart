
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DerjaVoiceScreen extends ConsumerStatefulWidget {
  const DerjaVoiceScreen({super.key});

  @override
  ConsumerState<DerjaVoiceScreen> createState() => _DerjaVoiceScreenState();
}

class _DerjaVoiceScreenState extends ConsumerState<DerjaVoiceScreen> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _questionController =
      TextEditingController();

  bool _available = false;
  bool _listening = false;
  bool _speaking = false;
  bool _busy = false;
  bool _captureRequested = false;

  String _localeId = 'en-US';
  String _transcript = '';
  String _answer = '';
  String? _lastLocale;
  double _soundLevel = 0;
  late final AnimationController _visualController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_lastLocale != null && _lastLocale != language) {
      if (_transcript.isNotEmpty) _answer = _getAgriculturalAnswer(_transcript);
      if (_speaking || _listening || _captureRequested) {
        _speech.stop();
        _tts.stop();
        _speaking = false;
        _listening = false;
        _captureRequested = false;
      }
    }
    _lastLocale = language;
  }

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    // Register TTS callbacks before any platform calls. Some browser engines can
    // emit start/completion events immediately after speak() is requested.
    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((message) {
      if (mounted) setState(() => _speaking = false);
    });

    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          // Do not clear _captureRequested here: Web Speech can report "done"
          // just before the pointer's long-press-end callback is delivered.
          setState(() => _listening = _speech.isListening);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _captureRequested = false;
          });
        },
      );
    } catch (_) {
      _available = false;
    }
    // TTS setup is independent of microphone availability. A platform that
    // rejects a volume/pitch setting must not disable speech recognition.
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (_captureRequested || _listening || _busy) return;

    try {
      await _tts.stop();
    } catch (_) {}
    _questionController.clear();
    if (mounted) {
      setState(() {
        _transcript = '';
        _soundLevel = 0;
        _captureRequested = true;
        _listening = true;
      });
    }

    try {
      // Re-initialize from the microphone gesture. Browsers may reject or defer
      // speech recognition initialization when it is first attempted at startup.
      if (!_available) {
        _available = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            setState(() => _listening = _speech.isListening);
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _listening = false;
              _captureRequested = false;
            });
          },
        );
      }
      if (!_available) {
        if (mounted) {
          setState(() {
            _listening = false;
            _captureRequested = false;
          });
          _showMessage(AppLocalizations.of(context)!.voiceSpeechUnavailable);
        }
        return;
      }

      final language = Localizations.localeOf(context).languageCode.toLowerCase();
      try {
        final locales = await _speech.locales();
        final matching = locales.where((item) =>
            item.localeId.toLowerCase().replaceAll('_', '-').startsWith('$language-') ||
            item.localeId.toLowerCase() == language).toList();
        if (matching.isNotEmpty) {
          _localeId = matching.first.localeId;
        } else {
          _localeId = switch (language) {
            'ar' => 'ar-SA',
            'fr' => 'fr-FR',
            _ => 'en-US',
          };
        }
      } catch (_) {
        _localeId = switch (language) {
          'ar' => 'ar-SA',
          'fr' => 'fr-FR',
          _ => 'en-US',
        };
      }

      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
        ),
        onSoundLevelChange: (level) {
          if (mounted) setState(() => _soundLevel = level);
        },
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _transcript = result.recognizedWords;
            _questionController.text = _transcript;
            _questionController.selection = TextSelection.collapsed(
              offset: _questionController.text.length,
            );
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _captureRequested = false;
        });
        _showMessage(AppLocalizations.of(context)!.voiceMicError);
      }
    }
  }

  Future<void> _finishListening() async {
    // _listening can already be false when the browser sends its final status;
    // _captureRequested tracks the user's press-and-hold gesture independently.
    if (!_captureRequested) return;
    _captureRequested = false;
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {
      // Keep any partial transcript; it can still be submitted manually.
    }
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _listening = false);
    final question = _transcript.trim();
    if (question.isNotEmpty) await _respond(question);
  }

  String _getAgriculturalAnswer(String question) {
    final l10n = AppLocalizations.of(context)!;
    final q = question.toLowerCase();
    final waterTerms = ['irrigation', 'eau', 'arroser', 'ري', 'سقي', 'ماء', 'عطش', 'water', 'watering'];
    final yellowTerms = ['jaune', 'feuille', 'feuilles', 'صفرا', 'أوراق', 'ورق', 'اصفر', 'yellow', 'leaf', 'leaves'];
    final pestTerms = ['maladie', 'insecte', 'ravageur', 'مرض', 'حشرة', 'دود', 'آفة', 'disease', 'insect', 'pest'];
    final tomatoTerms = ['tomate', 'tomates', 'طماطم', 'مطّيشة', 'tomato', 'tomatoes'];
    final oliveTerms = ['olive', 'olivier', 'زيتون', 'زيتونة', 'olives'];
    bool containsAny(List<String> terms) => terms.any(q.contains);

    if (containsAny(waterTerms)) return l10n.voiceAnswerWater;
    if (containsAny(yellowTerms)) return l10n.voiceAnswerYellow;
    if (containsAny(pestTerms)) return l10n.voiceAnswerPest;
    if (containsAny(tomatoTerms)) return l10n.voiceAnswerTomato;
    if (containsAny(oliveTerms)) return l10n.voiceAnswerOlive;
    return l10n.voiceAnswerGeneral;
  }

  Future<void> _respond(String question) async {
    if (question.trim().isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _transcript = question;
      _answer = _getAgriculturalAnswer(question);
    });

    try {
      await _speakText(_answer);
    } catch (_) {
      _showMessage(AppLocalizations.of(context)!.voiceAudioError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Configure a real installed voice for the app's active language, then speak.
  /// This is intentionally local/platform TTS: no cloud voice API is used.
  Future<void> _speakText(String text) async {
    if (text.trim().isEmpty) return;

    final language = Localizations.localeOf(context).languageCode.toLowerCase();
    final localeCandidates = switch (language) {
      'ar' => ['ar-SA', 'ar-EG', 'ar-AE', 'ar-MA', 'ar'],
      'fr' => ['fr-FR', 'fr-CA', 'fr-BE', 'fr-CH', 'fr'],
      _ => ['en-US', 'en-GB', 'en-AU', 'en-CA', 'en-IE', 'en'],
    };

    // Keep the visible brand spelling intact; use a TTS-only phonetic form.
    final speechText = switch (language) {
      'fr' => text.replaceAll(RegExp(r'AETHERA', caseSensitive: false), 'Éthéra'),
      'en' => text.replaceAll(RegExp(r'AETHERA', caseSensitive: false), 'Eethara'),
      _ => text,
    };

    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _tts.setSpeechRate(switch (language) {
        'ar' => 0.48,
        'fr' => 0.50,
        _ => 0.50,
      });
    } catch (_) {}
    try {
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (_) {}

    // Do not require getVoices() to return a populated list. Chromium and some
    // mobile engines populate it asynchronously or expose no list at all; the
    // old strict voice filter returned early and consequently produced silence
    // in every language. Ask the platform for a locale and let its TTS engine
    // resolve the installed/default voice. Retry regional then base language.
    Object? lastError;
    for (final locale in localeCandidates) {
      try {
        final languageResult = await _tts.setLanguage(locale);
        if (languageResult == 0 || languageResult == false) {
          lastError = StateError('TTS engine does not support locale $locale');
          continue;
        }
        final result = await _tts.speak(speechText);
        if (result == null || (result != 0 && result != false)) return;
        lastError = StateError('TTS engine rejected speech for locale $locale');
      } catch (error) {
        lastError = error;
      }
      try {
        await _tts.stop();
      } catch (_) {}
    }

    if (lastError != null) throw lastError;
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (mounted) setState(() => _speaking = false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _questionController.dispose();
    _visualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF174D35);
    const green = Color(0xFF38865A);
    const cream = Color(0xFFF6F7F0);
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    final direction = isRtl ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(l10n.voiceTitle),
        backgroundColor: cream,
        foregroundColor: forest,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF245B40), Color(0xFF102E24)]),
                boxShadow: [BoxShadow(color: forest.withValues(alpha: .16), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: Column(
                children: [
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.eco_rounded, color: Color(0xFFD9EBCB), size: 18),
                    SizedBox(width: 8),
                    Text('AETHERA VOICE', style: TextStyle(color: Color(0xFFD9EBCB), letterSpacing: 2, fontWeight: FontWeight.w800, fontSize: 10)),
                  ]),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _listening || _speaking
                        ? _VoiceWaveform(key: ValueKey('wave-$_listening-$_speaking'), controller: _visualController, level: _soundLevel, active: true)
                        : Container(
                            key: const ValueKey('idle'),
                            width: 150,
                            height: 100,
                            alignment: Alignment.center,
                            child: Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .10), border: Border.all(color: Colors.white.withValues(alpha: .28), width: 1.2)),
                              child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 38),
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _listening ? l10n.voiceListening : _speaking ? l10n.voiceSpeaking : l10n.voiceWelcome,
                    textDirection: direction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _listening ? l10n.voiceListeningHint : l10n.voiceInstruction,
                    textDirection: direction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFD2E1D5), fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onLongPressStart: (_) => _startListening(),
                    onLongPressEnd: (_) => _finishListening(),
                    onLongPressCancel: _finishListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: _listening ? 86 : 76,
                      height: _listening ? 86 : 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _listening ? const Color(0xFFE46F62) : const Color(0xFFE5F1E7),
                        boxShadow: [BoxShadow(color: (_listening ? const Color(0xFFE46F62) : const Color(0xFFB9D7BD)).withValues(alpha: .38), blurRadius: _listening ? 28 : 18, spreadRadius: _listening ? 5 : 2)],
                      ),
                      child: Icon(_listening ? Icons.mic_rounded : Icons.mic_none_rounded, color: _listening ? Colors.white : forest, size: 34),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.voicePressHold, style: TextStyle(color: Color(0xFFBFD6C4), fontSize: 9, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _questionController,
              textDirection: direction,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.voiceInputHint,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.edit_outlined, color: green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE4E9DF))),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _busy ? null : () => _respond(_questionController.text),
              icon: const Icon(Icons.send_rounded),
              label: Text(l10n.voiceAsk),
              style: ElevatedButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 22),
            _sectionTitle(l10n.voiceQuestion),
            _contentCard(_transcript.isEmpty ? l10n.voiceNoQuestion : _transcript),
            const SizedBox(height: 16),
            _sectionTitle(l10n.voiceAnswer),
            _contentCard(_answer.isEmpty ? l10n.voiceWelcome : _answer),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _speaking ? _stopSpeaking : () => _speakText(_answer.isEmpty ? l10n.voiceWelcome : _answer),
              icon: Icon(_speaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded),
              label: Text(_speaking ? l10n.voiceStopAudio : l10n.voiceListenAnswer),
            ),
            const SizedBox(height: 12),
            Text(l10n.voiceDisclaimer, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
          color: Color(0xFF174D35),
        ),
      ),
    );
  }

  Widget _contentCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textDirection: Localizations.localeOf(context).languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(fontSize: 16, height: 1.7),
      ),
    );
  }
}

class _VoiceWaveform extends StatelessWidget {
  final AnimationController controller;
  final double level;
  final bool active;
  const _VoiceWaveform({super.key, required this.controller, required this.level, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(31, (index) {
              final wave = math.sin((controller.value * math.pi * 2) + index * .58).abs();
              final envelope = math.sin((index / 30) * math.pi).abs() * .55 + .35;
              final inputBoost = (level.abs() / 12).clamp(0.0, 1.0);
              final height = (10 + wave * 34 * envelope + inputBoost * 30 * envelope).clamp(7.0, 76.0);
              return Container(
                width: 3.5,
                height: active ? height : 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: index % 4 == 0 ? const Color(0xFFD5E9B9) : const Color(0xFF83C99D), borderRadius: BorderRadius.circular(8)),
              );
            }),
          ),
        );
      },
    );
  }
}
