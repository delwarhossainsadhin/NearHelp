import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat_screen.dart';
import '../../models/review_model.dart';
import 'payment_screen.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showRatingDialog(BuildContext context, String taskId, String providerId, String customerName) {
    double selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1,
          child: StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              title: const Text('Rate the Service', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How was your experience with this provider?', textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () => setState(() => selectedRating = index + 1.0),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Later', style: TextStyle(color: Colors.grey[600]))),
                ElevatedButton(
                  onPressed: () async {
                    final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
                    final review = ReviewModel(
                      reviewId: reviewRef.id,
                      taskId: taskId,
                      customerId: FirebaseAuth.instance.currentUser!.uid,
                      customerName: customerName,
                      providerId: providerId,
                      rating: selectedRating,
                      comment: commentController.text.trim(),
                      createdAt: DateTime.now(),
                    );

                    await reviewRef.set(review.toMap());
                    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'hasReview': true});

                    final providerDoc = await FirebaseFirestore.instance.collection('users').doc(providerId).get();
                    if (providerDoc.exists) {
                      final data = providerDoc.data() as Map<String, dynamic>;
                      double currentRating = (data['rating'] ?? 0.0).toDouble();
                      int currentReviewCount = data['reviewCount'] ?? 0;
                      double newRating = ((currentRating * currentReviewCount) + selectedRating) / (currentReviewCount + 1);
                      await FirebaseFirestore.instance.collection('users').doc(providerId).update({
                        'rating': newRating,
                        'reviewCount': currentReviewCount + 1,
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Submit Review'),
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
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const Center(child: Text('Not logged in'));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').where('customerId', isEqualTo: user.uid).snapshots(),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No bookings found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              final taskId = sortedDocs[index].id;
              final status = data['status'] ?? 'open';
              final budget = (data['budget'] ?? 0.0).toDouble();

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
                        Expanded(child: Text(data['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(data['category'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),

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
                        _buildInfoBadge(Icons.payments_rounded, '৳$budget', Colors.green, isDark),
                        const SizedBox(width: 10),
                        _buildInfoBadge(Icons.location_on_rounded, data['location'] ?? 'N/A', Colors.redAccent, isDark),
                      ],
                    ),


                    if (status != 'open' && data['acceptedBy'] != null) ...[
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, thickness: 0.5)),
                      _buildProviderSection(context, data['acceptedBy'], taskId, data, isDark),
                    ],


                    if (status == 'completed' && data['acceptedBy'] != null) ...[
                      const SizedBox(height: 16),
                      if (data['paymentStatus'] == 'unpaid')
                        _buildActionButton(
                          label: 'Pay Now',
                          icon: Icons.payment_rounded,
                          color: Colors.pink[400]!,
                          onTap: () async {
                            final doc = await FirebaseFirestore.instance.collection('users').doc(data['acceptedBy']).get();
                            final pName = doc.data()?['name'] ?? 'Provider';
                            if (context.mounted) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(taskId: taskId, amount: budget, providerName: pName)));
                            }
                          },
                        ),
                      if (data['hasReview'] == false)
                        _buildActionButton(
                          label: 'Rate Service',
                          icon: Icons.star_rounded,
                          color: Colors.amber[700]!,
                          onTap: () => _showRatingDialog(context, taskId, data['acceptedBy'], data['customerName'] ?? 'Customer'),
                        ),
                      if (data['paymentStatus'] == 'paid' && data['hasReview'] == true)
                        const Center(child: Text('Completed & Paid! ⭐', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildProviderSection(BuildContext context, String providerId, String taskId, Map<String, dynamic> data, bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(providerId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        final pData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final pName = pData?['name'] ?? 'Provider';

        return Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: Colors.deepPurple.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.deepPurple, size: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Text('Service Provider', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const Spacer(),
            if (data['status'] == 'accepted')
              IconButton.filledTonal(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(taskId: taskId, otherUserId: providerId, otherUserName: pName))),
                icon: const Icon(Icons.chat_bubble_rounded, size: 20),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
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

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        ),
      ),
    );
  }
}