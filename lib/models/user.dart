class UserModel {
  final String userId;
  String namaLengkap;
  String email;
  String passwordHash;
  String? noHp;
  DateTime? tanggalLahir;
  String? jenisKelamin;
  double batasBudget;
  String? fotoProfil;

  UserModel({
    required this.userId,
    required this.namaLengkap,
    required this.email,
    required this.passwordHash,
    this.noHp,
    this.tanggalLahir,
    this.jenisKelamin,
    this.batasBudget = 0,
    this.fotoProfil,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nama_lengkap': namaLengkap,
      'email': email,
      'password_hash': passwordHash,
      'no_hp': noHp,
      'tanggal_lahir': tanggalLahir?.toIso8601String(),
      'jenis_kelamin': jenisKelamin,
      'batas_budget': batasBudget,
      'foto_profil': fotoProfil,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as String,
      namaLengkap: map['nama_lengkap'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      noHp: map['no_hp'] as String?,
      tanggalLahir: map['tanggal_lahir'] != null
          ? DateTime.parse(map['tanggal_lahir'] as String)
          : null,
      jenisKelamin: map['jenis_kelamin'] as String?,
      batasBudget: (map['batas_budget'] as num?)?.toDouble() ?? 0,
      fotoProfil: map['foto_profil'] as String?,
    );
  }

  UserModel copyWith({
    String? namaLengkap,
    String? email,
    String? passwordHash,
    String? noHp,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    double? batasBudget,
    String? fotoProfil,
  }) {
    return UserModel(
      userId: userId,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      noHp: noHp ?? this.noHp,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      batasBudget: batasBudget ?? this.batasBudget,
      fotoProfil: fotoProfil ?? this.fotoProfil,
    );
  }
}
