import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'models.dart';
import 'admin_add_photo.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final authService = AuthService();
  String selectedCategory = 'All'; // Default category

  final List<String> categories = [
    'All', 'Hair Styling', 'Hair Color', 'Makeup', 'Nail Art', 'Skin Care', 'Beard'
  ];

  // Favourite පද්ධතිය - Firestore හි 'favourites' collection එකට එක් කිරීම
  Future<void> toggleFavourite(String photoId, Map<String, dynamic> photoData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favourites')
        .doc(photoId);

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete(); // දැනටමත් තිබේ නම් අයින් කරන්න
    } else {
      await favRef.set({
        ...photoData,
        'favouritedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Style Gallery", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          _buildAdminAddButton(),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryList(), // Category Filter එක
          Expanded(child: _buildPhotoGrid()),
        ],
      ),
    );
  }

  Widget _buildAdminAddButton() {
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.role == 'admin') {
          return IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddPhoto())),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Category තේරීම සඳහා තිරස් ලැයිස්තුවක් (Horizontal List)
  Widget _buildCategoryList() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => selectedCategory = categories[index]);
              },
              selectedColor: const Color(0xFFE91E63),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid() {
    // තේරූ Category එක අනුව Query එක වෙනස් කිරීම
    Query query = FirebaseFirestore.instance.collection('gallery');
    if (selectedCategory != 'All') {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No photos available for this category."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return _buildImageCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildImageCard(String id, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity),
                ),
                // Favourite Button
                Positioned(
                  top: 5, right: 5,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users').doc(user?.uid).collection('favourites').doc(id).snapshots(),
                    builder: (context, favSnapshot) {
                      bool isFav = favSnapshot.hasData && favSnapshot.data!.exists;
                      return CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.7),
                        child: IconButton(
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                          onPressed: () => toggleFavourite(id, data),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'Style', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(data['category'] ?? '', style: const TextStyle(color: Color(0xFFE91E63), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}