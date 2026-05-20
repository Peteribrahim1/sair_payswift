import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/wallet_provider.dart';
import '../../core/widgets/custom_text_field.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final wallet = context.read<WalletProvider>();
    _nameController = TextEditingController(text: wallet.fullName);
    _phoneController = TextEditingController(text: wallet.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final wallet = context.read<WalletProvider>();
    final success = await wallet.updateProfile(_nameController.text.trim(), _phoneController.text.trim());
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Profile updated successfully');
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to update profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Text('Edit Profile', style: AppTextStyles.headlineLight.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Save Changes', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
