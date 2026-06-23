import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../services/api_service.dart';
import 'verify_reset_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _sendResetOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppSnackBar.showError(context, 'Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.forgotPassword(email);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Password reset OTP sent!');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyResetOtpScreen(email: email),
          ),
        );
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
    _emailController.dispose();
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
              Text('Forgot Password', style: AppTextStyles.headline1),
              const SizedBox(height: 8),
              Text(
                'Enter your registered email address to receive a password reset OTP.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'johndoe@email.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Send Reset Code',
                onPressed: _sendResetOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
