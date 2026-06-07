class CategoryModel {
  final int? kategoriId;
  String namaKategori;
  String tipe; // 'income' | 'expense'
  String ikon; // Material Icon name
  String warna; // Hex color code

  CategoryModel({
    this.kategoriId,
    required this.namaKategori,
    required this.tipe,
    required this.ikon,
    required this.warna,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nama_kategori': namaKategori,
      'tipe': tipe,
      'ikon': ikon,
      'warna': warna,
    };
    if (kategoriId != null) {
      map['kategori_id'] = kategoriId;
    }
    return map;
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      kategoriId: map['kategori_id'] as int?,
      namaKategori: map['nama_kategori'] as String,
      tipe: map['tipe'] as String,
      ikon: map['ikon'] as String,
      warna: map['warna'] as String,
    );
  }
}
