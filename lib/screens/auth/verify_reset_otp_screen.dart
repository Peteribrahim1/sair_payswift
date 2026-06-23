import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../services/api_service.dart';
import 'reset_password_screen.dart';

class VerifyResetOtpScreen extends StatefulWidget {
  final String email;

  const VerifyResetOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyResetOtpScreen> createState() => _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends State<VerifyResetOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      AppSnackBar.showError(context, 'Please enter a valid 4-digit OTP');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.verifyResetOtp(widget.email, otp);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.email, otp: otp),
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
    _otpController.dispose();
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
              Text('Enter Reset Code', style: AppTextStyles.headline1),
              const SizedBox(height: 8),
              Text(
                'We sent a 4-digit code to ${widget.email}. Enter it below to proceed.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _otpController,
                label: 'OTP Code',
                hint: '0000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.lock_clock_outlined,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Verify Code',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
