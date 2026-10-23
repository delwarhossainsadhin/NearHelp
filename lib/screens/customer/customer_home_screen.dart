import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_profile_screen.dart';
import 'provider_list_screen.dart';
import 'post_task_screen.dart';
import '../notification_screen.dart';
import 'customer_search_screen.dart';
import 'customer_bookings_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;


    final List<Widget> _screens = [
      _CustomerHomeContent(onSearchTap: () => _onItemTapped(1)),
      const CustomerSearchScreen(),
      const CustomerBookingsScreen(),
      const CustomerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F9FC),
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
                        child: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.primary),
                      )
                    : Icon(Icons.notifications_none_rounded, color: theme.colorScheme.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostTaskScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Post Task', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
      )
          : null,
      bottomNavigationBar: NavigationBar(
        elevation: 10,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CustomerHomeContent extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _CustomerHomeContent({required this.onSearchTap});

  // ক্যাটাগরি লিস্ট
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Plumber', 'icon': Icons.plumbing_rounded, 'color': Colors.blue},
    {'name': 'Electrician', 'icon': Icons.electrical_services_rounded, 'color': Colors.orange},
    {'name': 'Tutor', 'icon': Icons.school_rounded, 'color': Colors.purple},
    {'name': 'Cleaner', 'icon': Icons.cleaning_services_rounded, 'color': Colors.teal},
    {'name': 'Painter', 'icon': Icons.format_paint_rounded, 'color': Colors.pink},
    {'name': 'Carpenter', 'icon': Icons.carpenter_rounded, 'color': Colors.brown},
    {'name': 'AC Repair', 'icon': Icons.ac_unit_rounded, 'color': Colors.cyan},
    {'name': 'Mechanic', 'icon': Icons.build_circle_rounded, 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What service do\nyou need today?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 20),


                InkWell(
                  onTap: onSearchTap,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Search for services...',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(22, 20, 20, 10),
            child: Text(
              'Popular Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),


          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _CategoryCard(
                name: category['name'] as String,
                icon: category['icon'] as IconData,
                accentColor: category['color'] as Color,
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color accentColor;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProviderListScreen(category: name)),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: accentColor),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}