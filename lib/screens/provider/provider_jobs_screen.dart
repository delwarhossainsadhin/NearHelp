import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});

  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen> {
  bool _isAccepting = false;

  // আধুনিক কনফার্মেশন ডায়ালগ
  Future<void> _acceptTask(String taskId) async {
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
            title: const Text('Accept Job?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to accept this task? It will be moved to your active jobs.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isAccepting = true);

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': 'accepted',
        'acceptedBy': user.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task accepted successfully!'),
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
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) return const Scaffold(body: Center(child: Text('Please log in.')));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Available Jobs', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final category = userData?['serviceCategory'];

          if (category == null || category.toString().isEmpty) {
            return _buildEmptyState(
              Icons.category_rounded,
              'Category Not Set',
              'Go to Profile to set your service category first.',
              isDark,
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('category', isEqualTo: category)
                .where('status', isEqualTo: 'open')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data?.docs ?? [];
              final sortedDocs = List.from(docs);
              sortedDocs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                return (bTime?.toDate() ?? DateTime(2000)).compareTo(aTime?.toDate() ?? DateTime(2000));
              });

              if (sortedDocs.isEmpty) {
                return _buildEmptyState(
                  Icons.work_history_rounded,
                  'No Jobs Found',
                  'Currently there are no $category jobs available.',
                  isDark,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: sortedDocs.length,
                itemBuilder: (context, index) {
                  final data = sortedDocs[index].data() as Map<String, dynamic>;
                  final taskId = sortedDocs[index].id;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  return _buildJobCard(data, taskId, createdAt, theme, isDark);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> data, String taskId, DateTime? createdAt, ThemeData theme, bool isDark) {
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
          // শিরোনাম ও সময়
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['title'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ),
              if (createdAt != null)
                Text(
                  _formatDateTime(createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // কাস্টমার নাম
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(data['customerName'] ?? 'Customer', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            data['description'] ?? '',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 14, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // কাজের ছবি (যদি থাকে)
          if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                data['imageUrl'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // বাজেট ও লোকেশন ব্যাজ
          Row(
            children: [
              _buildBadge(Icons.payments_outlined, '৳${data['budget']}', Colors.green, isDark),
              const SizedBox(width: 10),
              _buildBadge(Icons.location_on_outlined, data['location'] ?? 'N/A', Colors.redAccent, isDark),
            ],
          ),

          const SizedBox(height: 20),

          // বাটন
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAccepting ? null : () => _acceptTask(taskId),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isAccepting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Accept This Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : color), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}