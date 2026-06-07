import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_screen.dart';
import 'add_schedule_screen.dart';
import 'add_transaction_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'edit_profile_screen.dart';
import 'manage_category_screen.dart';
import 'providers/transaction_provider.dart';
import 'providers/schedule_provider.dart';
import 'all_transactions_screen.dart';
import 'package:intl/intl.dart';
import 'main.dart'; // For LoginScreen
import 'models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomNavIndex = 0;
  String _selectedReportPeriod = 'Bulan';
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('is_notification_enabled') ?? true;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_notification_enabled', value);
    setState(() {
      _isNotificationEnabled = value;
    });
  }

  Map<String, dynamic> _getReportData(List<TransactionModel> transactions) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (_selectedReportPeriod == 'Minggu') {
      int daysSinceMonday = now.weekday - 1;
      start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceMonday));
    } else if (_selectedReportPeriod == 'Bulan') {
      start = DateTime(now.year, now.month, 1);
    } else {
      start = DateTime(now.year, 1, 1);
    }

    double totalExpense = 0;
    Map<String, double> expenseByCategory = {};
    Map<String, Map<String, dynamic>> categoryDetails = {};

    for (var trx in transactions) {
      if (trx.tipeTrx == 'expense' && trx.tanggalTrx.isAfter(start.subtract(const Duration(seconds: 1))) && trx.tanggalTrx.isBefore(end.add(const Duration(seconds: 1)))) {
        totalExpense += trx.nominal;
        String catName = trx.category?.namaKategori ?? 'Lainnya';
        expenseByCategory[catName] = (expenseByCategory[catName] ?? 0) + trx.nominal;

        if (!categoryDetails.containsKey(catName)) {
           IconData icon = Icons.receipt_long;
           Color iconColor = const Color(0xFF7C3AED);
           Color bgColor = const Color(0xFFF3E8FF);

           if (catName == 'Makanan') {
             icon = Icons.restaurant;
             iconColor = const Color(0xFFE87A3E);
             bgColor = const Color(0xFFFCEFE8);
           } else if (catName == 'Transportasi') {
             icon = Icons.directions_car;
             iconColor = const Color(0xFF3B82F6);
             bgColor = const Color(0xFFEBF8FF);
           } else if (catName == 'Edukasi') {
             icon = Icons.school;
             iconColor = const Color(0xFF8B5CF6);
             bgColor = const Color(0xFFF3E8FF);
           }

           categoryDetails[catName] = {
             'icon': icon,
             'iconColor': iconColor,
             'bgColor': bgColor,
             'barColor': iconColor.withOpacity(0.6),
           };
        }
      }
    }

    var sortedEntries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> sortedCategories = [];
    for (var entry in sortedEntries) {
      sortedCategories.add({
        'name': entry.key,
        'amount': entry.value,
        'percent': totalExpense > 0 ? entry.value / totalExpense : 0.0,
        ...categoryDetails[entry.key]!,
      });
    }

    return {
      'totalExpense': totalExpense,
      'categories': sortedCategories,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.97, // Sedikit membesar (zoom-in)
                  end: 1.0,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _getScreenContent(),
        ),
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF3366FF), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AddTransactionBottomSheet(),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 5;
              int positionIndex = _bottomNavIndex;
              if (_bottomNavIndex >= 2) positionIndex = _bottomNavIndex + 1;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: positionIndex * tabWidth + (tabWidth / 2) - 28,
                    top: 6,
                    child: Container(
                      width: 56,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(Icons.home_filled, 'BERANDA', 0),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          Icons.analytics_outlined,
                          'LAPORAN',
                          1,
                        ),
                      ),
                      const Expanded(child: SizedBox()), // Space for FAB
                      Expanded(
                        child: _buildNavItem(
                          Icons.calendar_today_outlined,
                          'JADWAL',
                          2,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(Icons.person_outline, 'PROFIL', 3),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getScreenContent() {
    if (_bottomNavIndex == 0)
      return KeyedSubtree(key: const ValueKey(0), child: _buildHomeContent());
    if (_bottomNavIndex == 1)
      return KeyedSubtree(key: const ValueKey(1), child: _buildReportContent());
    if (_bottomNavIndex == 2)
      return KeyedSubtree(
        key: const ValueKey(2),
        child: _buildScheduleContent(),
      );
    if (_bottomNavIndex == 3)
      return KeyedSubtree(
        key: const ValueKey(3),
        child: _buildProfileContent(),
      );
    return KeyedSubtree(
      key: const ValueKey(4),
      child: Center(child: Text('Coming Soon', style: GoogleFonts.inter())),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: const Color(0xFF3366FF),
                    fontWeight: FontWeight.bold,
                  ),
                  children: const [
                    TextSpan(text: 'My '),
                    TextSpan(
                      text: 'Wallet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showNotificationBottomSheet(context),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF3366FF),
                      size: 28,
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFAFAFC), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B5BDB), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3366FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SALDO ANDA',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showInitialBalanceBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<TransactionProvider>(
                  builder: (context, provider, _) => Text(
                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(provider.balance),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<TransactionProvider>(
                  builder: (context, provider, _) => Row(
                    children: [
                      _buildBalancePill(
                        icon: Icons.arrow_downward,
                        iconColor: Colors.green,
                        label: 'Income',
                        amount: NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(provider.totalIncome),
                      ),
                      const SizedBox(width: 12),
                      _buildBalancePill(
                        icon: Icons.arrow_upward,
                        iconColor: Colors.red,
                        label: 'Expense',
                        amount: NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(provider.totalExpense),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budget Card
          Consumer2<TransactionProvider, UserProvider>(
            builder: (context, trxProvider, userProvider, _) {
              final batasBudget = userProvider.batasBudget;
              final terpakai = trxProvider.totalExpense;
              final percent = batasBudget > 0 ? (terpakai / batasBudget).clamp(0.0, 1.0) : 0.0;
              
              return GestureDetector(
                onTap: () => _showSetBudgetBottomSheet(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget Bulan Ini',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              batasBudget > 0 ? 'Aktif' : 'Atur',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Terpakai',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(terpakai)} ',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: '/ Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(batasBudget)}',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percent,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: percent >= 0.9 ? const Color(0xFFE11D48) : const Color(0xFFF5A623),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(percent * 100).toStringAsFixed(0)}% of budget',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: Color(0xFFF0F0F0)),
                      ),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          children: [
                            const TextSpan(text: 'Sisa budget: '),
                            TextSpan(
                              text: 'Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format((batasBudget - terpakai) > 0 ? batasBudget - terpakai : 0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Actions Grid
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context: context,
                  icon: Icons.swap_horiz,
                  iconColor: const Color(0xFF3366FF),
                  bgColor: const Color(0xFFEef2ff),
                  label: 'Transfer',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context: context,
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFF3E8FF),
                  label: 'Tagihan',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context: context,
                  icon: Icons.savings_outlined,
                  iconColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFE1F5E9),
                  label: 'Nabung',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context: context,
                  icon: Icons.more_horiz,
                  iconColor: Colors.grey.shade700,
                  bgColor: Colors.grey.shade100,
                  label: 'Lainnya',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Transactions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Terakhir',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllTransactionsScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF3366FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<TransactionProvider>(
                  builder: (context, provider, _) {
                    if (provider.recentTransactions.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Belum ada transaksi',
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: provider.recentTransactions.map((trx) {
                        final isPemasukan = trx.tipeTrx == 'income';
                        // Map category to icon (simplification)
                        IconData icon = Icons.receipt_long;
                        Color iconColor = const Color(0xFF7C3AED);
                        Color bgColor = const Color(0xFFF3E8FF);

                        if (trx.category?.namaKategori == 'Makanan') {
                          icon = Icons.restaurant;
                          iconColor = const Color(0xFFE87A3E);
                          bgColor = const Color(0xFFFCEFE8);
                        } else if (trx.category?.namaKategori == 'Transportasi') {
                          icon = Icons.directions_car;
                          iconColor = const Color(0xFF3B82F6);
                          bgColor = const Color(0xFFEBF8FF);
                        } else if (isPemasukan) {
                          icon = Icons.account_balance;
                          iconColor = const Color(0xFF10B981);
                          bgColor = const Color(0xFFE1F5E9);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Dismissible(
                            key: Key(trx.trxId ?? trx.hashCode.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              final userId = context.read<UserProvider>().userId;
                              if (userId != null && trx.trxId != null) {
                                context.read<TransactionProvider>().deleteTransaction(trx.trxId!, userId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaksi dihapus')),
                                );
                              }
                            },
                            child: _buildTransactionItem(
                              icon: icon,
                              iconColor: iconColor,
                              bgColor: bgColor,
                              title: trx.catatan?.isNotEmpty == true ? trx.catatan! : (trx.category?.namaKategori ?? 'Lainnya'),
                              time: DateFormat('dd MMM, HH:mm').format(trx.tanggalTrx),
                              amount: '${isPemasukan ? '+' : '-'}Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(trx.nominal)}',
                              isPositive: isPemasukan,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // padding for FAB
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final reportData = _getReportData(provider.transactions);
        final totalExpense = reportData['totalExpense'] as double;
        final categories = reportData['categories'] as List<Map<String, dynamic>>;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Laporan Keuangan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                onSelected: (value) {
                  if (value == 'share') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur membagikan laporan akan segera hadir')),
                    );
                  } else if (value == 'download') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mengunduh laporan PDF...')),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'share',
                    child: Text('Bagikan Laporan'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'download',
                    child: Text('Unduh PDF'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Toggles
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedReportPeriod = 'Minggu'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: _selectedReportPeriod == 'Minggu' ? BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ) : null,
                      child: Center(
                        child: Text(
                          'Minggu',
                          style: GoogleFonts.inter(
                            color: _selectedReportPeriod == 'Minggu' ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: _selectedReportPeriod == 'Minggu' ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedReportPeriod = 'Bulan'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: _selectedReportPeriod == 'Bulan' ? BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ) : null,
                      child: Center(
                        child: Text(
                          'Bulan',
                          style: GoogleFonts.inter(
                            color: _selectedReportPeriod == 'Bulan' ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: _selectedReportPeriod == 'Bulan' ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedReportPeriod = 'Tahun'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: _selectedReportPeriod == 'Tahun' ? BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ) : null,
                      child: Center(
                        child: Text(
                          'Tahun',
                          style: GoogleFonts.inter(
                            color: _selectedReportPeriod == 'Tahun' ? Colors.black87 : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: _selectedReportPeriod == 'Tahun' ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'TOTAL PENGELUARAN',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalExpense),
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Periode $_selectedReportPeriod',
              style: GoogleFonts.inter(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Donut Chart Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: DonutChartPainter(categories),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          categories.isNotEmpty ? '${(categories.first['percent'] * 100).toStringAsFixed(0)}%' : '0%',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          categories.isNotEmpty ? categories.first['name'] : 'Belum Ada',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Rincian per Kategori
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rincian per Kategori',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                if (categories.isEmpty)
                  Text(
                    'Belum ada pengeluaran di periode ini',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  )
                else
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildCategoryItem(
                          icon: cat['icon'] as IconData,
                          iconBgColor: cat['bgColor'] as Color,
                          iconColor: cat['iconColor'] as Color,
                          title: cat['name'] as String,
                          amount: NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(cat['amount']),
                          percent: cat['percent'] as double,
                          barColor: cat['barColor'] as Color,
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Download Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF3366FF),
              ),
              label: Text(
                'Download Laporan PDF',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3366FF),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100), // padding for FAB
        ],
      ),
    );
    });
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String amount,
    required double percent,
    required Color barColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalancePill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context, // Added BuildContext
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fitur $label akan segera hadir')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String time,
    required String amount,
    required bool isPositive,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isPositive ? const Color(0xFF10B981) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : Colors.grey.shade400,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : Colors.grey.shade400,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    final List<String> daysOfWeek = [
      'Min',
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
    ];
    final List<int> days = [
      29,
      30,
      31,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      1,
      2,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kalender & Jadwal',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Calendar Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Month Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'April 2026',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Days of week
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: daysOfWeek
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Calendar Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.85,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isPrevMonth = index < 3; // 29, 30, 31
                    final isNextMonth = index > 32; // 1, 2
                    final isCurrentMonth = !isPrevMonth && !isNextMonth;

                    final isSelected = day == 14 && isCurrentMonth;
                    final hasEvent = (day == 20 || day == 25) && isCurrentMonth;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3366FF)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : isCurrentMonth
                                    ? Colors.black87
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                        if (hasEvent)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Jadwal Mendatang',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Consumer<ScheduleProvider>(
            builder: (context, provider, _) {
              if (provider.schedules.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Belum ada jadwal',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: provider.schedules.map((schedule) {
                  // Map category to icon
                  IconData icon = Icons.receipt_long;
                  Color iconColor = const Color(0xFF8B5CF6);
                  Color iconBgColor = const Color(0xFFF3E8FF);

                  if (schedule.category?.namaKategori == 'Rumah') {
                    icon = Icons.home_outlined;
                    iconColor = const Color(0xFF10B981);
                    iconBgColor = const Color(0xFFE1F5E9);
                  } else if (schedule.category?.namaKategori == 'Cicilan') {
                    icon = Icons.credit_card_outlined;
                    iconColor = const Color(0xFF3B82F6);
                    iconBgColor = const Color(0xFFEBF8FF);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildScheduleItem(
                      id: schedule.jadwalId,
                      icon: icon,
                      iconColor: iconColor,
                      iconBgColor: iconBgColor,
                      title: schedule.namaTagihan,
                      date: DateFormat('dd MMM yyyy').format(schedule.tanggalJatuhTempo),
                      amount: '-Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(schedule.nominal)}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddScheduleScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(
                'Tambah Jadwal Baru',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 100), // padding for FAB
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String id,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String date,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE11D48),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black45, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                // Future edit feature
              } else if (value == 'delete') {
                final userId = context.read<UserProvider>().userId;
                context.read<ScheduleProvider>().deleteSchedule(id, userId);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // App Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final fotoProfil = userProvider.currentUser?.fotoProfil;
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          image: fotoProfil != null
                              ? DecorationImage(
                                  image: FileImage(File(fotoProfil)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: fotoProfil == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Consumer<UserProvider>(
                    builder: (context, userProvider, _) => Text(
                      userProvider.currentUser?.namaLengkap ?? 'My Wallet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A44F3),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showNotificationBottomSheet(context),
                child: const Icon(Icons.notifications_none, color: Color(0xFF3366FF)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Pengaturan',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Profile Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        final fotoProfil = userProvider.currentUser?.fotoProfil;
                        return Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                            image: fotoProfil != null
                                ? DecorationImage(
                                    image: FileImage(File(fotoProfil)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: fotoProfil == null
                              ? const Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3366FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) => Text(
                          userProvider.currentUser?.namaLengkap ?? 'Pengguna My Wallet',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) => Text(
                          userProvider.currentUser?.email ?? 'pengguna@fintrack.id',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Edit Profil',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3366FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('KEUANGAN'),
          _buildSettingsCard(
            children: [
              Consumer<UserProvider>(
                builder: (context, userProvider, _) => GestureDetector(
                  onTap: () => _showSetBudgetBottomSheet(context),
                  child: _buildSettingsItem(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: const Color(0xFF3366FF),
                    title: 'Batas Pengeluaran\nBulanan',
                    trailingValue: 'Rp\n${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(userProvider.batasBudget)}',
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              _buildSettingsItem(
                icon: Icons.monetization_on_outlined,
                iconColor: const Color(0xFF3366FF),
                title: 'Mata Uang',
                trailingValue: 'IDR',
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('KATEGORI'),
          _buildSettingsCard(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageCategoryScreen()),
                  );
                },
                child: _buildSettingsItem(
                  icon: Icons.category_outlined,
                  iconColor: const Color(0xFF3366FF),
                  title: 'Kelola Kategori',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('NOTIFIKASI'),
          _buildSettingsCard(
            children: [
              _buildSettingsItem(
                icon: Icons.notifications_active_outlined,
                iconColor: const Color(0xFF3366FF),
                title: 'Pengingat Jadwal',
                trailingWidget: Switch(
                  value: _isNotificationEnabled,
                  onChanged: (val) => _toggleNotification(val),
                  activeColor: const Color(0xFF3366FF),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              _buildSettingsItem(
                icon: Icons.access_time,
                iconColor: const Color(0xFF3366FF),
                title: 'Waktu Pengingat',
                trailingValue: '08:00',
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('DATA'),
          _buildSettingsCard(
            children: [
              GestureDetector(
                onTap: () => _exportData(context),
                child: _buildSettingsItem(
                  icon: Icons.file_download_outlined,
                  iconColor: const Color(0xFF3366FF),
                  title: 'Export Semua Data',
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              GestureDetector(
                onTap: () => _confirmDeleteAllData(context),
                child: _buildSettingsItem(
                  icon: Icons.delete_outline,
                  iconColor: const Color(0xFFE11D48),
                  title: 'Hapus Semua Data',
                  titleColor: const Color(0xFFE11D48),
                  hideChevron: true,
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              GestureDetector(
                onTap: () {
                  context.read<UserProvider>().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: _buildSettingsItem(
                  icon: Icons.logout,
                  iconColor: const Color(0xFFE11D48),
                  title: 'Logout',
                  titleColor: const Color(0xFFE11D48),
                  hideChevron: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showInitialBalanceBottomSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atur Saldo Awal',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal Saldo',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      final userId = context.read<UserProvider>().userId;
                      context.read<TransactionProvider>().addTransaction(
                        userId: userId,
                        tipeTrx: 'income',
                        kategoriId: 9, // using Gaji category approx
                        nominal: amount,
                        tanggalTrx: DateTime.now(),
                        catatan: 'Saldo Awal',
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Saldo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetBudgetBottomSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atur Batas Pengeluaran',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal Budget',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      context.read<UserProvider>().updateBudget(amount);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan Budget'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? trailingValue,
    Widget? trailingWidget,
    bool hideChevron = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: titleColor ?? Colors.black87,
              ),
            ),
          ),
          if (trailingValue != null) ...[
            Text(
              trailingValue,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (trailingWidget != null) ...[
            trailingWidget,
          ] else if (!hideChevron) ...[
            const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
          ],
        ],
      ),
    );
  }

  void _showNotificationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada notifikasi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context) {
    // Generate simple CSV logic
    final provider = context.read<TransactionProvider>();
    final transactions = provider.transactions;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport')),
      );
      return;
    }
    
    // In a real app, use path_provider and share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data berhasil disiapkan (CSV export segera hadir)')),
    );
  }

  void _confirmDeleteAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Semua Data?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus seluruh data profil, pengaturan, dan transaksi? Data tidak dapat dikembalikan.', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await context.read<UserProvider>().deleteAllData();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Donut Chart
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;

  DonutChartPainter(this.categories);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 24.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (categories.isEmpty) {
      paint.color = Colors.grey.shade200;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -pi / 2,
        2 * pi,
        false,
        paint,
      );
      return;
    }

    double startAngle = -pi / 2; // Start from top

    for (var cat in categories) {
      final sweepAngle = (cat['percent'] as double) * 2 * pi;
      paint.color = cat['barColor'] as Color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
