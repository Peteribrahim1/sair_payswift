import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({Key? key, required this.email, required this.otp})
      : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  void _resetPassword() async {
    final newPassword = _passwordController.text;
    if (newPassword.length < 6) {
      AppSnackBar.showError(context, 'Password must be at least 6 characters');
      return;
    }
    if (newPassword != _confirmController.text) {
      AppSnackBar.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.resetPassword(widget.email, widget.otp, newPassword);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Password successfully reset!');
        // Go back to login screen, clearing the stack
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Password', style: AppTextStyles.headline1),
              const SizedBox(height: 8),
              Text(
                'Your new password must be different from your previous used passwords.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _passwordController,
                label: 'New Password',
                hint: 'Enter new password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmController,
                label: 'Confirm Password',
                hint: 'Re-enter new password',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Reset Password',
                onPressed: _resetPassword,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
