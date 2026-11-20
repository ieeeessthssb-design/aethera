// Arabic <-> French translation (expert <-> farmer).
//
// The farmer's note stays exactly as he wrote / dictated it. The expert sees
// a French translation next to it (original kept below).
//
// This is the ONLY place that talks to a translation service, so it is the
// only file to change when you move translation to your own backend.
//
// Current provider: MyMemory public API (no API key in the app, free,
// limited to about 5 000 characters per day per IP, 500 bytes per request).
// Privacy note: the note text is sent to that third-party service. For
// production, call your own server instead (which holds any paid key).
import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslateService {
  TranslateService._();

  static final Map<String, String> _cache = {};
  static final RegExp _arabic = RegExp(r'[؀-ۿ]');

  /// true if the text contains Arabic letters (Tunisian or standard).
  static bool hasArabic(String text) => _arabic.hasMatch(text);

  /// Farmer (Arabic) -> expert (French).
  static Future<String> arabicToFrench(String text) =>
      _translate(text, 'ar', 'fr');

  /// Expert (French) -> farmer (Arabic).
  static Future<String> frenchToArabic(String text) =>
      _translate(text, 'fr', 'ar');

  /// Throws if the service fails (offline, quota reached...).
  /// Results are cached for the session.
  static Future<String> _translate(String text, String from, String to) async {
    final clean = text.trim();
    if (clean.isEmpty) return '';
    final key = '$from>$to:$clean';
    final cached = _cache[key];
    if (cached != null) return cached;

    final out = <String>[];
    for (final chunk in _chunks(clean)) {
      out.add(await _translateChunk(chunk, from, to));
    }
    final result = out.join(' ').trim();
    _cache[key] = result;
    return result;
  }

  static Future<String> _translateChunk(
      String chunk, String from, String to) async {
    final uri = Uri.https('api.mymemory.translated.net', '/get', {
      'q': chunk,
      'langpair': '$from|$to',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('translation http ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final status = '${json['responseStatus']}';
    final data = json['responseData'];
    final text = data is Map ? '${data['translatedText'] ?? ''}' : '';
    if (status != '200' ||
        text.isEmpty ||
        text.toUpperCase().contains('MYMEMORY WARNING')) {
      throw Exception('translation refused');
    }
    return _unescape(text);
  }

  /// The service accepts at most 500 bytes per request: cut on sentence
  /// ends first, then on spaces. Arabic letters take 2 bytes each.
  static List<String> _chunks(String text) {
    const maxBytes = 420;
    final parts = text.split(RegExp(r'(?<=[.!?؟،,\n])\s*'));
    final chunks = <String>[];
    var cur = '';

    void flush() {
      if (cur.trim().isNotEmpty) chunks.add(cur.trim());
      cur = '';
    }

    for (final raw in parts) {
      var piece = raw;
      while (utf8.encode(piece).length > maxBytes) {
        // very long sentence: cut at the last space before the limit
        var cut = piece.length;
        while (cut > 1 && utf8.encode(piece.substring(0, cut)).length > maxBytes) {
          cut--;
        }
        final space = piece.lastIndexOf(' ', cut);
        if (space > 0) cut = space;
        flush();
        chunks.add(piece.substring(0, cut).trim());
        piece = piece.substring(cut).trim();
      }
      if (utf8.encode('$cur $piece').length > maxBytes) flush();
      cur = cur.isEmpty ? piece : '$cur $piece';
    }
    flush();
    return chunks;
  }

  static String _unescape(String s) => s
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
