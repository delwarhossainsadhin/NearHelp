import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../chat_screen.dart';

class ProviderDetailScreen extends StatelessWidget {
  final UserModel provider;

  const ProviderDetailScreen({super.key, required this.provider});

  void _startChat(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final String chatId = "${currentUserId}_${provider.uid}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          taskId: chatId,
          otherUserId: provider.uid,
          otherUserName: provider.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F9FC),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildHeader(context, isDark, theme),

                const SizedBox(height: 60),


                Center(
                  child: Column(
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Professional Provider",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatBadge(context, Icons.work_history_rounded, "Experience", "${provider.experience} Years", Colors.orange),
                      const SizedBox(width: 15),
                      _buildStatBadge(context, Icons.payments_rounded, "Hourly Rate", "৳${provider.hourlyRate}/hr", Colors.green),
                    ],
                  ),
                ),

                const SizedBox(height: 25),


                if (provider.bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('About Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            provider.bio,
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], height: 1.5, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 25),

                // ৫. রিভিউ সেকশন
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Text('Client Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),

                _buildReviewsList(isDark),

                const SizedBox(height: 100),
              ],
            ),
          ),


          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomHireBar(context, theme, isDark),
    );
  }


  Widget _buildHeader(BuildContext context, bool isDark, ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
          ),
        ),
        Positioned(
          bottom: -45,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF0F0F0F) : Colors.white, width: 5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 5)],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey[200],
              backgroundImage: provider.photoUrl.isNotEmpty ? NetworkImage(provider.photoUrl) : null,
              child: provider.photoUrl.isEmpty
                  ? Icon(Icons.person, size: 60, color: theme.colorScheme.primary)
                  : null,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildStatBadge(BuildContext context, IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }


  Widget _buildReviewsList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('providerId', isEqualTo: provider.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));

        final reviews = snapshot.data?.docs ?? [];
        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(25.0),
            child: Text('No reviews from clients yet.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = ReviewModel.fromMap(reviews[index].data() as Map<String, dynamic>);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star_rounded, size: 16,
                          color: i < review.rating ? Colors.amber : Colors.grey.withOpacity(0.3),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.comment, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[700], fontSize: 13)),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildBottomHireBar(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startChat(context),
              icon: const Icon(Icons.chat_bubble_rounded, size: 20),
              label: const Text('Hire & Chat Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}