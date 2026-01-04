import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'chat_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Timer? _reminderCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkAndActivateReminders();
    // Check every 30 seconds for due reminders (more frequent for testing)
    _reminderCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAndActivateReminders(),
    );
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAndActivateReminders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('🔔 NotificationsPage: No user logged in');
      return;
    }

    try {
      final now = DateTime.now();
      print('🔔 NotificationsPage: Checking reminders at $now');

      // Simplified query to avoid composite index requirement
      final remindersSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('type', isEqualTo: 'appointment_reminder')
          .get();

      // Filter in memory
      final dueReminders = remindersSnapshot.docs.where((doc) {
        final data = doc.data();
        final sent = data['sent'] as bool? ?? true;
        final scheduledFor = (data['scheduledFor'] as Timestamp?)?.toDate();

        if (sent || scheduledFor == null) return false;

        // Check if scheduled time has passed
        return scheduledFor.isBefore(now) || scheduledFor.isAtSameMomentAs(now);
      }).toList();

      print('🔔 NotificationsPage: Found ${dueReminders.length} due reminders');

      for (final doc in dueReminders) {
        final data = doc.data();
        print('🔔 Marking reminder as sent: ${data['message']}');
        // Mark reminder as sent so it appears in the list
        await doc.reference.update({
          'sent': true,
          'sentAt': FieldValue.serverTimestamp(),
        });
      }

      if (dueReminders.isNotEmpty) {
        print('✅ Marked ${dueReminders.length} reminders as sent');
      }
    } catch (e) {
      print('❌ NotificationsPage error: $e');
      debugPrint('Error checking reminders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              onPressed: () => _clearAllNotifications(context, userId),
              tooltip: 'Clear all',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              onPressed: () => _markAllAsRead(userId),
              tooltip: 'Mark all as read',
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE0E7FF), Color(0xFFF3E8FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF667EEA,
                                  ).withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 80,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'No notifications',
                      style: TextStyle(
                        color: Color(0xFF1A202C),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re all caught up!\nNotifications will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort notifications by createdAt in memory to avoid index requirement
          // Also filter out old reminders and notifications older than 7 days if read
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? '';
            final isRead = data['read'] ?? false;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final scheduledFor = (data['scheduledFor'] as Timestamp?)?.toDate();
            final sent = data['sent'] ?? false;

            // For reminders, only show if sent is true (means it's time to show)
            if (type == 'appointment_reminder') {
              return sent == true;
            }

            // Filter out read notifications older than 7 days
            if (isRead && createdAt != null) {
              final daysDiff = DateTime.now().difference(createdAt).inDays;
              if (daysDiff > 7) {
                return false;
              }
            }

            return true;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE0E7FF), Color(0xFFF3E8FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF667EEA,
                                  ).withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 80,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'No notifications',
                      style: TextStyle(
                        color: Color(0xFF1A202C),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re all caught up!\nNotifications will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          docs.sort((a, b) {
            final aTime =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // descending order (newest first)
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final type = data['type'] ?? 'message';
              final title = data['title'] ?? '';
              final message = data['message'] ?? '';
              final isRead = data['read'] ?? false;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final senderName = data['senderName'] ?? 'Utilisateur';
              final conversationId = data['conversationId'];
              final senderId = data['senderId'];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: isRead
                      ? const LinearGradient(
                          colors: [Colors.white, Color(0xFFFAFAFA)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFF0F4FF), Color(0xFFFFF4F0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isRead
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF667EEA).withOpacity(0.3),
                    width: isRead ? 1 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isRead
                          ? Colors.black.withOpacity(0.03)
                          : const Color(0xFF667EEA).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _markAsRead(doc.id);
                      if (type == 'message' &&
                          conversationId != null &&
                          senderId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              conversationId: conversationId,
                              otherPersonId: senderId,
                              otherPersonName: senderName,
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: _getGradientForType(type),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getColorForType(
                                        type,
                                      ).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getIcon(type),
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              if (!isRead)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF5F6D),
                                          Color(0xFFFFC371),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF5F6D,
                                          ).withOpacity(0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.w700
                                        : FontWeight.w900,
                                    fontSize: 16,
                                    color: const Color(0xFF1A202C),
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: _getColorForType(type),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      createdAt != null
                                          ? _formatTime(createdAt)
                                          : '',
                                      style: TextStyle(
                                        color: _getColorForType(type),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getColorForType(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: _getColorForType(type),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'message':
        return const Color(0xFF667EEA);
      case 'appointment':
        return const Color(0xFF4FD1C5);
      case 'reminder':
        return const Color(0xFFF6AD55);
      default:
        return const Color(0xFF63B3ED);
    }
  }

  LinearGradient _getGradientForType(String type) {
    switch (type) {
      case 'message':
        return const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'appointment':
        return const LinearGradient(
          colors: [Color(0xFF4FD1C5), Color(0xFF38B2AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'reminder':
        return const LinearGradient(
          colors: [Color(0xFFF6AD55), Color(0xFFED8936)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF63B3ED), Color(0xFF4299E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays == 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  static Future<void> _markAllAsRead(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  static Future<void> _clearAllNotifications(
    BuildContext context,
    String userId,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This will permanently delete all your notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final notifications = await FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: userId)
            .get();

        for (var doc in notifications.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error clearing notifications: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing notifications: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
