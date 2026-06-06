import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../services/api_service.dart';
import 'news_detail_screen.dart';
import '../services/convert_airtime_screen.dart';

class NewsAffiliateAd {
  final String title;
  final String imageBase64;
  final String contactLink;

  const NewsAffiliateAd({
    required this.title,
    required this.imageBase64,
    required this.contactLink,
  });
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<dynamic>> _newsFuture;
  final List<BannerAd> _bannerAds = [];
  final List<BannerAd> _loadedBanners = [];

  List<NewsAffiliateAd> _affiliateAds = [];

  Future<void> _loadAdverts() async {
    final rawAdverts = await ApiService.getAdverts();
    if (mounted) {
      setState(() {
        _affiliateAds = rawAdverts.map((ad) {
          String base64Data = ad['imageBase64'] ?? '';
          if (base64Data.contains(',')) {
            base64Data = base64Data.split(',').last;
          }
          return NewsAffiliateAd(
            title: ad['title'] ?? '',
            imageBase64: base64Data,
            contactLink: ad['contactLink'] ?? '',
          );
        }).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _newsFuture = ApiService.getNews();
    _loadAdverts();
    _loadAdMobBanners(3);
  }

  String get _bannerAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Google AdMob Test Banner ID
    } else {
      // In production/release, replace this with your real live Ad Unit ID
      return 'ca-app-pub-3940256099942544/6300978111'; 
    }
  }

  void _loadAdMobBanners(int count) {
    for (int i = 0; i < count; i++) {
      final banner = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _loadedBanners.add(ad as BannerAd);
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
          },
          onAdClicked: (ad) {
            // Click-bombing protection: immediately remove the clicked ad from feed and dispose it
            if (mounted) {
              setState(() {
                _loadedBanners.remove(ad);
              });
              ad.dispose();
              AppSnackBar.showInfo(context, 'Ad interaction logged safely.');
            }
          },
        ),
      );
      banner.load();
      _bannerAds.add(banner);
    }
  }

  @override
  void dispose() {
    for (var ad in _bannerAds) {
      ad.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _newsFuture = ApiService.getNews();
    });
    await _loadAdverts();
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

  void _handleAdAction(BuildContext context, String actionKey) {
    switch (actionKey) {
      case 'convert_airtime':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConvertAirtimeScreen()),
        );
        break;
      case 'upgrade':
        _showUpgradeDialog(context);
        break;
      case 'refer':
        _showReferralDialog(context);
        break;
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.secondaryDark,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, size: 48, color: Colors.amber),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sair VIP Upgrade',
                  style: AppTextStyles.headlineLight.copyWith(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upgrade to VIP to enjoy 0% convenience fees on all bill payments and get premium cashbacks on your purchases!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    AppSnackBar.showSuccess(context, 'Successfully upgraded to PaySwift VIP!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Upgrade Now (₦2,500/yr)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Maybe Later', style: TextStyle(color: Colors.grey.shade400)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReferralDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.secondaryDark,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, size: 48, color: Colors.pink),
                ),
                const SizedBox(height: 16),
                Text(
                  'Refer & Earn Cash',
                  style: AppTextStyles.headlineLight.copyWith(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share your unique referral code. When your friends register and complete a wallet funding of ₦2,000 or more, you get paid ₦500 instantly!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PAYSWIFT500',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.pink),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: 'PAYSWIFT500'));
                          Navigator.pop(dialogContext);
                          AppSnackBar.showSuccess(context, 'Referral code copied to clipboard!');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Close', style: TextStyle(color: Colors.grey.shade400)),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          final feedItems = <dynamic>[];
          int affiliateAdIndex = 0;
          int admobAdIndex = 0;

          for (int i = 0; i < newsItems.length; i++) {
            feedItems.add(newsItems[i]);

            // Interleave Custom Affiliate Card after every 2 articles
            if ((i + 1) % 2 == 0 && affiliateAdIndex < _affiliateAds.length) {
              feedItems.add(_affiliateAds[affiliateAdIndex]);
              affiliateAdIndex++;
            }

            // Interleave AdMob Banner after every 3 articles (overall index offsets)
            // But only if we have successfully loaded AdMob banners available!
            if ((i + 1) % 3 == 0 && admobAdIndex < _loadedBanners.length) {
              feedItems.add(_loadedBanners[admobAdIndex]);
              admobAdIndex++;
            }
          }

          return RefreshIndicator(
            color: AppColors.buttonColor,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              itemCount: feedItems.length,
              itemBuilder: (context, index) {
                final item = feedItems[index];
                Widget childWidget;
                if (item is NewsAffiliateAd) {
                  childWidget = _buildAffiliateAdCard(context, item);
                } else if (item is BannerAd) {
                  childWidget = _buildAdMobBannerCard(item);
                } else {
                  childWidget = _buildNewsCard(context, item as Map<dynamic, dynamic>, index);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: childWidget,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdMobBannerCard(BannerAd ad) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 10, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'SPONSORED GOOGLE AD',
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffiliateAdCard(BuildContext context, NewsAffiliateAd ad) {
    Uint8List? imageBytes;
    try {
      if (ad.imageBase64.isNotEmpty) {
        imageBytes = base64Decode(ad.imageBase64);
      }
    } catch (e) {
      debugPrint('Failed to decode advert image: $e');
    }

    return GestureDetector(
      onTap: () async {
        if (ad.contactLink.isNotEmpty) {
          try {
            await launchUrlString(
              ad.contactLink,
              mode: LaunchMode.externalApplication,
            );
          } catch (e) {
            if (context.mounted) {
              AppSnackBar.showError(context, 'Could not open the link.');
            }
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imageBytes != null
            ? Image.memory(
                imageBytes,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text('Image unavailable'),
              ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<dynamic, dynamic> item, int index) {
    final title = item['title'] ?? 'No Title';
    final category = item['source']?['name'] ?? 'General';
    final publishedAt = item['publishedAt'] as String?;
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
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailScreen(
                            article: item,
                            bannerGradient: gradient,
                          ),
                        ),
                      );
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
