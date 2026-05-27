import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../history/transaction_history_screen.dart';
import 'bank_accounts_screen.dart';
import 'help_support_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  String _getDisplayName(String email, String fullName) {
    if (fullName.isNotEmpty) return fullName;
    if (email.isEmpty) return 'PaySwift User';
    final parts = email.split('@');
    final namePart = parts[0].replaceAll(RegExp(r'[._]'), ' ');
    return namePart.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  String _getInitials(String email, String fullName) {
    final name = _getDisplayName(email, fullName);
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'P';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, WalletProvider>(
      builder: (context, themeProvider, wallet, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            title: Text('Profile',
                style: AppTextStyles.headlineLight.copyWith(fontSize: 20)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: wallet.profilePicture.isNotEmpty ? null : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primaryDark, AppColors.buttonColor],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: wallet.profilePicture.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.network(
                                  '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/${wallet.profilePicture}',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      _getInitials(wallet.email, wallet.fullName),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Text(
                                _getInitials(wallet.email, wallet.fullName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getDisplayName(wallet.email, wallet.fullName), style: AppTextStyles.subtitle),
                            const SizedBox(height: 4),
                            Text(
                              wallet.phone.isNotEmpty ? wallet.phone : (wallet.email.isEmpty ? 'Loading...' : wallet.email),
                              style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.buttonColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.buttonColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet, size: 13, color: AppColors.buttonColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    '₦${wallet.balance.toStringAsFixed(2)}',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 12,
                                      color: AppColors.buttonColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.buttonColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(
                    children: [
                      _buildListTile(
                          context, 'Transaction History', Icons.history),
                      const Divider(height: 1),
                      _buildListTile(
                          context, 'Bank Accounts', Icons.account_balance),
                      const Divider(height: 1),
                      _buildListTile(
                          context, 'Help & Support', Icons.support_agent),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text('Dark Mode',
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w600)),
                        secondary: Icon(Icons.dark_mode,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : AppColors.primaryDark),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                        activeColor: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ApiService.clearToken();
                      context.read<WalletProvider>().clearData();
                      Navigator.of(context, rootNavigator: true)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: Text('Log Out', style: AppTextStyles.button),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTile(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.primaryDark),
      title: Text(title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        if (title == 'Transaction History') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TransactionHistoryScreen()),
          );
        } else if (title == 'Bank Accounts') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BankAccountsScreen()),
          );
        } else if (title == 'Help & Support') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const HelpSupportScreen()),
          );
        }
      },
    );
  }
}
