import 'package:flutter/material.dart';
import '../controllers/schedule_controller.dart';
import '../models/schedule.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleController _controller = ScheduleController();

  List<ScheduleModel> _schedules = [];
  List<ScheduleModel> _upcomingSchedules = [];
  bool _isLoading = false;

  List<ScheduleModel> get schedules => _schedules;
  List<ScheduleModel> get upcomingSchedules => _upcomingSchedules;
  bool get isLoading => _isLoading;

  Future<void> loadSchedules(String userId) async {
    _isLoading = true;
    notifyListeners();

    _schedules = await _controller.getAllSchedules(userId);
    _upcomingSchedules = await _controller.getUpcomingSchedules(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSchedule({
    required String userId,
    required int kategoriId,
    required String namaTagihan,
    required double nominal,
    required DateTime tanggalJatuhTempo,
    bool isReminderActive = true,
  }) async {
    try {
      await _controller.addSchedule(
        userId: userId,
        kategoriId: kategoriId,
        namaTagihan: namaTagihan,
        nominal: nominal,
        tanggalJatuhTempo: tanggalJatuhTempo,
        isReminderActive: isReminderActive,
      );
      await loadSchedules(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule, String userId) async {
    await _controller.updateSchedule(schedule);
    await loadSchedules(userId);
  }

  Future<void> deleteSchedule(String jadwalId, String userId) async {
    await _controller.deleteSchedule(jadwalId);
    await loadSchedules(userId);
  }
}
