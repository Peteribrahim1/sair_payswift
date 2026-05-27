import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<dynamic, dynamic> article;
  final LinearGradient bannerGradient;

  const NewsDetailScreen({
    Key? key,
    required this.article,
    required this.bannerGradient,
  }) : super(key: key);

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

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final title = article['title'] ?? 'No Title';
    final sourceName = article['source']?['name'] ?? 'General';
    final publishedAt = article['publishedAt'] as String?;
    final imageUrl = article['urlToImage'] as String?;
    final description = article['description'] as String?;
    final content = article['content'] as String?;
    final articleUrl = article['url'] as String?;
    final timeAgo = _relativeTime(publishedAt);

    // Clean up content string (often NewsAPI adds suffix " [+1234 chars]")
    String displayContent = content ?? '';
    if (displayContent.contains(' [+')) {
      displayContent = displayContent.split(' [+')[0];
    }
    if (displayContent.isEmpty) {
      displayContent = description ?? 'No further content available for this article.';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primaryDark : Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Premium sliver app bar with image/gradient background
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or gradient banner
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(gradient: bannerGradient),
                        child: Center(
                          child: Icon(Icons.article, size: 64, color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(gradient: bannerGradient),
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(gradient: bannerGradient),
                      child: Center(
                        child: Icon(
                          Icons.article,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  // Dark gradient overlay for title legibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Article content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source & Date Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.buttonColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.buttonColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          sourceName,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.buttonColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    title,
                    style: AppTextStyles.headlineDark.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const Divider(height: 32, thickness: 1),
                  
                  // Description / Summary (if available)
                  if (description != null && description.isNotEmpty && description != title) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.buttonColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.buttonColor.withOpacity(0.1)),
                      ),
                      child: Text(
                        description,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Content Body
                  Text(
                    displayContent,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Action Button to Read Original Web Page
                  if (articleUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _launchUrl(articleUrl),
                        icon: const Icon(Icons.open_in_browser, color: Colors.white),
                        label: Text(
                          'Read Full Article on Web',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
