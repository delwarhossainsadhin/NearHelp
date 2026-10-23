import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'provider_jobs_screen.dart';
import 'provider_accepted_jobs_screen.dart';
import 'provider_profile_screen.dart';
import '../notification_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _ProviderHomeContent(),
    const ProviderJobsScreen(),
    const ProviderAcceptedJobsScreen(),
    const ProviderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
        title: Text(
          'NearHelp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              return IconButton(
                icon: unreadCount > 0
                    ? Badge(
                        label: Text('$unreadCount'),
                        child: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
                      )
                    : Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        elevation: 10,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'My Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProviderHomeContent extends StatefulWidget {
  const _ProviderHomeContent();

  @override
  State<_ProviderHomeContent> createState() => _ProviderHomeContentState();
}

class _ProviderHomeContentState extends State<_ProviderHomeContent> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _rateController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;
  bool _isSaved = false;

  static const List<String> _categories = [
    'Plumber', 'Electrician', 'Tutor', 'Cleaner', 'Painter', 'Carpenter', 'AC Repair', 'Mechanic',
  ];

  @override
  void dispose() {
    _experienceController.dispose();
    _rateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a service category')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'serviceCategory': _selectedCategory,
        'experienceYears': _experienceController.text.trim(),
        'hourlyRate': _rateController.text.trim(),
        'bio': _bioController.text.trim(),
      });

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // স্বাগতম সেকশন
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Setup',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Fill in your professional details to start getting jobs.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.stars_rounded, color: Colors.white.withOpacity(0.5), size: 50),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // ফর্ম কার্ড
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildDropdown(),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _experienceController,
                    label: 'Years of Experience',
                    icon: Icons.history_rounded,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _rateController,
                    label: 'Hourly Rate (৳)',
                    icon: Icons.payments_outlined,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Short Bio',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                        _isSaved ? 'Update Service Profile' : 'Save & Start Working',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: _inputDecoration('Service Category', Icons.category_outlined),
      items: _categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon),
      validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.grey[100],
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}