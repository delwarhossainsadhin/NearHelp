import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat_screen.dart';

class ProviderAcceptedJobsScreen extends StatefulWidget {
  const ProviderAcceptedJobsScreen({super.key});

  @override
  State<ProviderAcceptedJobsScreen> createState() => _ProviderAcceptedJobsScreenState();
}

class _ProviderAcceptedJobsScreenState extends State<ProviderAcceptedJobsScreen> {
  bool _isUpdating = false;

  // প্রিমিয়াম কনফার্মেশন ডায়ালগ
  Future<void> _completeTask(String taskId) async {
    final bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: const Text('Finish Task?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you have finished this task? This will notify the customer for payment.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Not Yet', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Yes, Completed'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);

    try {
      final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      final data = taskDoc.data() as Map<String, dynamic>;
      final customerId = data['customerId'];
      final taskTitle = data['title'] ?? 'your task';

      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': 'completed',
      });

      if (customerId != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': customerId,
          'title': 'Task Completed! 🎉',
          'body': 'Your task "$taskTitle" has been marked as completed. Please check and pay.',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task marked as completed!'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) return const Center(child: Text('Please log in.'));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Active Jobs', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('acceptedBy', isEqualTo: user.uid)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final taskId = docs[index].id;

              return _buildActiveJobCard(data, taskId, theme, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveJobCard(Map<String, dynamic> data, String taskId, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(data['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('In Progress', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text('Customer: ${data['customerName'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),

          if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(data['imageUrl'], height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ),

          Row(
            children: [
              _buildSmallBadge(Icons.location_on_rounded, data['location'] ?? 'N/A', Colors.redAccent, isDark),
              const Spacer(),
              Text('৳${data['budget']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 0.5),
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          taskId: taskId,
                          otherUserId: data['customerId'] ?? '',
                          otherUserName: data['customerName'] ?? 'Customer',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _completeTask(taskId),
                  icon: _isUpdating
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String text, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.blue[200]),
          ),
          const SizedBox(height: 20),
          const Text('No Active Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('All your accepted jobs will appear here.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}