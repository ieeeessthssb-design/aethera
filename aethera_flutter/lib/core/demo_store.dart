import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show ImageProvider;
import 'package:shared_preferences/shared_preferences.dart';

enum CaseStatus { none, submitted, reviewing, responded, resolved }

/// What the farmer actually sent to the expert (question typed or spoken,
/// photo, AI result at that moment, and the trail of his actions).
/// The expert page reads this to show the case details.
class FarmerSubmission {
  const FarmerSubmission({
    required this.origin,
    required this.note,
    required this.spoken,
    required this.lang,
    required this.crop,
    required this.aiPrediction,
    required this.aiConfidence,
    required this.aiAnalysis,
    required this.aiRecommendation,
    required this.actions,
    required this.createdAt,
    this.farmContext = '',
    this.photo,
    this.photoName,
  });

  /// 'assist' (Aide rapide) or 'diagnose' (Diagnostic).
  final String origin;

  /// The farmer's question / symptoms, exactly as sent (written or dictated).
  final String note;

  /// true when the note was dictated with the voice button.
  final bool spoken;

  /// App language when sent: 'ar' (Tunisian) or 'fr'.
  final String lang;
  final String crop;
  final String aiPrediction;
  final double aiConfidence; // 0..1
  final String aiAnalysis;
  final String aiRecommendation;
  final String farmContext;

  /// Trail of what the farmer did in the app before sending.
  final List<String> actions;
  final DateTime createdAt;

  /// Photo is kept in memory only (not saved on the device).
  final ImageProvider? photo;
  final String? photoName;

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'note': note,
        'spoken': spoken,
        'lang': lang,
        'crop': crop,
        'aiPrediction': aiPrediction,
        'aiConfidence': aiConfidence,
        'aiAnalysis': aiAnalysis,
        'aiRecommendation': aiRecommendation,
        'farmContext': farmContext,
        'actions': actions,
        'createdAt': createdAt.toIso8601String(),
        'photoName': photoName,
      };

  static FarmerSubmission? fromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      return FarmerSubmission(
        origin: '${raw['origin'] ?? 'assist'}',
        note: '${raw['note'] ?? ''}',
        spoken: raw['spoken'] == true,
        lang: '${raw['lang'] ?? 'fr'}',
        crop: '${raw['crop'] ?? ''}',
        aiPrediction: '${raw['aiPrediction'] ?? ''}',
        aiConfidence: ((raw['aiConfidence'] as num?) ?? 0).toDouble(),
        aiAnalysis: '${raw['aiAnalysis'] ?? ''}',
        aiRecommendation: '${raw['aiRecommendation'] ?? ''}',
        farmContext: '${raw['farmContext'] ?? ''}',
        actions: ((raw['actions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        createdAt:
            DateTime.tryParse('${raw['createdAt']}') ?? DateTime.now(),
        photoName: raw['photoName'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Local demo scenario (farmer <-> expert case flow), persisted on the device.
/// Port of src/lib/demo-store.ts.
class DemoStore extends ChangeNotifier {
  CaseStatus caseStatus = CaseStatus.none;
  String expertVerdict = '';
  List<String> expertPlan = [];
  bool published = false;

  /// The case the farmer sent (null until he sends one).
  FarmerSubmission? submission;

  /// Expert decision on that case: '' | 'confirmed' | 'rejected'.
  String expertDecision = '';

  static const _key = 'agribridge-demo';

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        caseStatus = CaseStatus.values.firstWhere(
            (e) => e.name == m['caseStatus'],
            orElse: () => CaseStatus.none);
        expertVerdict = (m['expertVerdict'] as String?) ?? '';
        expertPlan = ((m['expertPlan'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();
        published = (m['published'] as bool?) ?? false;
        submission = FarmerSubmission.fromJson(m['submission']);
        expertDecision = (m['expertDecision'] as String?) ?? '';
        notifyListeners();
      }
    } catch (_) {}
  }

  void set(
      {CaseStatus? caseStatus,
      String? expertVerdict,
      List<String>? expertPlan,
      bool? published,
      FarmerSubmission? submission,
      String? expertDecision}) {
    if (caseStatus != null) this.caseStatus = caseStatus;
    if (expertVerdict != null) this.expertVerdict = expertVerdict;
    if (expertPlan != null) this.expertPlan = expertPlan;
    if (published != null) this.published = published;
    if (submission != null) this.submission = submission;
    if (expertDecision != null) this.expertDecision = expertDecision;
    notifyListeners();
    _save();
  }

  void reset() {
    submission = null;
    set(
        caseStatus: CaseStatus.none,
        expertVerdict: '',
        expertPlan: [],
        published: false,
        expertDecision: '');
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _key,
          jsonEncode({
            'caseStatus': caseStatus.name,
            'expertVerdict': expertVerdict,
            'expertPlan': expertPlan,
            'published': published,
            'submission': submission?.toJson(),
            'expertDecision': expertDecision
          }));
    } catch (_) {}
  }
}
