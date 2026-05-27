import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/api_service.dart';
import '../services/buy_airtime_screen.dart';
import '../services/buy_data_screen.dart';
import '../services/convert_airtime_screen.dart';
import '../services/withdraw_screen.dart';
import '../history/transaction_history_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestions = [
    'Check Wallet Balance',
    'Convert Airtime to Cash',
    'Buy Mobile Data',
    'Recharge Airtime',
    'Withdraw Funds',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'isUser': false,
      'text': "Hello! I am PaySwift AI, your premium financial assistant. Ask me to check your balance, recharge airtime/data, convert airtime, or manage your wallet. How can I help you today?",
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });
    _scrollToBottom();
    _messageController.clear();

    try {
      final response = await ApiService.sendAiChatMessage(text);
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': response['reply'] ?? "I couldn't process that. Please try again.",
            'action': response['action'],
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': "Sorry, I ran into a connection issue. Please check your network and try again.",
            'timestamp': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _handleActionClick(Map<String, dynamic> action) {
    final String type = action['type'] ?? 'NONE';

    Widget? targetScreen;
    switch (type) {
      case 'NAVIGATE_BUY_AIRTIME':
        targetScreen = const BuyAirtimeScreen();
        break;
      case 'NAVIGATE_BUY_DATA':
        targetScreen = const BuyDataScreen();
        break;
      case 'NAVIGATE_CONVERT_AIRTIME':
        targetScreen = const ConvertAirtimeScreen();
        break;
      case 'NAVIGATE_WITHDRAW':
        targetScreen = const WithdrawScreen();
        break;
      case 'NAVIGATE_HISTORY':
        targetScreen = const TransactionHistoryScreen();
        break;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    }
  }

  String _getActionLabel(String type) {
    switch (type) {
      case 'NAVIGATE_BUY_AIRTIME':
        return 'Go to Buy Airtime';
      case 'NAVIGATE_BUY_DATA':
        return 'Go to Buy Data';
      case 'NAVIGATE_CONVERT_AIRTIME':
        return 'Go to Convert Airtime';
      case 'NAVIGATE_WITHDRAW':
        return 'Go to Withdraw Funds';
      case 'NAVIGATE_HISTORY':
        return 'View Transactions';
      default:
        return 'Open Page';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primaryDark : AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.buttonColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                color: AppColors.accentGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PaySwift AI',
              style: AppTextStyles.headlineLight.copyWith(fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                final action = msg['action'] as Map<String, dynamic>?;

                return Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isDark
                                ? AppColors.secondaryDark
                                : Colors.white,
                            child: const Icon(Icons.bolt,
                                color: AppColors.buttonColor, size: 18),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.buttonColor
                                  : (isDark
                                      ? AppColors.secondaryDark
                                      : Colors.white),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isUser
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                                bottomRight: isUser
                                    ? Radius.zero
                                    : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                              border: !isUser && !isDark
                                  ? Border.all(color: Colors.grey.shade200)
                                  : null,
                            ),
                            child: Text(
                              msg['text'] as String,
                              style: isUser
                                  ? AppTextStyles.body.copyWith(color: Colors.white)
                                  : AppTextStyles.body.copyWith(
                                      color: isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.buttonColor.withOpacity(0.2),
                            child: const Icon(Icons.person,
                                color: AppColors.buttonColor, size: 18),
                          ),
                        ],
                      ],
                    ),
                    if (action != null && action['type'] != 'NONE')
                      Padding(
                        padding: const EdgeInsets.only(left: 40, bottom: 12, top: 4),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: Text(
                            _getActionLabel(action['type']),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _handleActionClick(action),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PaySwift AI is thinking...',
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),

          // Suggestions chips
          if (_messages.length == 1 && !_isLoading)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor:
                          isDark ? AppColors.secondaryDark : Colors.white,
                      surfaceTintColor: Colors.transparent,
                      label: Text(
                        suggestion,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : AppColors.primaryDark.withOpacity(0.15),
                        ),
                      ),
                      onPressed: () => _sendMessage(suggestion),
                    ),
                  );
                },
              ),
            ),

          // Message input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondaryDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.primaryDark : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: isDark
                            ? Border.all(color: Colors.white10)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Type a message or request...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) => _sendMessage(value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.buttonColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
