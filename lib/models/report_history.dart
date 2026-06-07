class ReportHistoryModel {
  final String reportId;
  String userId;
  String tipeLaporan; // 'Mingguan' | 'Bulanan' | 'Tahunan'
  DateTime tanggalDibuat;
  String? filePath;
  String periodeLaporan; // e.g., 'April 2026'

  ReportHistoryModel({
    required this.reportId,
    required this.userId,
    required this.tipeLaporan,
    required this.tanggalDibuat,
    this.filePath,
    required this.periodeLaporan,
  });

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'user_id': userId,
      'tipe_laporan': tipeLaporan,
      'tanggal_dibuat': tanggalDibuat.toIso8601String(),
      'file_path': filePath,
      'periode_laporan': periodeLaporan,
    };
  }

  factory ReportHistoryModel.fromMap(Map<String, dynamic> map) {
    return ReportHistoryModel(
      reportId: map['report_id'] as String,
      userId: map['user_id'] as String,
      tipeLaporan: map['tipe_laporan'] as String,
      tanggalDibuat: DateTime.parse(map['tanggal_dibuat'] as String),
      filePath: map['file_path'] as String?,
      periodeLaporan: map['periode_laporan'] as String,
    );
  }
}
