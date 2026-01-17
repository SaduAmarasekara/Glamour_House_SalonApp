import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'models.dart';
import 'admin_add_photo.dart';
import 'favourite_page.dart'; // FavouritePage එක Import කරන්න

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final authService = AuthService();
  String selectedCategory = 'All';

  final List<String> categories = [
    'All', 'Hair Styling', 'Hair Color', 'Makeup', 'Nail Art', 'Skin Care', 'Beard'
  ];

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
      await favRef.delete();
    } else {
      await favRef.set({
        ...photoData,
        'favouritedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFD81B60);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Style Gallery", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryPink,
        centerTitle: true,
        elevation: 0,
        actions: [
          // 1. Favourite Page එකට යන Love Icon එක (ඕනෑම අයෙකුට පෙනේ)
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavouritePage())
            ),
          ),
          // 2. Admin ට පමණක් පෙනෙන Add Photo Button එක
          _buildAdminAddButton(),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryList(),
          Expanded(child: _buildPhotoGrid()),
        ],
      ),
    );
  }

  // Admin කෙනෙක් නම් පමණක් අලුත් ඡායාරූප එක් කිරීමේ බොත්තම පෙන්වයි
  Widget _buildAdminAddButton() {
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.role == 'admin') {
          return IconButton(
            icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminAddPhoto())
            ),
          );
        }
        return const SizedBox.shrink(); // Admin නොවේ නම් කිසිවක් පෙන්වන්නේ නැත
      },
    );
  }

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
              selectedColor: const Color(0xFFD81B60),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoGrid() {
    Query query = FirebaseFirestore.instance.collection('gallery');
    if (selectedCategory != 'All') {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    data['imageUrl'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users').doc(user?.uid).collection('favourites').doc(id).snapshots(),
                    builder: (context, favSnapshot) {
                      bool isFav = favSnapshot.hasData && favSnapshot.data!.exists;
                      return GestureDetector(
                        onTap: () => toggleFavourite(id, data),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          radius: 18,
                          child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 20
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Style',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                    data['category'] ?? '',
                    style: const TextStyle(color: Color(0xFFD81B60), fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}