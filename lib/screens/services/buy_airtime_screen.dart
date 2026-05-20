import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/wallet_provider.dart';

class BuyAirtimeScreen extends StatefulWidget {
  const BuyAirtimeScreen({Key? key}) : super(key: key);

  @override
  State<BuyAirtimeScreen> createState() => _BuyAirtimeScreenState();
}

class _BuyAirtimeScreenState extends State<BuyAirtimeScreen> {
  bool _isLoading = false;
  int _selectedNetwork = 0;
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  final List<Map<String, dynamic>> _networks = [
    {'name': 'MTN', 'color': AppColors.mtnYellow},
    {'name': 'Airtel', 'color': AppColors.airtelRed},
    {'name': 'Glo', 'color': AppColors.gloGreen},
    {'name': '9mobile', 'color': AppColors.nineMobileGreen},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _selectedNetworkName => _networks[_selectedNetwork]['name'] as String;

  void _handlePurchase() async {
    final phone = _phoneController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }
    if (amount == null || amount < 50) {
      _showError('Minimum airtime amount is ₦50');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await context.read<WalletProvider>().buyAirtime(
            network: _selectedNetworkName,
            phone: phone,
            amount: amount,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccess('₦${amount.toStringAsFixed(0)} $_selectedNetworkName airtime sent to $phone!');
        Navigator.pop(context);
      } else {
        _showError(result['error'] ?? 'Airtime purchase failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showError(msg);
    }
  }

  void _showError(String msg) {
    AppSnackBar.showError(context, msg);
  }

  void _showSuccess(String msg) {
    AppSnackBar.showSuccess(context, msg);
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
        title: Text('Buy Airtime',
            style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Network', style: AppTextStyles.subtitle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_networks.length, (index) {
                final net = _networks[index];
                return _buildNetworkLogo(
                    net['name'] as String, net['color'] as Color, index);
              }),
            ),
            const SizedBox(height: 24),
            _buildLabeledField(
              label: 'Phone Number',
              hint: '08012345678',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildLabeledField(
              label: 'Amount (₦)',
              hint: 'e.g. 500',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixText: '₦  ',
            ),
            const SizedBox(height: 12),
            // Quick amount chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [100, 200, 500, 1000, 2000].map((amt) {
                return ActionChip(
                  label: Text('₦$amt'),
                  onPressed: () => setState(
                      () => _amountController.text = amt.toString()),
                  backgroundColor: (_networks[_selectedNetwork]['color'] as Color)
                      .withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: _networks[_selectedNetwork]['color'] as Color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 36),
            // Live indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Powered by VTPass — Real airtime delivery',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _handlePurchase,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Buy Now', style: AppTextStyles.button),
              ),
            )
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
          color: isSelected ? color : color.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.45), blurRadius: 10, spreadRadius: 1)]
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

  Widget _buildLabeledField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
