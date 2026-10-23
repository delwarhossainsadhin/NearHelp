import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import 'dart:io';
import '../../services/storage_service.dart';
import '../../widgets/success_dialog.dart';

class PostTaskScreen extends StatefulWidget {
  const PostTaskScreen({super.key});

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedCategory;
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _categories = [
    'Plumber', 'Electrician', 'Tutor', 'Cleaner', 'Painter', 'Carpenter', 'AC Repair', 'Mechanic',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _postTask() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? uploadedImageUrl;
      if (_imageFile != null) {
        uploadedImageUrl = await _storageService.uploadImage(_imageFile!, 'task_images');
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final customerName = userDoc.data()?['name'] ?? 'Unknown';

      final taskRef = FirebaseFirestore.instance.collection('tasks').doc();

      final task = TaskModel(
        taskId: taskRef.id,
        customerId: user.uid,
        customerName: customerName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        budget: double.parse(_budgetController.text.trim()),
        location: _locationController.text.trim(),
        imageUrl: uploadedImageUrl,
        status: 'open',
        createdAt: DateTime.now(),
      );

      await taskRef.set(task.toMap());

      if (!context.mounted) return;


      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(
          message: "Your task has been posted successfully! Providers will see it soon.",
          onDone: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Create New Task', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(isDark),
              const SizedBox(height: 25),
              _buildSectionTitle("Task Details", isDark),
              _buildModernTextField(
                controller: _titleController,
                label: 'Task Title (e.g. Need a Painter)',
                icon: Icons.title_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildModernDropdown(isDark),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _descriptionController,
                label: 'Tell us more about the job...',
                icon: Icons.description_outlined,
                maxLines: 4,
                isDark: isDark,
              ),
              const SizedBox(height: 25),
              _buildSectionTitle("Additional Info", isDark),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _budgetController,
                      label: 'Budget (৳)',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Post Task Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final file = await _storageService.pickImage();
        if (file != null) setState(() => _imageFile = file);
      },
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: _imageFile != null
            ? ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.file(_imageFile!, fit: BoxFit.cover))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.add_a_photo_rounded, size: 30, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            const Text('Add a photo of the problem', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Text('(Optional)', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDark = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
    );
  }

  Widget _buildModernDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Service Category',
        prefixIcon: const Icon(Icons.category_rounded, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }
}