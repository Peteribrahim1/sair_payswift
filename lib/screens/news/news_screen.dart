import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<dynamic>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = ApiService.getNews();
  }

  Future<void> _refresh() async {
    setState(() {
      _newsFuture = ApiService.getNews();
    });
  }

  String _relativeTime(String? isoDate) {
    if (isoDate == null) return 'Just now';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Just now';
    }
  }

  // Assign a gradient based on the article index for visual variety
  LinearGradient _cardGradient(int index) {
    const gradients = [
      [Color(0xFF1A237E), Color(0xFF283593)],
      [Color(0xFF004D40), Color(0xFF00695C)],
      [Color(0xFF880E4F), Color(0xFFAD1457)],
      [Color(0xFF1B5E20), Color(0xFF2E7D32)],
      [Color(0xFF311B92), Color(0xFF4527A0)],
    ];
    final g = gradients[index % gradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: g,
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'finance':
        return Icons.account_balance;
      case 'technology':
        return Icons.computer;
      case 'market':
        return Icons.show_chart;
      case 'crypto':
        return Icons.currency_bitcoin;
      case 'business':
        return Icons.business_center;
      default:
        return Icons.article;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'finance':
        return Colors.blue;
      case 'technology':
        return Colors.purple;
      case 'market':
        return Colors.green;
      case 'crypto':
        return Colors.orange;
      case 'business':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Text('News', style: AppTextStyles.headlineLight.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Failed to load news.', style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  )
                ],
              ),
            );
          }

          final newsItems = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.buttonColor,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              itemCount: newsItems.length,
              itemBuilder: (context, index) {
                final item = newsItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildNewsCard(context, item, index),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<dynamic, dynamic> item, int index) {
    final title = item['title'] ?? 'No Title';
    final category = item['source']?['name'] ?? 'General';
    final publishedAt = item['publishedAt'] as String?;
    final articleUrl = item['url'] as String?;
    final timeAgo = _relativeTime(publishedAt);
    final gradient = _cardGradient(index);
    final catColor = _categoryColor(category);
    final catIcon = _categoryIcon(category);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient banner with icon
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(gradient: gradient),
            child: Stack(
              children: [
                // Decorative circles for depth
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -10,
                  bottom: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                Center(
                  child: Icon(catIcon, size: 52, color: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: catColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catIcon, size: 12, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              color: catColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Time ago
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Read more
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () async {
                      if (articleUrl != null) {
                        final uri = Uri.parse(articleUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read more',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
