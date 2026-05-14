import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/wallet_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedIndex = -1;

  Map<String, double> _calculateCategoryData(List<dynamic> transactions) {
    Map<String, double> data = {
      'AIRTIME': 0,
      'DATA': 0,
      'BILL': 0,
      'CONVERT': 0,
    };

    for (var tx in transactions) {
      final type = tx['type'] ?? 'UNKNOWN';
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      if (type == 'FUND') continue; // Skip funding for spending analytics

      if (type == 'AIRTIME') data['AIRTIME'] = data['AIRTIME']! + amount;
      else if (type == 'DATA') data['DATA'] = data['DATA']! + amount;
      else if (type == 'BILL') data['BILL'] = data['BILL']! + amount;
      else if (type == 'CONVERT_AIRTIME') data['CONVERT'] = data['CONVERT']! + amount;
    }

    // Remove empty categories
    data.removeWhere((key, value) => value == 0);
    return data;
  }

  List<BarChartGroupData> _calculateWeeklyData(List<dynamic> transactions) {
    final Map<int, double> dailyTotals = {};
    final now = DateTime.now();

    for (var i = 0; i < 7; i++) {
      dailyTotals[i] = 0;
    }

    for (var tx in transactions) {
      final dateStr = tx['createdAt'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.parse(dateStr);
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        final type = tx['type'] ?? '';
        if (type != 'FUND') {
          dailyTotals[6 - diff] = (dailyTotals[6 - diff] ?? 0) + amount;
        }
      }
    }

    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[i]!,
            color: AppColors.primaryDark,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Spending Analytics', style: AppTextStyles.headlineLight.copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final transactions = wallet.transactions;
          if (transactions.isEmpty) {
            return const Center(child: Text('No transaction data to analyze.'));
          }

          final categoryData = _calculateCategoryData(transactions);
          final weeklyGroups = _calculateWeeklyData(transactions);
          final totalSpend = categoryData.values.fold<double>(0, (sum, val) => sum + val);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Card
                _buildOverviewCard(totalSpend),
                const SizedBox(height: 24),

                // Category Pie Chart
                Text('Spending by Category', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPieChart(categoryData),
                const SizedBox(height: 32),

                // Weekly Bar Chart
                Text('Weekly Trend', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildBarChart(weeklyGroups),
                const SizedBox(height: 32),

                // Breakdown List
                Text('Breakdown', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...categoryData.entries.map((e) => _buildBreakdownTile(e.key, e.value, totalSpend)).toList(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Monthly Spend', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('₦${total.toStringAsFixed(2)}', 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 4),
              Text('2.5% increase from last month', 
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    final colors = [AppColors.primaryDark, Colors.orange, AppColors.mtnYellow, Colors.teal, Colors.purple];
    int i = 0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: data.entries.map((entry) {
            final isTouched = data.entries.toList().indexOf(entry) == _touchedIndex;
            final fontSize = isTouched ? 16.0 : 12.0;
            final radius = isTouched ? 60.0 : 50.0;
            final color = colors[i++ % colors.length];

            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: isTouched ? '₦${entry.value.toInt()}' : '${(entry.value / data.values.fold(0, (s,v)=>s+v) * 100).toInt()}%',
              radius: radius,
              titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<BarChartGroupData> groups) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          barGroups: groups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildBreakdownTile(String category, double amount, double total) {
    final percentage = (amount / total * 100).toStringAsFixed(1);
    IconData icon;
    Color color;

    switch (category) {
      case 'AIRTIME': icon = Icons.phone_android; color = AppColors.mtnYellow; break;
      case 'DATA': icon = Icons.wifi; color = Colors.orange; break;
      case 'BILL': icon = Icons.lightbulb_outline; color = Colors.teal; break;
      default: icon = Icons.category; color = AppColors.primaryDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$percentage% of total spend', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text('₦${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
