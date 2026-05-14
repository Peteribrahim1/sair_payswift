import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/wallet_provider.dart';
import 'transaction_details_screen.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  String _humanizeType(String type) {
    switch (type) {
      case 'AIRTIME':
        return 'Buy Airtime';
      case 'DATA':
        return 'Buy Data';
      case 'BILL':
        return 'Pay Bill';
      case 'CONVERT_AIRTIME':
        return 'Convert Airtime';
      case 'FUND':
        return 'Wallet Top-up';
      default:
        return type;
    }
  }

  bool _isCredit(String type) =>
      type == 'CONVERT_AIRTIME' || type == 'FUND';

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction History',
          style: AppTextStyles.headlineLight.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final transactions = wallet.transactions;

          if (wallet.isLoading && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No transactions yet', style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  Text(
                    'Your transaction history will appear here',
                    style: AppTextStyles.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Compute summary stats
          final totalDebit = transactions
              .where((t) => !_isCredit(t['type'] ?? ''))
              .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));
          final totalCredit = transactions
              .where((t) => _isCredit(t['type'] ?? ''))
              .fold<double>(0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length + 1, // +1 for summary header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummaryHeader(context, transactions.length, totalCredit, totalDebit);
              }
              final tx = transactions[index - 1];
              return _buildTransactionCard(context, tx);
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(
      BuildContext context, int count, double credit, double debit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.secondaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count Transaction${count == 1 ? '' : 's'}',
            style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryChip(
                  label: 'Total In',
                  amount: '+₦${credit.toStringAsFixed(2)}',
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryChip(
                  label: 'Total Out',
                  amount: '-₦${debit.toStringAsFixed(2)}',
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 2),
                Text(amount,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, dynamic transaction) {
    final type = transaction['type'] ?? 'UNKNOWN';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final date = DateTime.tryParse(transaction['createdAt'] ?? '') ?? DateTime.now();
    final credit = _isCredit(type);
    final label = _humanizeType(type);

    IconData icon;
    Color color;
    switch (type) {
      case 'DATA':
        icon = Icons.wifi;
        color = AppColors.gloGreen;
        break;
      case 'AIRTIME':
        icon = Icons.phone_android;
        color = AppColors.mtnYellow;
        break;
      case 'BILL':
        icon = Icons.lightbulb_outline;
        color = Colors.orange;
        break;
      case 'CONVERT_AIRTIME':
        icon = Icons.import_export;
        color = Colors.green;
        break;
      case 'FUND':
        icon = Icons.account_balance_wallet;
        color = Colors.green;
        break;
      default:
        icon = Icons.receipt_long;
        color = AppColors.primaryDark;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _relativeTime(date),
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${credit ? '+' : '-'}₦${amount.toStringAsFixed(2)}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: credit ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
