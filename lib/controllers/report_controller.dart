import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/report_history.dart';

class ReportController {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  Future<ReportHistoryModel> generateReport({
    required String userId,
    required String tipeLaporan,
    required String periodeLaporan,
    String? filePath,
  }) async {
    final report = ReportHistoryModel(
      reportId: _uuid.v4(),
      userId: userId,
      tipeLaporan: tipeLaporan,
      tanggalDibuat: DateTime.now(),
      filePath: filePath,
      periodeLaporan: periodeLaporan,
    );

    await _db.insertReport(report);
    return report;
  }

  Future<List<ReportHistoryModel>> getReportHistory(String userId) async {
    return await _db.getReportsByUser(userId);
  }

  Future<void> deleteReport(String reportId) async {
    await _db.deleteReport(reportId);
  }
}
