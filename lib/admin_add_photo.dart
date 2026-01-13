import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  File? _selectedImage;
  String _selectedCategory = 'Hair Styling';
  bool _isUploading = false;

  final List<String> categories = [
    'Hair Styling',
    'Hair Color',
    'Makeup',
    'Nail Art',
    'Skin Care',
    'Beard',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      UserModel? user = await _authService.getCurrentUserData();
      if (user == null) throw Exception('User not found');

      // Firebase Storage එකට පින්තූරය Upload කිරීම
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('gallery/$fileName.jpg');

      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore එකේ දත්ත ගබඩා කිරීම
      GalleryPhoto photo = GalleryPhoto(
        imageUrl: downloadUrl,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        uploadedAt: DateTime.now(),
        uploadedBy: user.uid,
      );

      await _firestore.collection('gallery').add(photo.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Style added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Dashboard එකේ පසුබිම් වර්ණය
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD81B60), // ඔබේ ප්‍රධාන Pink වර්ණය
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
                // --- IMAGE PICKER CARD ---
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                      border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.1), width: 2),
                    ),
                    child: _selectedImage == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 70, color: const Color(0xFFD81B60).withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('Tap to choose a stunning style', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
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
                // --- UPLOAD BUTTON ---
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                      shadowColor: const Color(0xFFD81B60).withOpacity(0.4),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add to Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER UI METHODS ---
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