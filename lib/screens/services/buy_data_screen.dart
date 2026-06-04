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
  int _selectedCategoryIndex = 0;
  Map<String, dynamic>? _selectedPlan;
  final _phoneController = TextEditingController();

  final List<Map<String, dynamic>> _networks = [
    {'name': 'MTN', 'color': AppColors.mtnYellow},
    {'name': 'Airtel', 'color': AppColors.airtelRed},
    {'name': 'Glo', 'color': AppColors.gloGreen},
    {'name': '9mobile', 'color': AppColors.nineMobileGreen},
  ];

  bool _isSmeSelected = true;
  final List<String> _categories = ['Daily', 'Weekly', 'Monthly', 'Mega'];
  Map<String, List<Map<String, dynamic>>> _categorizedPlans = {
    'Daily': [],
    'Weekly': [],
    'Monthly': [],
    'Mega': [],
  };

  List<Map<String, dynamic>> _smePlans = [];
  List<Map<String, dynamic>> _dataPlans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans('MTN');
  }

  String get _selectedNetworkName => _networks[_selectedNetworkIndex]['name'] as String;

  String _categorizePlan(String name) {
    final lowerName = name.toLowerCase().replaceAll(' ', ''); // remove spaces for easier matching
    if (lowerName.contains('year') ||
        lowerName.contains('2month') ||
        lowerName.contains('3month') ||
        lowerName.contains('6month') ||
        lowerName.contains('12month') ||
        lowerName.contains('tb') ||
        lowerName.contains('mega')) {
      return 'Mega';
    }
    if (lowerName.contains('30day') || lowerName.contains('month')) {
      return 'Monthly';
    }
    if (lowerName.contains('7day') || lowerName.contains('14day') || lowerName.contains('week')) {
      return 'Weekly';
    }
    if (lowerName.contains('day') || lowerName.contains('hr') || lowerName.contains('hour')) {
      return 'Daily';
    }
    return 'Mega';
  }

  Future<void> _loadPlans(String network) async {
    setState(() {
      _loadingPlans = true;
      _dataPlans = [];
      _smePlans = [];
      _categorizedPlans = {'Daily': [], 'Weekly': [], 'Monthly': [], 'Mega': []};
      _selectedPlan = null;
    });
    try {
      // Fetch both VTPass and SMEPlug plans in parallel
      final results = await Future.wait([
        ApiService.getDataPlans(network),
        ApiService.fetchSmeDataPlans(network).catchError((_) => <String, dynamic>{'success': false, 'plans': []}),
      ]);

      final vtpassPlans = results[0] as List<dynamic>;
      final smeResponse = results[1] as Map<String, dynamic>;
      final smePlans = (smeResponse['success'] == true && smeResponse['plans'] != null)
          ? smeResponse['plans'] as List<dynamic>
          : [];

      if (!mounted) return;
      setState(() {
        // Map VTPass plans
        final standardPlans = vtpassPlans
            .map<Map<String, dynamic>>((p) => {
                  'label': p['name'] ?? p['variation_amount'] ?? '',
                  'amount': double.tryParse(p['variation_amount']?.toString() ?? '0') ?? 0,
                  'code': p['variation_code'] ?? '',
                  'isSme': false,
                })
            .where((p) => p['amount'] > 0)
            .toList();

        // Map SMEPlug plans
        _smePlans = smePlans
            .map<Map<String, dynamic>>((p) => {
                  'label': p['name'] ?? '',
                  'amount': double.tryParse(p['price']?.toString() ?? '0') ?? 0,
                  'code': p['id']?.toString() ?? '',
                  'rawPrice': double.tryParse(p['raw_price']?.toString() ?? '0') ?? 0,
                  'isSme': true,
                })
            .where((p) => p['amount'] > 0)
            .toList();
            
        // Categorize standard plans
        for (var plan in standardPlans) {
          final cat = _categorizePlan(plan['label'] as String);
          _categorizedPlans[cat]?.add(plan);
        }
        
        // Sort each category by amount (lowest to highest)
        for (var key in _categorizedPlans.keys) {
          _categorizedPlans[key]?.sort((a, b) => (a['amount'] as double).compareTo(b['amount'] as double));
        }
        _smePlans.sort((a, b) => (a['amount'] as double).compareTo(b['amount'] as double));
        
        if (_isSmeSelected) {
          _selectedPlan = _smePlans.isNotEmpty ? _smePlans.first : null;
        } else {
          // Auto-select first non-empty category and plan
          _selectedCategoryIndex = _categories.indexWhere((c) => _categorizedPlans[c]!.isNotEmpty);
          if (_selectedCategoryIndex == -1) _selectedCategoryIndex = 0;
          
          final currentCatList = _categorizedPlans[_categories[_selectedCategoryIndex]];
          if (currentCatList != null && currentCatList.isNotEmpty) {
            _selectedPlan = currentCatList.first;
          }
        }

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
      Map<String, dynamic> result;
      if (_selectedPlan!['isSme'] == true) {
        result = await context.read<WalletProvider>().buySmeData(
              network: _selectedNetworkName,
              phone: phone,
              planId: int.parse(_selectedPlan!['code'] as String),
              rawPrice: _selectedPlan!['rawPrice'] as double,
            );
      } else {
        result = await context.read<WalletProvider>().buyData(
              network: _selectedNetworkName,
              phone: phone,
              variationCode: _selectedPlan!['code'] as String,
              amount: _selectedPlan!['amount'] as double,
            );
      }

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
            const SizedBox(height: 16),
            _buildDataModeToggle(networkColor),
            const SizedBox(height: 16),

            // Categories Pill Bar
            if (!_isSmeSelected) ...[
              Text('Data Bundles', style: AppTextStyles.subtitle),
              const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_categories.length, (index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                        final plans = _categorizedPlans[cat];
                        if (plans != null && plans.isNotEmpty) {
                          _selectedPlan = plans.first;
                        } else {
                          _selectedPlan = null;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? networkColor : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(
                        cat,
                        style: AppTextStyles.body.copyWith(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 16),
            
            // Plans Grid
            if (_loadingPlans)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_isSmeSelected ? _smePlans.isEmpty : _categorizedPlans[_categories[_selectedCategoryIndex]]!.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('No plans available for this category.',
                      style: AppTextStyles.bodySecondary),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: _isSmeSelected ? _smePlans.length : _categorizedPlans[_categories[_selectedCategoryIndex]]!.length,
                itemBuilder: (context, index) {
                  final plan = _isSmeSelected 
                      ? _smePlans[index] 
                      : _categorizedPlans[_categories[_selectedCategoryIndex]]![index];
                  final isSelected = _selectedPlan?['code'] == plan['code'];
                  
                  // Extract amount from label cleanly for UI display
                  String shortLabel = plan['label'].toString();
                  // Strip the duplicate price string from VTPass names (e.g. "N100 100MB - 24 hrs" -> "100MB - 24 hrs")
                  if (shortLabel.toUpperCase().startsWith('N') || shortLabel.toUpperCase().startsWith('MTN N')) {
                    final split = shortLabel.split(' ');
                    if (split.length > 1 && split[0].contains(RegExp(r'[0-9]'))) {
                      shortLabel = split.sublist(1).join(' ');
                    } else if (split.length > 2 && split[1].contains(RegExp(r'[0-9]'))) {
                      shortLabel = split.sublist(2).join(' ');
                    }
                  }

                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlan = plan),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? networkColor.withOpacity(0.1) : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? networkColor : Colors.grey.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shortLabel,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? networkColor : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(
                            '₦${(plan['amount'] as double).toStringAsFixed(0)}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? networkColor : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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

  Widget _buildDataModeToggle(Color networkColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSmeSelected = true;
                  _selectedPlan = _smePlans.isNotEmpty ? _smePlans.first : null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isSmeSelected ? networkColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: _isSmeSelected
                      ? [
                          BoxShadow(
                              color: networkColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'SME Data',
                  style: AppTextStyles.body.copyWith(
                    color: _isSmeSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: _isSmeSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSmeSelected = false;
                  _selectedCategoryIndex = _categories.indexWhere((c) => _categorizedPlans[c]!.isNotEmpty);
                  if (_selectedCategoryIndex == -1) _selectedCategoryIndex = 0;
                  final currentCatList = _categorizedPlans[_categories[_selectedCategoryIndex]];
                  _selectedPlan = currentCatList?.isNotEmpty == true ? currentCatList!.first : null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isSmeSelected ? networkColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: !_isSmeSelected
                      ? [
                          BoxShadow(
                              color: networkColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Standard Data',
                  style: AppTextStyles.body.copyWith(
                    color: !_isSmeSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: !_isSmeSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
