// Voice module reused from the "Voice" project (assistant_service.dart),
// reduced to what Aethera needs: speech-to-text + text-to-speech.
// NOTHING here calls an AI: the transcript is only handed back to the
// Aethera screen, which sends it through its own existing workflow.
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceError {
  speechUnavailable,
  micDenied,
  notUnderstood,
  network,
  generic,
}

class VoiceException implements Exception {
  const VoiceException(this.error);
  final VoiceError error;
}

/// [lang] is always the app language: 'ar' (Tunisian) or 'fr'.
/// No auto-detection and no mixing — the farmer's choice decides.
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechReady = false;
  bool _active = false;
  String _heard = '';
  String _lang = 'fr';
  void Function()? _onEnded;
  void Function(VoiceError)? _onError;

  bool _speaking = false;
  int _speakToken = 0;
  Completer<void>? _chunkDone;

  // ---------- Speech recognition ----------
  // No time limit: the browser/phone engine stops by itself after a pause or
  // a few tens of seconds, so we restart it automatically and keep the text
  // already heard. Listening only ends when the farmer taps "Terminer".

  bool _wanted = false; // true until the farmer stops
  String _committed = ''; // text of previous engine sessions
  String? _localeId;
  int _emptyRestarts = 0;

  Future<void> startListening({
    required String lang,
    required void Function(String text) onText,
    required void Function() onEnded,
    required void Function(VoiceError error) onError,
  }) async {
    _heard = '';
    _committed = '';
    _lang = lang;
    _onEnded = onEnded;
    _onError = onError;
    _onText = onText;
    _emptyRestarts = 0;

    if (!_speechReady) {
      try {
        _speechReady = await _speech.initialize(
          onStatus: _handleStatus,
          onError: _handleError,
        );
      } catch (_) {
        _speechReady = false;
      }
      if (!_speechReady) {
        throw const VoiceException(VoiceError.speechUnavailable);
      }
    }

    _localeId = await _pickLocale(lang);
    _wanted = true;
    await _listen();
  }

  void Function(String)? _onText;

  Future<void> _listen() async {
    _active = true;
    await _speech.listen(
      onResult: (result) {
        final part = _clean(result.recognizedWords);
        if (part.isNotEmpty) _emptyRestarts = 0;
        _heard = _committed.isEmpty
            ? part
            : (part.isEmpty ? _committed : '$_committed $part');
        _onText?.call(_heard);
      },
      localeId: _localeId,
      listenFor: const Duration(minutes: 30),
      pauseFor: const Duration(minutes: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<String> stopListening() async {
    _wanted = false;
    _active = false;
    try {
      await _speech.stop();
    } catch (_) {}
    // Let the last recognition result arrive.
    await Future.delayed(const Duration(milliseconds: 500));
    return _heard;
  }

  Future<void> cancelListening() async {
    _wanted = false;
    _active = false;
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  /// The engine ended by itself (pause / browser limit): keep going.
  Future<void> _restart() async {
    if (!_wanted) return;
    _committed = _heard;
    _emptyRestarts++;
    if (_emptyRestarts > 40) {
      _wanted = false;
      _onEnded?.call();
      return;
    }
    await Future.delayed(const Duration(milliseconds: 250));
    if (!_wanted) return;
    try {
      await _listen();
    } catch (_) {
      if (_wanted) {
        _wanted = false;
        _active = false;
        if (_heard.isEmpty) {
          _onError?.call(VoiceError.generic);
        } else {
          _onEnded?.call();
        }
      }
    }
  }

  void _handleStatus(String status) {
    if (!_active) return;
    if (status == 'done' || status == 'notListening') {
      _active = false;
      if (_wanted) {
        _restart();
      } else {
        _onEnded?.call();
      }
    }
  }

  void _handleError(dynamic error) {
    if (!_active) return;
    final message = error.errorMsg.toString();
    if (message.contains('permission') || message.contains('not-allowed')) {
      _wanted = false;
      _active = false;
      _onError?.call(VoiceError.micDenied);
    } else if (message.contains('network')) {
      _wanted = false;
      _active = false;
      _onError?.call(VoiceError.network);
    } else if (_wanted) {
      // silence / no match: just listen again
      _active = false;
      _restart();
    } else if (_heard.isEmpty) {
      _active = false;
      _onError?.call(VoiceError.notUnderstood);
    } else {
      _active = false;
      _onEnded?.call();
    }
  }

  // Tunisian mode = Arabic script only; French mode = Latin script only.
  // The browser engine sometimes mixes scripts (French loanwords written in
  // Latin letters inside an Arabic transcript). Known farm words are converted
  // to Arabic; other foreign-script words are removed.
  static const Map<String, String> _frToAr = {
    'tomate': 'طماطم', 'tomates': 'طماطم',
    'poivron': 'فلفل', 'poivrons': 'فلفل', 'piment': 'فلفل',
    'patate': 'بطاطا', 'patates': 'بطاطا',
    'oignon': 'بصل', 'oignons': 'بصل',
    'mildiou': 'ميلديو', 'engrais': 'سماد',
    'arrosage': 'سقي', 'irrigation': 'ري',
    'maladie': 'مرض', 'feuille': 'ورقة', 'feuilles': 'ورق',
    'jaune': 'أصفر', 'jaunes': 'صفراء',
  };
  static final RegExp _latin = RegExp(r'[A-Za-z\u00C0-\u00FF]');
  static final RegExp _arabic = RegExp(r'[\u0600-\u06FF]');

  String _clean(String raw) {
    final out = <String>[];
    for (final tok in raw.split(RegExp(r'\s+'))) {
      if (tok.isEmpty) continue;
      if (_lang == 'ar') {
        if (!_latin.hasMatch(tok)) {
          out.add(tok);
          continue;
        }
        final key = tok.toLowerCase().replaceAll(RegExp(r'[^a-z\u00C0-\u00FF]'), '');
        final ar = _frToAr[key];
        if (ar != null) out.add(ar);
      } else {
        if (!_arabic.hasMatch(tok)) out.add(tok);
      }
    }
    return out.join(' ');
  }

  String _norm(String s) => s.replaceAll('-', '_').toLowerCase();

  Future<String?> _pickLocale(String lang) async {
    final isAr = lang == 'ar';
    final preferred = isAr
        ? ['ar_tn', 'ar_dz', 'ar_ma', 'ar_ly', 'ar_sa', 'ar_eg', 'ar']
        : ['fr_fr', 'fr_tn', 'fr_ca', 'fr'];
    try {
      final locales = await _speech.locales();
      for (final want in preferred) {
        for (final l in locales) {
          if (_norm(l.localeId) == want) return l.localeId;
        }
      }
      final prefix = isAr ? 'ar' : 'fr';
      for (final l in locales) {
        if (_norm(l.localeId).startsWith(prefix)) return l.localeId;
      }
    } catch (_) {}
    if (isAr) return kIsWeb ? 'ar-TN' : 'ar_TN';
    return kIsWeb ? 'fr-FR' : 'fr_FR';
  }

  // ---------- Text-to-speech ("اسمع") ----------

  bool get isSpeaking => _speaking;

  /// Reads [text] aloud, sentence by sentence (long answers are cut by some
  /// browsers when sent as one block). [lang]: 'ar', 'fr' or 'en'.
  /// Completes when finished or stopped.
  Future<void> speak(String text, String lang) async {
    await stopSpeaking();
    final token = ++_speakToken;
    _speaking = true;

    void done() {
      final c = _chunkDone;
      if (c != null && !c.isCompleted) c.complete();
    }

    _tts.setCompletionHandler(done);
    _tts.setCancelHandler(done);
    _tts.setErrorHandler((_) => done());

    try {
      await _prepareVoice(lang);
      for (final chunk in _chunks(text)) {
        if (token != _speakToken) break;
        final c = Completer<void>();
        _chunkDone = c;
        await _tts.speak(chunk);
        await c.future.timeout(const Duration(seconds: 40), onTimeout: () {});
      }
    } finally {
      if (token == _speakToken) _speaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    _speakToken++;
    _speaking = false;
    final c = _chunkDone;
    if (c != null && !c.isCompleted) c.complete();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  List<String> _chunks(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return const [];
    final parts = clean.split(RegExp(r'(?<=[.!?؟…:])\s+'));
    final out = <String>[];
    var cur = '';
    for (final p in parts) {
      if (cur.isNotEmpty && (cur.length + p.length) > 240) {
        out.add(cur);
        cur = p;
      } else {
        cur = cur.isEmpty ? p : '$cur $p';
      }
    }
    if (cur.isNotEmpty) out.add(cur);
    return out;
  }

  Future<void> _prepareVoice(String lang) async {
    final candidates = switch (lang) {
      'ar' => ['ar-TN', 'ar-DZ', 'ar-MA', 'ar-SA', 'ar'],
      'en' => ['en-US', 'en-GB', 'en'],
      _ => ['fr-FR', 'fr'],
    };
    String? chosen;
    for (final code in candidates) {
      try {
        final ok = await _tts.isLanguageAvailable(code);
        if (ok == true || ok == 1) {
          chosen = code;
          break;
        }
      } catch (_) {}
    }
    chosen ??= candidates.last;
    try {
      await _tts.setLanguage(chosen);
    } catch (_) {}

    // Prefer a natural / online voice of that exact locale when the
    // browser or phone offers one (e.g. Edge "Hedi / Reem Online (Natural)").
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        Map? best;
        var bestScore = -1;
        for (final v in voices) {
          if (v is! Map) continue;
          final loc = _norm('${v['locale'] ?? ''}');
          if (loc != _norm(chosen)) continue;
          final name = '${v['name'] ?? ''}'.toLowerCase();
          var score = 1;
          if (name.contains('natural')) score += 3;
          if (name.contains('online')) score += 2;
          if (score > bestScore) {
            bestScore = score;
            best = v;
          }
        }
        if (best != null) {
          await _tts.setVoice({
            'name': '${best['name']}',
            'locale': '${best['locale']}',
          });
        }
      }
    } catch (_) {}

    // Faster reading. On the web the rate is a multiplier (1.0 = normal);
    // on Android/iOS 0.5 is the normal speed.
    try {
      final rate = kIsWeb
          ? (lang == 'ar' ? 1.05 : 1.15)
          : (lang == 'ar' ? 0.52 : 0.58);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  void dispose() {
    _wanted = false;
    _active = false;
    _speakToken++;
    _speech.cancel();
    _tts.stop();
  }
}
