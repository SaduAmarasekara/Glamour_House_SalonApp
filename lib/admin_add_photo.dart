import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'models.dart';

class AdminAddPhoto extends StatefulWidget {
  const AdminAddPhoto({super.key});

  @override
  State<AdminAddPhoto> createState() => _AdminAddPhotoState();
}

class _AdminAddPhotoState extends State<AdminAddPhoto> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  // ආරම්භක අගය (Initial Value) අනිවාර්යයෙන්ම පහත ලිස්ට් එකේ තිබිය යුතුය.
  String _selectedCategory = 'Hair Cut';
  bool _isUploading = false;

  // GalleryPage එකේ තියෙන ලිස්ට් එකටම සමාන විය යුතුය.
  final List<String> categories = [
    'Skin Care', 'Facial', 'Coloring', 'Make-up',
    'Waxing', 'Manicure', 'Hair Spa', 'Hair Cut',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _uploadPhoto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      UserModel? user = await _authService.getCurrentUserData();
      if (user == null) throw Exception('User not found');

      // GalleryPhoto model එක හරහා data සකස් කිරීම
      GalleryPhoto photo = GalleryPhoto(
        imageUrl: _urlController.text.trim(),
        title: _titleController.text.trim(),
        category: _selectedCategory, // තෝරාගත් Category එක Firestore වෙත යයි
        uploadedAt: DateTime.now(),
        uploadedBy: user.uid,
      );

      await _firestore.collection('gallery').add(photo.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New style added to Gallery! ✨'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD81B60),
        title: const Text('Add New Style', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- PREVIEW BOX ---
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                    border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.2)),
                  ),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _urlController,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 50, color: const Color(0xFFD81B60).withOpacity(0.3)),
                            const Text("Live Image Preview", style: TextStyle(color: Colors.grey)),
                          ],
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          value.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.red),
                                Text("Invalid Image Link", style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // --- IMAGE URL INPUT ---
                _buildLabel("Image Direct Link (URL)", isDark),
                TextFormField(
                  controller: _urlController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: _inputDecoration("https://example.com/image.jpg", Icons.link, isDark),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please paste an image link' : null,
                ),
                const SizedBox(height: 20),

                // --- TITLE INPUT ---
                _buildLabel("Style Name / Title", isDark),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: _inputDecoration("e.g. Bridal Make-up", Icons.title, isDark),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),

                // --- CATEGORY DROPDOWN ---
                _buildLabel("Style Category", isDark),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16),
                  decoration: _inputDecoration(null, Icons.category_rounded, isDark),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                ),
                const SizedBox(height: 40),

                // --- SUBMIT BUTTON ---
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Publish Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87)),
  );

  InputDecoration _inputDecoration(String? hint, IconData icon, bool isDark) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    prefixIcon: Icon(icon, color: const Color(0xFFD81B60)),
    filled: true,
    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: const Color(0xFFD81B60).withOpacity(0.1)),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
  );
}