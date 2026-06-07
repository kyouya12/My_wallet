import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthController {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserModel?> register({
    required String namaLengkap,
    required String email,
    required String password,
    String? noHp,
    DateTime? tanggalLahir,
    String? jenisKelamin,
  }) async {
    // Check if email already exists
    final existing = await _db.getUserByEmail(email);
    if (existing != null) {
      throw Exception('Email sudah terdaftar');
    }

    final user = UserModel(
      userId: _uuid.v4(),
      namaLengkap: namaLengkap,
      email: email,
      passwordHash: hashPassword(password),
      noHp: noHp,
      tanggalLahir: tanggalLahir,
      jenisKelamin: jenisKelamin,
      batasBudget: 1600000, // Default budget
    );

    await _db.insertUser(user);
    return user;
  }

  Future<UserModel?> login(String email, String password) async {
    final user = await _db.getUserByEmail(email);
    if (user == null) {
      throw Exception('Email tidak ditemukan');
    }

    final passwordHash = hashPassword(password);
    if (user.passwordHash != passwordHash) {
      throw Exception('Password salah');
    }

    return user;
  }
}
