import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedFilter = 'All';

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  String _formatFullDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} • $hour:$minute $period";
  }

  String _getDateCategory(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (itemDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (itemDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return 'Earlier';
    }
  }

  bool _matchesFilter(NotificationModel item, String filter) {
    if (filter == 'All') return true;
    if (filter == 'Unread') return !item.read;

    final type = item.type.toLowerCase();
    final title = item.title.toLowerCase();

    if (filter == 'Jobs') {
      return type.contains('job') || type.contains('booking') || title.contains('job') || title.contains('task') || title.contains('booking');
    }
    if (filter == 'Messages') {
      return type.contains('chat') || type.contains('message') || title.contains('message') || title.contains('chat');
    }
    if (filter == 'System') {
      return type.contains('system') || type.contains('payment') || title.contains('payment') || title.contains('system');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: currentUserId)
              .where('read', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data?.docs.length ?? 0;
            return Row(
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded, color: theme.colorScheme.primary),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllAsRead(currentUserId),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black87),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'clear_all') {
                _confirmClearAll(context, currentUserId);
              } else if (value == 'mark_read') {
                _markAllAsRead(currentUserId);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Clear all notifications', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          _buildFilterChipsRow(currentUserId, theme, isDark),
          const SizedBox(height: 8),

          // Main Notifications Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading notifications: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawDocs = snapshot.data?.docs ?? [];
                final allNotifications = rawDocs.map((doc) {
                  return NotificationModel.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  );
                }).toList();

                // Sort descending by timestamp
                allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                // Filter by selected tab
                final filteredList = allNotifications.where((n) => _matchesFilter(n, _selectedFilter)).toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                // Group by Today, Yesterday, Earlier
                final Map<String, List<NotificationModel>> groupedMap = {};
                for (var item in filteredList) {
                  final groupKey = _getDateCategory(item.timestamp);
                  groupedMap.putIfAbsent(groupKey, () => []).add(item);
                }

                final groupOrder = ['Today', 'Yesterday', 'Earlier'];
                final displayGroups = groupOrder.where((g) => groupedMap.containsKey(g)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: displayGroups.length,
                  itemBuilder: (context, groupIndex) {
                    final groupName = displayGroups[groupIndex];
                    final groupItems = groupedMap[groupName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Text(
                            groupName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...groupItems.map((notify) {
                          return _buildNotificationCard(context, notify, isDark, theme);
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsRow(String userId, ThemeData theme, bool isDark) {
    final categories = ['All', 'Unread', 'Jobs', 'Messages', 'System'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final models = docs.map((d) => NotificationModel.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

        final unreadCount = models.where((n) => !n.read).length;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedFilter == cat;
              int? badgeNum;
              if (cat == 'All') badgeNum = models.length;
              if (cat == 'Unread') badgeNum = unreadCount;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat),
                      if (badgeNum != null && badgeNum > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.3)
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$badgeNum',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = cat);
                    }
                  },
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                  ),
                  elevation: isSelected ? 2 : 0,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notify, bool isDark, ThemeData theme) {
    final iconData = _getIcon(notify.title, notify.type);
    final iconColor = _getIconColor(notify.title, notify.type);

    return Dismissible(
      key: Key(notify.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        FirebaseFirestore.instance.collection('notifications').doc(notify.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 26),
            SizedBox(height: 2),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (!notify.read) {
            FirebaseFirestore.instance.collection('notifications').doc(notify.id).update({'read': true});
          }
          _showNotificationDetails(context, notify, iconData, iconColor, isDark, theme);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notify.read
                ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
                : (isDark ? const Color(0xFF262038) : const Color(0xFFF0EBFC)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notify.read
                  ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))
                  : theme.colorScheme.primary.withValues(alpha: 0.25),
              width: notify.read ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notify.title,
                            style: TextStyle(
                              fontWeight: notify.read ? FontWeight.bold : FontWeight.w900,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF111111),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(notify.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notify.body,
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Unread Indicator Dot
              if (!notify.read) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notify,
    IconData iconData,
    Color iconColor,
    bool isDark,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notify.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFullDate(notify.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  notify.body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          FirebaseFirestore.instance.collection('notifications').doc(notify.id).delete();
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIcon(String title, String type) {
    final t = '${title.toLowerCase()} ${type.toLowerCase()}';
    if (t.contains('message') || t.contains('chat')) return Icons.chat_bubble_rounded;
    if (t.contains('job') || t.contains('task') || t.contains('booking')) return Icons.work_rounded;
    if (t.contains('payment') || t.contains('wallet') || t.contains('money')) return Icons.account_balance_wallet_rounded;
    if (t.contains('star') || t.contains('review') || t.contains('rating')) return Icons.star_rounded;
    if (t.contains('offer') || t.contains('promo') || t.contains('discount')) return Icons.local_offer_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _getIconColor(String title, String type) {
    final t = '${title.toLowerCase()} ${type.toLowerCase()}';
    if (t.contains('message') || t.contains('chat')) return Colors.blueAccent;
    if (t.contains('job') || t.contains('task') || t.contains('booking')) return Colors.orangeAccent;
    if (t.contains('payment') || t.contains('wallet')) return Colors.green;
    if (t.contains('star') || t.contains('review')) return Colors.amber;
    if (t.contains('offer') || t.contains('promo')) return Colors.purpleAccent;
    return Colors.deepPurpleAccent;
  }

  void _markAllAsRead(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();

    if (mounted && querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked ${querySnapshot.docs.length} notifications as read'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmClearAll(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Notifications?'),
        content: const Text('This will permanently delete all your notifications. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final query = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .get();

              final batch = FirebaseFirestore.instance.batch();
              for (var doc in query.docs) {
                batch.delete(doc.reference);
              }
              await batch.commit();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEDE7F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 70,
                color: isDark ? Colors.grey[600] : const Color(0xFF7E57C2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedFilter == 'All'
                  ? 'All caught up!'
                  : 'No $_selectedFilter notifications',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedFilter == 'All'
                  ? "You don't have any notifications right now."
                  : "There are no notifications matching the '$_selectedFilter' filter.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
            ),
            if (_selectedFilter != 'All') ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedFilter = 'All'),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: const Text('Clear Filter'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
