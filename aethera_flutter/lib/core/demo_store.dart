import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CaseStatus { none, submitted, reviewing, responded, resolved }

/// Local demo scenario (farmer <-> expert case flow), persisted on the device.
/// Port of src/lib/demo-store.ts.
class DemoStore extends ChangeNotifier {
  CaseStatus caseStatus = CaseStatus.none;
  String expertVerdict = '';
  List<String> expertPlan = [];
  bool published = false;

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
        notifyListeners();
      }
    } catch (_) {}
  }

  void set(
      {CaseStatus? caseStatus,
      String? expertVerdict,
      List<String>? expertPlan,
      bool? published}) {
    if (caseStatus != null) this.caseStatus = caseStatus;
    if (expertVerdict != null) this.expertVerdict = expertVerdict;
    if (expertPlan != null) this.expertPlan = expertPlan;
    if (published != null) this.published = published;
    notifyListeners();
    _save();
  }

  void reset() => set(
      caseStatus: CaseStatus.none,
      expertVerdict: '',
      expertPlan: [],
      published: false);

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _key,
          jsonEncode({
            'caseStatus': caseStatus.name,
            'expertVerdict': expertVerdict,
            'expertPlan': expertPlan,
            'published': published
          }));
    } catch (_) {}
  }
}
