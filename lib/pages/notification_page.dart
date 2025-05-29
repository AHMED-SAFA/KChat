import 'package:kchat/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:toastification/toastification.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

import '../services/cloud_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NotificationService _notificationService;
  late AnimationController _animationController;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _notificationService = _getIt.get<NotificationService>();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadNotifications();
    _markNotificationsAsRead();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Add this method
  Future<void> _markNotificationsAsRead() async {
    try {
      String receiverId = _authService.user!.uid;
      await _notificationService.markNotificationsAsRead(
          receiverId: receiverId);
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      String receiverId = _authService.user!.uid;
      List<Map<String, dynamic>> notifications = await _notificationService
          .retrieveNotifications(receiverId: receiverId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });
    await _loadNotifications();
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = DateTime.parse(timestamp.toString());
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _showClearAllDialog,
              icon: const Icon(Icons.delete),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: RefreshIndicator(
        backgroundColor: Colors.white,
        onRefresh: _refreshNotifications,
        color: Colors.black,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              )
            : _buildNotificationContent(),
      ),
    );
  }

  Widget _buildNotificationContent() {
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildNotificationHeader(),
        Expanded(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        index * 0.1,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    )),
                    child: _buildNotificationCard(index),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black12, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.notifications_active,
              color: Colors.deepPurple.shade600,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_notifications.length} ${_notifications.length == 1 ? 'notification' : 'notifications'}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(int index) {
    final notification = _notifications[index];
    String notificationId = notification['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle notification tap if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationAvatar(notification),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['senderName'] ?? 'Unknown Sender',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildDeleteButton(notificationId, index),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (notification['message'] != null)
                        Text(
                          notification['message'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(notification['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationAvatar(Map<String, dynamic> notification) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade300,
            Colors.deepPurple.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          (notification['senderName'] ?? 'U')[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(String notificationId, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _deleteNotification(notificationId, index),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red.shade400,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you receive notifications,\nthey\'ll appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      String receiverId = _authService.user!.uid;
      await _notificationService.deleteNotification(
        receiverId: receiverId,
        notificationId: notificationId,
      );

      setState(() {
        _notifications.removeAt(index);
      });

      _showSuccessToast('Notification deleted successfully');
    } catch (e) {
      _showErrorToast('Failed to delete notification');
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Clear All Notifications',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      String receiverId = _authService.user!.uid;
      for (var notification in _notifications) {
        await _notificationService.deleteNotification(
          receiverId: receiverId,
          notificationId: notification['id'],
        );
      }

      setState(() {
        _notifications.clear();
      });

      _showSuccessToast('All notifications cleared');
    } catch (e) {
      _showErrorToast('Failed to clear notifications');
    }
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG, // ~3 seconds
      gravity: ToastGravity.TOP, // Position at top
      backgroundColor: Colors.green.shade400,
      textColor: Colors.white,
      fontSize: 14.0,
      timeInSecForIosWeb: 3,
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      style: ToastificationStyle.flat,
      type: ToastificationType.error, // Built-in error style
      backgroundColor: Colors.red.shade400,
      foregroundColor: Colors.white,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      alignment: Alignment.topCenter,

      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1.0), // Slide from top
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}
