import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../profile/help_support_screen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsScreen({Key? key, required this.transaction})
      : super(key: key);

  String _humanizeType(String type) {
    switch (type) {
      case 'AIRTIME':        return 'Buy Airtime';
      case 'DATA':           return 'Buy Data';
      case 'BILL':           return 'Pay Bill';
      case 'ELECTRICITY':    return 'Electricity Bill';
      case 'CABLE_TV':       return 'Cable TV';
      case 'CONVERT_AIRTIME':return 'Convert Airtime';
      case 'FUND':           return 'Wallet Top-up';
      case 'WITHDRAW':       return 'Withdrawal';
      default:               return type;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'AIRTIME':        return Icons.phone_android;
      case 'DATA':           return Icons.wifi;
      case 'ELECTRICITY':    return Icons.bolt;
      case 'CABLE_TV':       return Icons.tv;
      case 'CONVERT_AIRTIME':return Icons.swap_horiz;
      case 'FUND':           return Icons.account_balance_wallet;
      case 'WITHDRAW':       return Icons.account_balance;
      default:               return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'] ?? 'UNKNOWN';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
    final date = DateTime.tryParse(transaction['createdAt'] ?? '') ?? DateTime.now();
    final isCredit = type == 'CONVERT_AIRTIME' || type == 'FUND';

    // New VTPass metadata fields
    final phone     = transaction['phone'] as String?;
    final network   = transaction['network'] as String?;
    final reference = transaction['reference'] as String?;

    // Fallback ref display
    final String displayRef = reference != null && reference.isNotEmpty
        ? reference
        : (transaction['id']?.toString().toUpperCase().substring(0, 12) ?? 'N/A');

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaction Receipt',
            style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconForType(type),
                        color: Colors.green, size: 40),
                  ),
                  const SizedBox(height: 12),

                  Text('Transaction Successful',
                      style: AppTextStyles.subtitle.copyWith(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Text(
                    '${isCredit ? '+' : '-'} ₦${amount.toStringAsFixed(2)}',
                    style: AppTextStyles.headlineDark.copyWith(
                        fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 28),

                  // Dashed divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        60,
                        (i) => Expanded(
                          child: Container(
                            color: i % 2 == 0
                                ? Colors.transparent
                                : Colors.grey.shade300,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Core details
                  _buildRow('Transaction Type', _humanizeType(type)),
                  _buildRow('Date',
                      '${date.day}/${date.month}/${date.year}'),
                  _buildRow('Time',
                      '${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                  _buildRow('Payment Method', 'Wallet'),

                  // Conditional VTPass metadata
                  if (phone != null && phone.isNotEmpty)
                    _buildRow('Recipient Phone', phone),
                  if (network != null && network.isNotEmpty)
                    _buildRow('Network / Provider', network),
                  if (reference != null && reference.isNotEmpty)
                    _buildRow('VTPass Ref', reference,
                        valueStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace'),
                        copyable: true,
                        context: context),

                  _buildRow('Transaction ID', displayRef,
                      copyable: true,
                      context: context),
                  _buildRow('Status', 'Completed', isStatus: true),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HelpSupportScreen(
                            prefilledSubject: 'Issue with Transaction #$displayRef',
                          ),
                        ),
                      );
                    },
                    child: Text('Need help with this transaction?',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isStatus = false, TextStyle? valueStyle, bool copyable = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
          const SizedBox(width: 16),
          if (isStatus)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
          else
            Flexible(
              child: copyable && context != null
                  ? InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$label copied to clipboard!'),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(value,
                                  textAlign: TextAlign.right,
                                  style: valueStyle ??
                                      AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    )
                  : Text(value,
                      textAlign: TextAlign.right,
                      style: valueStyle ??
                          AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
