import '../edit_profile_screen.dart'; // পাথ ঠিক করা হলো
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../main.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
                ),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Use camera to capture photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateProfileImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Select image from device storage'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfileImage(ImageSource source) async {
    try {
      final File? image = await _storageService.pickImage(source: source);
      if (image == null) return;

      setState(() => _isUploading = true);

      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final String? imageUrl = await _storageService.uploadImage(image, 'profile_pictures');

      if (imageUrl != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': imageUrl,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully! 📸'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('unauthorized')) {
          errorMsg = 'Firebase Storage permission denied. Please check Storage Rules in Firebase Console.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $errorMsg'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('User not found'));
          final userData = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return SingleChildScrollView(
            child: Column(
              children: [
                // ১. গ্র্যাডিয়েন্ট হেডার ও কার্ভ ডিজাইন
                SizedBox(
                  height: 240,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
                        ),
                      ),
                      const Positioned(
                        top: 55,
                        child: Text(
                          "My Profile",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                      Positioned(
                        top: 45,
                        right: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditProfileScreen(user: userData)),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF0F0F0F) : Colors.white, width: 4),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: userData.photoUrl.isNotEmpty ? NetworkImage(userData.photoUrl) : null,
                                child: userData.photoUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
                              ),
                            ),
                            if (_isUploading)
                              const Center(child: CircularProgressIndicator(color: Colors.white)),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Material(
                                color: theme.colorScheme.secondary,
                                shape: const CircleBorder(),
                                elevation: 3,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _isUploading ? null : _showImageSourcePicker,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // ২. নাম এবং রোল (ডাইনামিক করা হলো)
                Text(userData.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      userData.role == 'provider' ? "Professional Provider" : "Valued Customer",
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)
                  ),
                ),

                const SizedBox(height: 30),

                // ৩. ইনফরমেশন লিস্ট
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Account Information", isDark),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(context, Icons.email_rounded, "Email Address", userData.email, Colors.blue),
                            _buildDivider(isDark),
                            _buildInfoTile(context, Icons.phone_android_rounded, "Phone Number", userData.phone, Colors.orange),
                            _buildDivider(isDark),
                            _buildInfoTile(context, Icons.calendar_month_rounded, "Member Since", "August 2024", Colors.purple),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      _buildLabel("Preferences", isDark),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
                        ),
                        child: SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.dark_mode_rounded, color: Colors.grey),
                          ),
                          title: const Text("Dark Mode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          value: themeNotifier.value == ThemeMode.dark,
                          activeColor: theme.colorScheme.primary,
                          onChanged: (v) async {
                            themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isDarkMode', v);
                            setState(() {});
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // লগআউট বাটন
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // হেল্পার মেথডগুলো (Label, Divider, InfoTile)
  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 70, endIndent: 20, color: isDark ? Colors.white10 : Colors.grey[100]);
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
    );
  }
}