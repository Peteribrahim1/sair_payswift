import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/wallet_provider.dart';

class ConvertAirtimeScreen extends StatefulWidget {
  const ConvertAirtimeScreen({Key? key}) : super(key: key);

  @override
  State<ConvertAirtimeScreen> createState() => _ConvertAirtimeScreenState();
}

class _ConvertAirtimeScreenState extends State<ConvertAirtimeScreen> {
  bool _isLoading = false;
  int _selectedNetwork = 0;
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  static const double _conversionRate = 0.70; // 70% payout

  final List<Map<String, dynamic>> _networks = [
    {'name': 'MTN', 'color': AppColors.mtnYellow},
    {'name': 'Airtel', 'color': AppColors.airtelRed},
    {'name': 'Glo', 'color': AppColors.gloGreen},
    {'name': '9mobile', 'color': AppColors.nineMobileGreen},
  ];

  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  double get _payout => _enteredAmount * _conversionRate;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleConversion() async {
    final phone = _phoneController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }
    if (amount == null || amount < 100) {
      _showError('Minimum conversion amount is ₦100');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // CONVERT_AIRTIME is a credit operation — adds payout to wallet
      final success = await context
          .read<WalletProvider>()
          .processTransaction(_payout, type: 'CONVERT_AIRTIME');

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _showSuccessDialog(amount, _payout);
      } else {
        _showError('Conversion failed. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    AppSnackBar.showError(context, msg);
  }

  void _showSuccessDialog(double sent, double received) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            Text('Conversion Successful!', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            Text(
              '₦${received.toStringAsFixed(2)} has been added to your wallet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close screen
                },
                child: const Text('Done',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
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
        title: Text('Convert Airtime to Cash',
            style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryDark.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: AppColors.primaryDark.withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transfer airtime from your phone to your wallet. Rate: 70% payout.',
                      style: AppTextStyles.bodySecondary
                          .copyWith(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Select Network', style: AppTextStyles.subtitle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                _networks.length,
                (i) => _buildNetworkLogo(
                    _networks[i]['name'] as String,
                    _networks[i]['color'] as Color,
                    i),
              ),
            ),
            const SizedBox(height: 24),

            // Phone number
            Text('Your Phone Number',
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '08012345678',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Amount to convert
            Text('Airtime Amount (₦)',
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 1000',
                prefixText: '₦  ',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Payout preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You will receive (70%)',
                          style: AppTextStyles.bodySecondary
                              .copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '₦ ${_payout.toStringAsFixed(2)}',
                        style: AppTextStyles.headlineDark.copyWith(
                            fontSize: 22, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rate', style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('30% fee',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _handleConversion,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Convert Now', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkLogo(String name, Color color, int index) {
    final isSelected = _selectedNetwork == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNetwork = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Colors.white, width: 2.5)
              : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          name,
          style: AppTextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
