import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({Key? key}) : super(key: key);

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _selectedProvider;
  String? _verifiedName;
  String _meterType = 'prepaid';

  final _accountController = TextEditingController(); // meter number
  final _amountController = TextEditingController(); // amount
  final _phoneController = TextEditingController(); // contact phone

  final List<String> _electricityProviders = [
    'Jos Electricity (JED)',
    'Eko Electricity (EKEDC)',
    'Ikeja Electricity (IKEDC)',
    'Kano Electricity (KEDCO)',
    'Port Harcourt (PHED)',
    'Abuja Electricity (AEDC)',
    'Ibadan Electricity (IBEDC)',
    'Enugu Electricity (EEDC)',
    'Kaduna Electricity (KAEDCO)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedProvider = _electricityProviders.first;
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─── Meter verification ───────────────────────────────────────────────────

  Future<void> _verifyMeter() async {
    final meterNum = _accountController.text.trim();
    if (meterNum.isEmpty || _selectedProvider == null) return;

    setState(() {
      _isVerifying = true;
      _verifiedName = null;
    });
    try {
      final info = await ApiService.verifyMeter(
        provider: _selectedProvider!,
        meterNumber: meterNum,
      );
      if (!mounted) return;
      final name = info['info']?['Customer_Name'] ??
          info['info']?['name'] ??
          info['Customer_Name'] ??
          '';
      setState(() {
        _verifiedName = name.toString().isNotEmpty ? name.toString() : null;
        _isVerifying = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
    }
  }

  // ─── Payment handler ─────────────────────────────────────────────────────

  void _handlePayment() async {
    final account = _accountController.text.trim();
    final phone = _phoneController.text.trim();

    if (account.isEmpty) {
      _showError('Please enter your meter number');
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 500) {
      _showError('Minimum electricity payment is ₦500');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await context.read<WalletProvider>().payElectricity(
            provider: _selectedProvider!,
            meterNumber: account,
            meterType: _meterType,
            amount: amount,
            phone: phone,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccess('₦${amount.toStringAsFixed(0)} electricity payment successful!');
        Navigator.pop(context);
      } else {
        _showError(result['error'] ?? 'Payment failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showProviderPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        maxChildSize: 0.7,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Text('Select Provider', style: AppTextStyles.subtitle),
            const Divider(),
            Expanded(
              child: ListView(
                controller: ctrl,
                children: _electricityProviders
                    .map((p) => ListTile(
                          title: Text(p, style: AppTextStyles.body),
                          leading: _selectedProvider == p
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primaryDark)
                              : const Icon(Icons.circle_outlined,
                                  color: Colors.grey),
                          onTap: () {
                            setState(() {
                              _selectedProvider = p;
                              _accountController.clear();
                              _verifiedName = null;
                            });
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
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
        title: Text('Electricity',
            style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider selector
            Text('Select Provider', style: AppTextStyles.subtitle),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showProviderPicker,
              child: _buildDropdown(_selectedProvider ?? 'Choose a provider'),
            ),
            const SizedBox(height: 16),

            // Meter number
            CustomTextField(
              label: 'Meter Number',
              hint: 'Enter meter number',
              controller: _accountController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                if (_verifiedName != null) {
                  setState(() => _verifiedName = null);
                }
              },
            ),

            // Meter verification button
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isVerifying ? null : _verifyMeter,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined, size: 16),
                  label: Text(_isVerifying ? 'Verifying...' : 'Verify Meter',
                      style: const TextStyle(fontSize: 13)),
                ),
                if (_verifiedName != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '✓ $_verifiedName',
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 16),

            // Meter type toggle
            Text('Meter Type',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMeterTypeChip('prepaid', 'Prepaid'),
                const SizedBox(width: 12),
                _buildMeterTypeChip('postpaid', 'Postpaid'),
              ],
            ),
            const SizedBox(height: 16),

            // Amount
            CustomTextField(
              label: 'Amount (₦)',
              hint: 'Min. ₦500',
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),

            // Phone number
            CustomTextField(
              label: 'Contact Phone Number',
              hint: '08012345678',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),
            // VTPass indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  'Powered by VTPass — Real payment processing',
                  style: AppTextStyles.bodySecondary
                      .copyWith(color: Colors.green.shade700, fontSize: 12),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Pay button bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Amount',
                          style: AppTextStyles.bodySecondary
                              .copyWith(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        '₦${_amountController.text.isEmpty ? '0' : _amountController.text}',
                        style: AppTextStyles.headline1
                            .copyWith(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _handlePayment,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: AppColors.primaryDark, strokeWidth: 2),
                          )
                        : const Text('Pay Now',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeterTypeChip(String value, String label) {
    final isSelected = _meterType == value;
    return GestureDetector(
      onTap: () => setState(() => _meterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primaryDark : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(hint,
                style: AppTextStyles.bodySecondary,
                overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    );
  }
}
