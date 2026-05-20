import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/wallet_provider.dart';
import '../profile/bank_accounts_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  Map<String, String>? _selectedAccount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = context.read<WalletProvider>().bankAccounts;
      if (accounts.isNotEmpty) {
        setState(() {
          _selectedAccount = accounts.first;
        });
      }
    });
  }

  void _processWithdrawal() async {
    final rawAmount = _amountController.text.trim();
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      AppSnackBar.showError(context, 'Please enter a valid amount');
      return;
    }

    if (_selectedAccount == null) {
      AppSnackBar.showError(context, 'Please select a bank account');
      return;
    }

    final wallet = context.read<WalletProvider>();
    if (amount > wallet.balance) {
      AppSnackBar.showError(context, 'Insufficient wallet balance');
      return;
    }

    setState(() => _isLoading = true);

    final success = await wallet.processWithdrawal(amount, _selectedAccount!);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                Text('Withdrawal Successful', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Text(
                  '₦${amount.toStringAsFixed(2)} has been sent to your ${_selectedAccount!['bank']} account.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close screen
                    },
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        AppSnackBar.showError(context, 'Withdrawal failed. Please try again.');
      }
    }
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
        title: Text('Withdraw Funds', style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryDark.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text('Available Balance', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 8),
                      Text(
                        '₦${wallet.balance.toStringAsFixed(2)}',
                        style: AppTextStyles.headlineDark.copyWith(fontSize: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Amount Input
                Text('Amount to Withdraw', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.headlineDark.copyWith(fontSize: 24),
                  decoration: InputDecoration(
                    prefixText: '₦ ',
                    prefixStyle: AppTextStyles.headlineDark.copyWith(fontSize: 24),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 24),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryDark),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
                const SizedBox(height: 32),

                // Bank Account Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transfer To', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BankAccountsScreen()),
                        ).then((_) {
                          // refresh selected account in case they added/deleted
                          setState(() {
                            final accounts = context.read<WalletProvider>().bankAccounts;
                            if (accounts.isNotEmpty && !accounts.contains(_selectedAccount)) {
                              _selectedAccount = accounts.first;
                            } else if (accounts.isEmpty) {
                              _selectedAccount = null;
                            }
                          });
                        });
                      },
                      child: Text('Manage', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (wallet.bankAccounts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No Bank Account Linked', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BankAccountsScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                          child: const Text('Add Account', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, String>>(
                        value: _selectedAccount,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: wallet.bankAccounts.map((account) {
                          return DropdownMenuItem<Map<String, String>>(
                            value: account,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primaryDark.withOpacity(0.1),
                                  child: Text(account['logo']!, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(account['bank']!, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                    Text(account['number']!, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccount = value;
                          });
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 48),

                // Withdraw Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading || wallet.bankAccounts.isEmpty ? null : _processWithdrawal,
                    child: _isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Withdraw', style: AppTextStyles.button),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
