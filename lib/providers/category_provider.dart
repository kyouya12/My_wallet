import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<CategoryModel> _categories = [];
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;

  Future<void> loadCategories() async {
    _categories = await _db.getAllCategories();
    _expenseCategories = _categories.where((c) => c.tipe == 'expense').toList();
    _incomeCategories = _categories.where((c) => c.tipe == 'income').toList();
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.insertCategory(category);
    await loadCategories();
  }

  CategoryModel? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.kategoriId == id);
    } catch (_) {
      return null;
    }
  }

  // Map icon name string to IconData
  static IconData getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'school': Icons.school,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'medical_services': Icons.medical_services,
      'receipt_long': Icons.receipt_long,
      'more_horiz': Icons.more_horiz,
      'account_balance': Icons.account_balance,
      'swap_horiz': Icons.swap_horiz,
      'home': Icons.home,
      'credit_card': Icons.credit_card,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  // Parse hex color string to Color
  static Color parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
