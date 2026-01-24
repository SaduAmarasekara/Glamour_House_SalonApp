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
  final _urlController = TextEditingController(); // පින්තූර ලින්ක් එක සඳහා
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  String _selectedCategory = 'Hair Styling';
  bool _isUploading = false;

  final List<String> categories = [
    'All',  'Skin Care', 'Facial', 'Coloring', 'Make-up',
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

      // පින්තූරය අප්ලෝඩ් කරන්නේ නැතිව කෙලින්ම URL එක Firestore එකට යැවීම
      GalleryPhoto photo = GalleryPhoto(
        imageUrl: _urlController.text.trim(), // ලින්ක් එක මෙතැනට
        title: _titleController.text.trim(),
        category: _selectedCategory,
        uploadedAt: DateTime.now(),
        uploadedBy: user.uid,
      );

      await _firestore.collection('gallery').add(photo.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Style link added successfully!'), backgroundColor: Colors.green),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD81B60),
        title: const Text('Add Style Link', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                  ),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _urlController,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link_rounded, size: 50, color: const Color(0xFFD81B60).withOpacity(0.3)),
                            const Text("Image Preview will appear here", style: TextStyle(color: Colors.grey)),
                          ],
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          value.text,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(child: Text("Invalid Image Link")),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // --- IMAGE URL INPUT ---
                _buildLabel("Image URL (Link)"),
                TextFormField(
                  controller: _urlController,
                  decoration: _inputDecoration("https://example.com/image.jpg", Icons.image_search_rounded),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please paste an image link' : null,
                ),
                const SizedBox(height: 20),

                // --- TITLE INPUT ---
                _buildLabel("Style Title"),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration("e.g. Modern Fade Cut", Icons.edit),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),

                // --- CATEGORY DROPDOWN ---
                _buildLabel("Choose Category"),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _inputDecoration(null, Icons.category_rounded),
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
                        : const Text('Save to Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
  );

  InputDecoration _inputDecoration(String? hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFFD81B60)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(vertical: 18),
  );
}