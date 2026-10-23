import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'provider_detail_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';


  RangeValues _priceRange = const RangeValues(0, 5000);
  double _minRating = 0.0;

  final List<String> _categories = [
    'All', 'Plumber', 'Electrician', 'Tutor', 'Cleaner', 'Painter', 'Carpenter', 'AC Repair', 'Mechanic'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text("Advanced Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 25),


                  Text("Budget Range (৳${_priceRange.start.round()} - ৳${_priceRange.end.round()})",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: _priceRange,
                    min: 0, max: 5000,
                    divisions: 50,
                    labels: RangeLabels('৳${_priceRange.start.round()}', '৳${_priceRange.end.round()}'),
                    onChanged: (values) {
                      setModalState(() => _priceRange = values);
                      setState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: 20),


                  Text("Minimum Rating (${_minRating.toStringAsFixed(1)}+ Stars)",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minRating,
                    min: 0, max: 5,
                    divisions: 5,
                    label: _minRating.toString(),
                    onChanged: (val) {
                      setModalState(() => _minRating = val);
                      setState(() => _minRating = val);
                    },
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [

            _buildSearchHeader(isDark, theme),
            _buildCategoryFilters(isDark, theme),

            Expanded(
              child: _SearchResults(
                query: _query,
                selectedCategory: _selectedCategory,
                priceRange: _priceRange,
                minRating: _minRating,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search Services', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search helper by name...',
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              GestureDetector(
                onTap: () => _showFilterSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCategoryFilters(bool isDark, ThemeData theme) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedCategory = category),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final String query;
  final String selectedCategory;
  final RangeValues priceRange;
  final double minRating;

  const _SearchResults({
    required this.query,
    required this.selectedCategory,
    required this.priceRange,
    required this.minRating,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'provider')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData) return const Center(child: Text('Something went wrong.'));

        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final category = (data['serviceCategory'] ?? '').toString().toLowerCase();
          

          final hourlyRate = double.tryParse((data['hourlyRate'] ?? 0).toString()) ?? 0.0;
          final rating = double.tryParse((data['rating'] ?? 0.0).toString()) ?? 0.0;

          bool matchesQuery = name.contains(query) || category.contains(query);
          bool matchesCategory = selectedCategory == 'All' || (data['serviceCategory'] == selectedCategory);
          bool matchesPrice = hourlyRate >= priceRange.start && hourlyRate <= priceRange.end;
          bool matchesRating = rating >= minRating;

          return matchesQuery && matchesCategory && matchesPrice && matchesRating;
        }).toList();

        if (results.isEmpty) return const Center(child: Text('No providers found matching your filters.'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final data = results[index].data() as Map<String, dynamic>;
            final providerModel = UserModel.fromMap(data);

            return _ProviderSearchCard(data: data, provider: providerModel, isDark: isDark, theme: theme);
          },
        );
      },
    );
  }
}

class _ProviderSearchCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final UserModel provider;
  final bool isDark;
  final ThemeData theme;

  const _ProviderSearchCard({required this.data, required this.provider, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDetailScreen(provider: provider))),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Text(provider.name[0].toUpperCase()),
        ),
        title: Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['serviceCategory'] ?? 'Service', style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('৳${provider.hourlyRate}/hr', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                Text("${data['rating']?.toStringAsFixed(1) ?? '0.0'}", style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}