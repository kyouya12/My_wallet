import '../database/database_helper.dart';
import '../models/user.dart';

class ProfileController {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<UserModel?> updateProfile({
    required String userId,
    String? namaLengkap,
    String? email,
    String? noHp,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    String? fotoProfil,
  }) async {
    final user = await _db.getUserById(userId);
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    // Check if new email already exists for another user
    if (email != null && email != user.email) {
      final existing = await _db.getUserByEmail(email);
      if (existing != null) {
        throw Exception('Email sudah digunakan');
      }
    }

    final updated = user.copyWith(
      namaLengkap: namaLengkap,
      email: email,
      noHp: noHp,
      tanggalLahir: tanggalLahir,
      jenisKelamin: jenisKelamin,
      fotoProfil: fotoProfil,
    );

    await _db.updateUser(updated);
    return updated;
  }

  Future<UserModel?> updateBudget(String userId, double newBudget) async {
    final user = await _db.getUserById(userId);
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    final updated = user.copyWith(batasBudget: newBudget);
    await _db.updateUser(updated);
    return updated;
  }

  Future<void> deleteAllData(String userId) async {
    await _db.deleteAllUserData(userId);
  }
}
