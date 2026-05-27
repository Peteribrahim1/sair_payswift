import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../services/api_service.dart';

class HelpSupportScreen extends StatefulWidget {
  final String? prefilledSubject;

  const HelpSupportScreen({Key? key, this.prefilledSubject}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _messageController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.prefilledSubject);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not launch support link.');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error launching link: $e');
      }
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please enter a subject');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please enter your message');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.submitSupportTicket(
        _subjectController.text.trim(),
        _messageController.text.trim(),
      );
      
      if (res['success'] == true) {
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Ticket submitted! We will contact you soon.');
          _messageController.clear();
          if (widget.prefilledSubject == null) {
            _subjectController.clear();
          }
        }
      } else {
        if (mounted) {
          AppSnackBar.showError(context, res['error'] ?? 'Failed to submit ticket');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to submit ticket: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Text('Help & Support', style: AppTextStyles.headlineLight.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact Action Cards
              Row(
                children: [
                  Expanded(
                    child: _buildContactCard(
                      context: context,
                      icon: Icons.email_outlined,
                      title: 'Email Support',
                      subtitle: 'support@payswift.com',
                      onTap: () => _launchUrl('mailto:support@payswift.com?subject=Support%20Request'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildContactCard(
                      context: context,
                      icon: Icons.phone_in_talk_outlined,
                      title: 'Call Support',
                      subtitle: '+234 812 345 6789',
                      onTap: () => _launchUrl('tel:+2348123456789'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWhatsAppCard(
                context: context,
                onTap: () => _launchUrl('https://wa.me/2348055579520'),
              ),
              const SizedBox(height: 28),

              // Contact Form Title
              Text('Send us a Message', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Contact Form Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _subjectController,
                      label: 'Subject',
                      hint: 'What is this regarding?',
                      prefixIcon: Icons.subject,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _messageController,
                      label: 'Message',
                      hint: 'Describe your issue details here...',
                      prefixIcon: Icons.message_outlined,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitTicket,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Submit Ticket', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // FAQs Section Title
              Text('Frequently Asked Questions', style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // FAQ Expandable Tiles
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      _buildFaqTile(
                        context,
                        'How do I fund my wallet?',
                        'You can fund your wallet by transferring funds to your dedicated virtual account displayed on the dashboard home screen. Top-ups reflect instantly.',
                      ),
                      const Divider(height: 1),
                      _buildFaqTile(
                        context,
                        'Why is my transaction pending?',
                        'Transactions usually process instantly. If a transaction is pending, VTPass might be validating the payment. You can copy the reference ID and contact our support if it takes longer than 15 minutes.',
                      ),
                      const Divider(height: 1),
                      _buildFaqTile(
                        context,
                        'Are my card details secure?',
                        'Yes, PaySwift uses state-of-the-art bank-grade security and standard tokenization to protect all your sensitive financial and personal details.',
                      ),
                      const Divider(height: 1),
                      _buildFaqTile(
                        context,
                        'How do I upgrade my KYC limit?',
                        'Navigate to your virtual account details or profile settings, choose "KYC Verification", and supply your BVN or NIN to instantly upgrade your transfer limits.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.buttonColor.withOpacity(isDark ? 0.15 : 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.buttonColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.buttonColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppCard({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const whatsappGreen = Color(0xFF25D366);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: whatsappGreen.withOpacity(isDark ? 0.2 : 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: whatsappGreen.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: whatsappGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WhatsApp Support',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chat with us instantly on WhatsApp',
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: whatsappGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ExpansionTile(
      title: Text(
        question,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      iconColor: AppColors.buttonColor,
      collapsedIconColor: isDark ? Colors.white70 : AppColors.primaryDark,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: AppTextStyles.bodySecondary.copyWith(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
