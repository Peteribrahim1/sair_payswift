import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade300,
                        child: const Icon(Icons.person,
                            size: 30, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ibrahim Peter', style: AppTextStyles.subtitle),
                          const SizedBox(height: 4),
                          Text('peteribrahim@gmail.com',
                              style: AppTextStyles.bodySecondary
                                  .copyWith(fontSize: 12)),
                        ],
                      )
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
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
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
      onTap: () {},
    );
  }
}
