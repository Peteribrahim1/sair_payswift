import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/service_card.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../services/buy_data_screen.dart';
import '../services/buy_airtime_screen.dart';
import '../services/convert_airtime_screen.dart';
import '../services/electricity_screen.dart';
import '../services/cable_tv_screen.dart';
import '../services/withdraw_screen.dart';
import 'package:flutter/services.dart';
import 'notifications_screen.dart';
import '../history/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final notifications = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _unreadCount = notifications.where((n) => n['read'] == false).length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notification count: $e');
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
    // Refresh badge when returning
    _fetchUnreadCount();
  }

  void _showFundWalletSheet() {
    // Start fetching virtual account
    context.read<WalletProvider>().fetchVirtualAccount();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Consumer<WalletProvider>(
              builder: (context, wallet, child) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Fund Wallet',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text('Transfer money to your dedicated account number below to fund your wallet instantly.',
                        style: AppTextStyles.bodySecondary),
                    const SizedBox(height: 32),
                    
                    if (wallet.loadingVirtualAccount)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (wallet.requireKyc)
                      _KycFormWidget(wallet: wallet)
                    else if (wallet.virtualAccountNumber != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryDark.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Bank Name', style: AppTextStyles.bodySecondary),
                                Text(wallet.virtualAccountBank ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Account Number', style: AppTextStyles.bodySecondary),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: wallet.virtualAccountNumber!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Account number copied!')),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Text(wallet.virtualAccountNumber!, style: AppTextStyles.headlineLight.copyWith(color: AppColors.primaryDark, fontSize: 20)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.copy, size: 18, color: AppColors.primaryDark),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Account Name', style: AppTextStyles.bodySecondary),
                                Text(wallet.virtualAccountName ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          'Failed to generate virtual account. Please try again.',
                          style: AppTextStyles.bodySecondary.copyWith(color: Colors.red),
                        ),
                      ),
                    
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text('Done', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildServicesGrid(context),
              const SizedBox(height: 24),
              _buildSponsoredAd(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Home', style: AppTextStyles.headlineLight.copyWith(fontSize: 20)),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: _openNotifications,
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryDark, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _unreadCount > 9 ? '9+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet Balance', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Consumer<WalletProvider>(
                      builder: (context, wallet, child) {
                        return Text(
                          '₦${wallet.balance.toStringAsFixed(2)}',
                          style: AppTextStyles.headlineLight.copyWith(fontSize: 28),
                        );
                      },
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showFundWalletSheet,
                  child: const Text('Fund Wallet'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    final services = [
      {'title': 'Buy Data', 'icon': Icons.wifi, 'color': AppColors.gloGreen, 'route': const BuyDataScreen()},
      {'title': 'Buy Airtime', 'icon': Icons.phone_android, 'color': AppColors.mtnYellow, 'route': const BuyAirtimeScreen()},
      {'title': 'Convert Airtime', 'icon': Icons.import_export, 'color': AppColors.airtelRed, 'route': const ConvertAirtimeScreen()},
      {'title': 'Electricity', 'icon': Icons.lightbulb_outline, 'color': Colors.orange, 'route': const ElectricityScreen()},
      {'title': 'Withdraw', 'icon': Icons.account_balance_wallet, 'color': Colors.teal, 'route': const WithdrawScreen()},
      {'title': 'Cable TV', 'icon': Icons.tv, 'color': AppColors.nineMobileGreen, 'route': const CableTvScreen()},
      {'title': 'Analytics', 'icon': Icons.insights, 'color': Colors.deepPurple, 'route': const AnalyticsScreen()},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCard(
            title: service['title'] as String,
            icon: service['icon'] as IconData,
            iconColor: service['color'] as Color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => service['route'] as Widget),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSponsoredAd() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sponsored Ad', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Get 5% Cashback', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('On all electricity payments', style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 40),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _KycFormWidget extends StatefulWidget {
  final WalletProvider wallet;
  const _KycFormWidget({Key? key, required this.wallet}) : super(key: key);

  @override
  State<_KycFormWidget> createState() => _KycFormWidgetState();
}

class _KycFormWidgetState extends State<_KycFormWidget> {
  final _bvnController = TextEditingController();
  final _ninController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final bvn = _bvnController.text.trim();
    final nin = _ninController.text.trim();
    if (bvn.isEmpty && nin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter either BVN or NIN')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final success = await widget.wallet.submitKyc(bvn: bvn.isNotEmpty ? bvn : null, nin: nin.isNotEmpty ? nin : null);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC Verified Successfully. Generating Account...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to verify KYC. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'CBN Regulation requires a BVN or NIN to generate your dedicated virtual account.',
                  style: AppTextStyles.bodySecondary.copyWith(color: Colors.amber.shade900, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _bvnController,
          label: 'BVN (Bank Verification Number)',
          keyboardType: TextInputType.number,
          hint: 'Enter your 11-digit BVN',
        ),
        const SizedBox(height: 16),
        const Center(child: Text('OR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _ninController,
          label: 'NIN (National Identification Number)',
          keyboardType: TextInputType.number,
          hint: 'Enter your 11-digit NIN',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Verify & Create Account', style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
