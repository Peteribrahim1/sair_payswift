import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/wallet_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

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
        title: Text('Notifications', style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _buildNotificationItem(context, tx);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, dynamic transaction) {
    final type = transaction['type'] ?? 'UNKNOWN';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    
    // We use a mock message based on the type
    String message;
    IconData icon;
    Color color;

    switch (type) {
      case 'DATA':
        message = 'Your data purchase of ₦${amount.toStringAsFixed(2)} was successful.';
        icon = Icons.wifi;
        color = AppColors.gloGreen;
        break;
      case 'AIRTIME':
        message = 'Your airtime purchase of ₦${amount.toStringAsFixed(2)} was successful.';
        icon = Icons.phone_android;
        color = AppColors.mtnYellow;
        break;
      case 'CONVERT_AIRTIME':
        message = 'You successfully converted ₦${amount.toStringAsFixed(2)} airtime to cash.';
        icon = Icons.account_balance_wallet;
        color = Colors.blue;
        break;
      case 'BILL':
        message = 'Your bill payment of ₦${amount.toStringAsFixed(2)} was successfully processed.';
        icon = Icons.lightbulb_outline;
        color = Colors.orange;
        break;
      default:
        message = 'A transaction of ₦${amount.toStringAsFixed(2)} was processed.';
        icon = Icons.receipt_long;
        color = AppColors.primaryDark;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                _relativeTime(transaction['createdAt']),
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _relativeTime(String? isoDate) {
    if (isoDate == null) return 'Just now';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Just now';
    }
  }
}
