import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    try {
      await ApiService.markNotificationRead(id);
      setState(() {
        _notifications[index]['read'] = true;
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.headlineLight.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications yet.',
                    style: AppTextStyles.bodySecondary,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['read'] == true;
                    return Card(
                      color: isRead ? Theme.of(context).cardColor : AppColors.secondaryDark.withOpacity(0.1),
                      elevation: isRead ? 0 : 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: isRead ? null : () => _markAsRead(notification['id'], index),
                        leading: CircleAvatar(
                          backgroundColor: isRead ? Colors.grey.shade300 : AppColors.buttonColor,
                          child: Icon(
                            isRead ? Icons.notifications_none : Icons.notifications_active,
                            color: isRead ? Colors.grey : Colors.white,
                          ),
                        ),
                        title: Text(
                          notification['title'] ?? 'Notification',
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            notification['message'] ?? '',
                            style: AppTextStyles.body.copyWith(
                              color: isRead ? Colors.grey : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
