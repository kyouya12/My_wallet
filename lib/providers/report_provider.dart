import 'package:flutter/material.dart';
import '../controllers/report_controller.dart';
import '../models/report_history.dart';

class ReportProvider extends ChangeNotifier {
  final ReportController _controller = ReportController();

  List<ReportHistoryModel> _reports = [];
  String _selectedPeriod = 'Bulan'; // 'Minggu' | 'Bulan' | 'Tahun'
  bool _isLoading = false;

  List<ReportHistoryModel> get reports => _reports;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  Future<void> loadReports(String userId) async {
    _isLoading = true;
    notifyListeners();

    _reports = await _controller.getReportHistory(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> generateReport({
    required String userId,
    required String tipeLaporan,
    required String periodeLaporan,
    String? filePath,
  }) async {
    try {
      await _controller.generateReport(
        userId: userId,
        tipeLaporan: tipeLaporan,
        periodeLaporan: periodeLaporan,
        filePath: filePath,
      );
      await loadReports(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteReport(String reportId, String userId) async {
    await _controller.deleteReport(reportId);
    await loadReports(userId);
  }
}
