import 'package:flutter/material.dart';
import '../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';

class BuyDataScreen extends StatefulWidget {
  const BuyDataScreen({Key? key}) : super(key: key);

  @override
  State<BuyDataScreen> createState() => _BuyDataScreenState();
}

class _BuyDataScreenState extends State<BuyDataScreen> {
  bool _isLoading = false;
  bool _loadingPlans = false;
  int _selectedNetworkIndex = 0;
  Map<String, dynamic>? _selectedPlan;
  final _phoneController = TextEditingController();

  final List<Map<String, dynamic>> _networks = [
    {'name': 'MTN', 'color': AppColors.mtnYellow},
    {'name': 'Airtel', 'color': AppColors.airtelRed},
    {'name': 'Glo', 'color': AppColors.gloGreen},
    {'name': '9mobile', 'color': AppColors.nineMobileGreen},
  ];

  List<Map<String, dynamic>> _dataPlans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans('MTN');
  }

  String get _selectedNetworkName => _networks[_selectedNetworkIndex]['name'] as String;

  Future<void> _loadPlans(String network) async {
    setState(() {
      _loadingPlans = true;
      _dataPlans = [];
      _selectedPlan = null;
    });
    try {
      final plans = await ApiService.getDataPlans(network);
      if (!mounted) return;
      setState(() {
        _dataPlans = plans
            .map<Map<String, dynamic>>((p) => {
                  'label': p['name'] ?? p['variation_amount'] ?? '',
                  'amount': double.tryParse(p['variation_amount']?.toString() ?? '0') ?? 0,
                  'code': p['variation_code'] ?? '',
                })
            .where((p) => p['amount'] > 0)
            .toList();
        if (_dataPlans.isNotEmpty) _selectedPlan = _dataPlans.first;
        _loadingPlans = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPlans = false);
      _showError('Could not load data plans. Check your connection.');
    }
  }

  void _handlePurchase() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }
    if (_selectedPlan == null) {
      _showError('Please select a data plan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await context.read<WalletProvider>().buyData(
            network: _selectedNetworkName,
            phone: phone,
            variationCode: _selectedPlan!['code'] as String,
            amount: _selectedPlan!['amount'] as double,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccess('${_selectedPlan!['label']} sent to $phone!');
        Navigator.pop(context);
      } else {
        _showError(result['error'] ?? 'Data purchase failed');
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

  void _showPlanPicker() {
    if (_loadingPlans) return;
    if (_dataPlans.isEmpty) {
      _showError('No plans available. Try refreshing.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text('Select Data Plan', style: AppTextStyles.subtitle),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: _dataPlans.length,
                  itemBuilder: (context, i) {
                    final plan = _dataPlans[i];
                    final isSelected = _selectedPlan?['code'] == plan['code'];
                    return ListTile(
                      title: Text(plan['label'].toString(),
                          style: AppTextStyles.body),
                      trailing: Text(
                        '₦${(plan['amount'] as double).toStringAsFixed(0)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _networks[_selectedNetworkIndex]['color'] as Color,
                        ),
                      ),
                      leading: isSelected
                          ? Icon(Icons.check_circle,
                              color: _networks[_selectedNetworkIndex]['color'] as Color)
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                      onTap: () {
                        setState(() => _selectedPlan = plan);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final networkColor = _networks[_selectedNetworkIndex]['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Buy Data',
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
            CustomTextField(
              label: 'Phone Number',
              hint: '08012345678',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            // Plan picker
            Text('Data Plan',
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showPlanPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Expanded(
                        child: Text(
                          _selectedPlan != null
                              ? '${_selectedPlan!['label']}  •  ₦${(_selectedPlan!['amount'] as double).toStringAsFixed(0)}'
                              : 'Select a plan...',
                          style: _selectedPlan != null
                              ? AppTextStyles.body
                              : AppTextStyles.bodySecondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Amount display
            if (_selectedPlan != null) ...[
              Text('Amount',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: networkColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: networkColor.withOpacity(0.3)),
                ),
                child: Text(
                  '₦ ${(_selectedPlan!['amount'] as double).toStringAsFixed(0)}',
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold, color: networkColor),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // VTPass live indicator
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
                        color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live plans from VTPass — Real data delivery',
                    style: AppTextStyles.bodySecondary.copyWith(
                        color: Colors.green.shade700, fontSize: 12),
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
                onPressed: _isLoading || _loadingPlans ? null : _handlePurchase,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Buy Now', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkLogo(String name, Color color, int index) {
    bool isSelected = _selectedNetworkIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNetworkIndex = index);
        _loadPlans(name);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10)]
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
