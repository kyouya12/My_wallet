import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionController _controller = TransactionController();
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _recentTransactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  Map<int, double> _expenseByCategory = {};
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;
  Map<int, double> get expenseByCategory => _expenseByCategory;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions(String userId) async {
    _isLoading = true;
    notifyListeners();

    _transactions = await _db.getTransactionsByUser(userId);
    _recentTransactions = await _controller.getRecentTransactions(userId, limit: 5);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthlySummary(String userId, int month, int year) async {
    final summary = await _controller.getIncomeExpenseSummary(userId, month, year);
    _totalIncome = summary['income'] ?? 0;
    _totalExpense = summary['expense'] ?? 0;
    _balance = summary['balance'] ?? 0;

    _expenseByCategory = await _controller.getMonthlyExpenseByCategory(userId, month, year);
    notifyListeners();
  }

  Future<bool> addTransaction({
    required String userId,
    required int kategoriId,
    required String tipeTrx,
    required double nominal,
    required DateTime tanggalTrx,
    String? catatan,
  }) async {
    try {
      await _controller.addTransaction(
        userId: userId,
        kategoriId: kategoriId,
        tipeTrx: tipeTrx,
        nominal: nominal,
        tanggalTrx: tanggalTrx,
        catatan: catatan,
      );

      // Reload data
      await loadTransactions(userId);
      final now = DateTime.now();
      await loadMonthlySummary(userId, now.month, now.year);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteTransaction(String trxId, String userId) async {
    await _controller.deleteTransaction(trxId);
    await loadTransactions(userId);
    final now = DateTime.now();
    await loadMonthlySummary(userId, now.month, now.year);
  }
}
