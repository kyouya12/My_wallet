import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_provider.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Semua Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.transactions.isEmpty) {
            return Center(
              child: Text(
                'Belum ada transaksi',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              final trx = provider.transactions[index];
              final isPemasukan = trx.tipeTrx == 'income';
              
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

              return Dismissible(
                key: Key(trx.trxId ?? index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
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
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                              trx.catatan?.isNotEmpty == true ? trx.catatan! : (trx.category?.namaKategori ?? 'Lainnya'),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(trx.tanggalTrx),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isPemasukan ? '+' : '-'}Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(trx.nominal)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPemasukan ? const Color(0xFF10B981) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
