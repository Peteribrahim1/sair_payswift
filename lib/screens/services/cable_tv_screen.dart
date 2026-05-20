import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';

class CableTvScreen extends StatefulWidget {
  const CableTvScreen({Key? key}) : super(key: key);

  @override
  State<CableTvScreen> createState() => _CableTvScreenState();
}

class _CableTvScreenState extends State<CableTvScreen> {
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _loadingPlans = false;
  String? _selectedProvider;
  String? _verifiedName; // customer name from smart card verification

  // Cable TV plan selection
  List<Map<String, dynamic>> _cablePlans = [];
  Map<String, dynamic>? _selectedCablePlan;

  final _accountController =
      TextEditingController(); // smart card number
  final _phoneController = TextEditingController(); // contact phone

  final List<String> _cableProviders = ['DSTV', 'GOTV', 'StarTimes', 'Showmax'];

  @override
  void initState() {
    super.initState();
    _selectedProvider = _cableProviders.first;
    _loadCablePlans(_selectedProvider!);
  }

  @override
  void dispose() {
    _accountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─── Load cable plans ────────────────────────────────────────────────────

  Future<void> _loadCablePlans(String provider) async {
    setState(() {
      _loadingPlans = true;
      _cablePlans = [];
      _selectedCablePlan = null;
    });
    try {
      final plans = await ApiService.getCablePlans(provider);
      if (!mounted) return;
      setState(() {
        _cablePlans = plans
            .map<Map<String, dynamic>>((p) => {
                  'label': p['name'] ?? '',
                  'amount': double.tryParse(
                          p['variation_amount']?.toString() ?? '0') ??
                      0,
                  'code': p['variation_code'] ?? '',
                })
            .where((p) => (p['amount'] as double) > 0)
            .toList();
        if (_cablePlans.isNotEmpty) _selectedCablePlan = _cablePlans.first;
        _loadingPlans = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlans = false);
    }
  }

  // ─── Smart card verification ─────────────────────────────────────────────

  Future<void> _verifySmartCard() async {
    final cardNum = _accountController.text.trim();
    if (cardNum.isEmpty || _selectedProvider == null) return;

    setState(() {
      _isVerifying = true;
      _verifiedName = null;
    });
    try {
      final info = await ApiService.verifySmartCard(
        provider: _selectedProvider!,
        smartCardNumber: cardNum,
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
      _showError('Please enter your smart card / IUC number');
      return;
    }
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    if (_selectedCablePlan == null) {
      _showError('Please select a subscription plan');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await context.read<WalletProvider>().payCableTV(
            provider: _selectedProvider!,
            smartCardNumber: account,
            variationCode: _selectedCablePlan!['code'] as String,
            amount: _selectedCablePlan!['amount'] as double,
            phone: phone,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccess('${_selectedProvider} subscription activated!');
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
    AppSnackBar.showError(context, msg);
  }

  void _showSuccess(String msg) {
    AppSnackBar.showSuccess(context, msg);
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
                children: _cableProviders
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
                              _verifiedName = null;
                              _accountController.clear();
                              _selectedCablePlan = null;
                              _cablePlans = [];
                            });
                            Navigator.pop(context);
                            _loadCablePlans(p);
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

  void _showCablePlanPicker() {
    if (_loadingPlans || _cablePlans.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
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
            Text('Select Plan', style: AppTextStyles.subtitle),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: _cablePlans.length,
                itemBuilder: (_, i) {
                  final plan = _cablePlans[i];
                  final isSelected =
                      _selectedCablePlan?['code'] == plan['code'];
                  return ListTile(
                    title: Text(plan['label'].toString(),
                        style: AppTextStyles.body),
                    trailing: Text(
                      '₦${(plan['amount'] as double).toStringAsFixed(0)}',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark),
                    ),
                    leading: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primaryDark)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                    onTap: () {
                      setState(() => _selectedCablePlan = plan);
                      Navigator.pop(context);
                    },
                  );
                },
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
        title: Text('Cable TV',
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

            // Smart card
            CustomTextField(
              label: 'Smart Card / IUC Number',
              hint: 'Enter smart card number',
              controller: _accountController,
              keyboardType: TextInputType.number,
            ),

            // Smart card verification button
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isVerifying ? null : _verifySmartCard,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined, size: 16),
                  label: Text(_isVerifying ? 'Verifying...' : 'Verify Card',
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

            // Cable plan picker
            if (_selectedProvider != null) ...[
              const SizedBox(height: 16),
              Text('Subscription Plan',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showCablePlanPicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (_loadingPlans)
                        const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Expanded(
                          child: Text(
                            _selectedCablePlan != null
                                ? '${_selectedCablePlan!['label']}  •  ₦${(_selectedCablePlan!['amount'] as double).toStringAsFixed(0)}'
                                : 'Select a plan...',
                            style: _selectedCablePlan != null
                                ? AppTextStyles.body
                                : AppTextStyles.bodySecondary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],

            // Phone number
            const SizedBox(height: 16),
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
                        _selectedCablePlan != null
                                ? '₦${(_selectedCablePlan!['amount'] as double).toStringAsFixed(0)}'
                                : '₦0',
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
