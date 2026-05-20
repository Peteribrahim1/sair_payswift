import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({Key? key}) : super(key: key);

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  void _showAddAccountSheet() {
    final accountController = TextEditingController();
    
    // Map of popular Nigerian banks to their Paystack bank codes
    final banks = {
      'Access Bank': '044',
      'GTBank': '058',
      'Zenith Bank': '057',
      'UBA': '033',
      'First Bank': '011',
      'Kuda Bank': '50211',
      'Opay': '999992',
      'Palmpay': '999991',
    };
    
    String selectedBankName = 'Access Bank';
    String selectedBankCode = '044';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text('Link Bank Account', style: AppTextStyles.subtitle.copyWith(fontSize: 20)),
                    const SizedBox(height: 24),
                    Text('Select Bank', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBankName,
                          isExpanded: true,
                          items: banks.keys.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                          onChanged: (val) {
                            setSheetState(() {
                              selectedBankName = val!;
                              selectedBankCode = banks[val]!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Account Number',
                      hint: '10 digits',
                      controller: accountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    Text('We will securely verify this account before linking.', style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isLoading ? null : () async {
                          if (accountController.text.length < 10) return;
                          setSheetState(() => isLoading = true);
                          
                          try {
                            await context.read<WalletProvider>().addBankAccount(
                              selectedBankName, 
                              selectedBankCode, 
                              accountController.text,
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            AppSnackBar.showSuccess(context, 'Bank account linked successfully!');
                          } catch (e) {
                            if (!mounted) return;
                            AppSnackBar.showError(context, e.toString().replaceAll('Exception: ', ''));
                          } finally {
                            if (mounted) {
                              setSheetState(() => isLoading = false);
                            }
                          }
                        },
                        child: isLoading 
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Verify & Link Account', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bank Accounts', style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddAccountSheet,
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final accounts = wallet.bankAccounts;
          return accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No accounts linked', style: AppTextStyles.subtitle),
                      const SizedBox(height: 8),
                      Text('Add a bank account to enable withdrawals', style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _showAddAccountSheet,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                        child: const Text('Add Account', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final acc = accounts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryDark.withOpacity(0.1),
                      child: Text(acc['logo']!, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(acc['bank']!, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(acc['number']!, style: AppTextStyles.bodySecondary),
                        Text(acc['name']!, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => context.read<WalletProvider>().removeBankAccount(acc['id']!),
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
