import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Single access point to the Supabase backend (same project as the web app).
class Backend {
  static SupabaseClient? get client =>
      AppConfig.hasBackend ? Supabase.instance.client : null;

  static Future<void> init() async {
    if (!AppConfig.hasBackend) return;
    await Supabase.initialize(
        url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }
}

/// Row of `risk_alerts`.
class RiskAlert {
  RiskAlert({
    required this.id,
    required this.crop,
    required this.symptomCategory,
    required this.governorate,
    required this.reportCount,
    required this.severity,
    required this.status,
    required this.preventiveSteps,
    required this.infoRequested,
    required this.sameCount,
    required this.notCount,
    required this.isDemo,
    required this.lastReportAt,
    this.expertNote,
  });

  final String id;
  final String crop;
  final String symptomCategory;
  final String governorate;
  final int reportCount;
  final String severity;
  final String status;
  final String? expertNote;
  final List<String> preventiveSteps;
  final bool infoRequested;
  final int sameCount;
  final int notCount;
  final bool isDemo;
  final String lastReportAt;

  factory RiskAlert.fromMap(Map<String, dynamic> m) => RiskAlert(
        id: m['id'] as String,
        crop: (m['crop'] as String?) ?? '',
        symptomCategory: (m['symptom_category'] as String?) ?? '',
        governorate: (m['governorate'] as String?) ?? '',
        reportCount: (m['report_count'] as num?)?.toInt() ?? 0,
        severity: (m['severity'] as String?) ?? 'low',
        status: (m['status'] as String?) ?? 'detected',
        expertNote: m['expert_note'] as String?,
        preventiveSteps: ((m['preventive_steps'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        infoRequested: (m['info_requested'] as bool?) ?? false,
        sameCount: (m['same_count'] as num?)?.toInt() ?? 0,
        notCount: (m['not_count'] as num?)?.toInt() ?? 0,
        isDemo: (m['is_demo'] as bool?) ?? false,
        lastReportAt: (m['last_report_at'] as String?) ?? '',
      );
}

/// Row of `risk_reports` (subset shown to the owner / experts).
class RiskReportRow {
  RiskReportRow(
      {required this.id,
      required this.crop,
      required this.governorate,
      required this.observedOn,
      this.alertId,
      this.symptoms = '',
      this.locality,
      this.photoPath});
  final String id;
  final String crop;
  final String governorate;
  final String observedOn;
  final String? alertId;
  final String symptoms;
  final String? locality;
  final String? photoPath;

  factory RiskReportRow.fromMap(Map<String, dynamic> m) => RiskReportRow(
        id: m['id'] as String,
        crop: (m['crop'] as String?) ?? '',
        governorate: (m['governorate'] as String?) ?? '',
        observedOn: (m['observed_on'] as String?) ?? '',
        alertId: m['alert_id'] as String?,
        symptoms: (m['symptoms'] as String?) ?? '',
        locality: m['locality'] as String?,
        photoPath: m['photo_path'] as String?,
      );
}
