import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/service_card.dart';
import '../../providers/wallet_provider.dart';
import '../services/buy_data_screen.dart';
import '../services/convert_airtime_screen.dart';
import '../services/pay_bills_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              )
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
                  onPressed: () {},
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
      {'title': 'Buy Airtime', 'icon': Icons.phone_android, 'color': AppColors.mtnYellow, 'route': const Scaffold(body: Center(child: Text('Buy Airtime')))},
      {'title': 'Convert Airtime', 'icon': Icons.import_export, 'color': AppColors.airtelRed, 'route': const ConvertAirtimeScreen()},
      {'title': 'Electricity', 'icon': Icons.lightbulb_outline, 'color': Colors.orange, 'route': const PayBillsScreen()},
      {'title': 'Cable TV', 'icon': Icons.tv, 'color': Colors.blue, 'route': const PayBillsScreen()},
      {'title': 'Pay Bills', 'icon': Icons.receipt_long, 'color': AppColors.nineMobileGreen, 'route': const PayBillsScreen()},
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
