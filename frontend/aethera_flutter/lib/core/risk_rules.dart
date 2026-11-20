// Mirrors the database clustering trigger (cluster_report) so the rules are testable.
const int kClusterMinReports = 3;
const int kClusterWindowDays = 14;
const int kSensorStaleHours = 6;

class ReportLike {
  const ReportLike(
      {required this.crop,
      required this.symptomCategory,
      required this.governorate,
      required this.observedOn});
  final String crop;
  final String symptomCategory;
  final String governorate;
  final String observedOn;
}

bool shouldCluster(List<ReportLike> reports, ReportLike target,
    {DateTime? today}) {
  final now = today ?? DateTime.now();
  final cutoff = now.subtract(const Duration(days: kClusterWindowDays));
  final n = reports.where((r) {
    final d = DateTime.tryParse(r.observedOn);
    return r.crop == target.crop &&
        r.symptomCategory == target.symptomCategory &&
        r.governorate == target.governorate &&
        d != null &&
        !d.isBefore(cutoff);
  }).length;
  return n >= kClusterMinReports;
}

String severityFor(int count) =>
    count >= 8 ? 'high' : (count >= 5 ? 'medium' : 'low');

bool isSensorStale(String? recordedAt, {DateTime? now}) {
  if (recordedAt == null || recordedAt.isEmpty) return true;
  final t = DateTime.tryParse(recordedAt);
  if (t == null) return true;
  return (now ?? DateTime.now()).difference(t).inMilliseconds >
      kSensorStaleHours * 3600000;
}
