import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../navigation/main_navigation.dart';
import '../../services/api_service.dart';
import '../../providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      AppSnackBar.showError(context, 'Please fill all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      AppSnackBar.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    try {
      final response = await ApiService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        fullName,
        _phoneController.text.trim(),
      );
      
      // Save Token
      ApiService.setToken(response['token']);
      
      // Fetch initial profile
      if (mounted) {
        await Provider.of<WalletProvider>(context, listen: false).fetchProfile();
      }

      if (mounted) {
         // Clear the navigation stack entirely and push MainNavigation
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Registration Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false, // Extend gradient behind status bar
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Beautiful Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.secondaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Create Account',
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Sair to start managing your payments.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Elevated Form Card
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        hint: 'John',
                        keyboardType: TextInputType.name,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        hint: 'Doe',
                        keyboardType: TextInputType.name,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '08012345678',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'johndoe@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a Password',
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your Password',
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: 'Sign Up',
                        onPressed: _register,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Bottom Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    'Already have an account?',
                    style: AppTextStyles.bodySecondary,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Log in',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
