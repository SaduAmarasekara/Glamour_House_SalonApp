import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'models.dart';
import 'admin_add_photo.dart';
import 'favourite_page.dart';

// --- GALLERY DETAIL PAGE ---
class GalleryDetailKey extends StatelessWidget {
  final String imageUrl;
  final String serviceName;
  final String title;

  const GalleryDetailKey({
    super.key,
    required this.imageUrl,
    required this.serviceName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF5F7),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD81B60),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: imageUrl,
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 350,
                fit: BoxFit.cover,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Text(
                "What our customers say ✨",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('serviceName', isEqualTo: serviceName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snapshot.data?.docs ?? [];
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text("No reviews yet for this style.")),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final r = reviews[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFD81B60).withOpacity(0.1),
                          child: Text(r['customerName']?[0].toUpperCase() ?? 'U',
                              style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(r['customerName'] ?? 'Guest User', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(r['comment'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(" ${r['rating']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// --- MAIN GALLERY PAGE ---
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final authService = AuthService();
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',  'Skin Care', 'Facial', 'Coloring', 'Make-up',
    'Waxing', 'Manicure', 'Hair Spa', 'Hair Cut',
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF5F7),
      appBar: AppBar(
        title: const Text("Style Gallery ✨", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFD81B60), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavouritePage())),
          ),
          _buildAdminAddButton(),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryList(isDark),
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
            icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddPhoto())),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoryList(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => setState(() => selectedCategory = categories[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFD81B60)]) : null,
                  color: isSelected ? null : (isDark ? const Color(0xFF1F1F1F) : Colors.white),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF2D1410)), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No photos available"));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GalleryDetailKey(
                      imageUrl: data['imageUrl'],
                      serviceName: data['category'] ?? 'General',
                      title: data['title'] ?? 'Style Detail',
                    ),
                  ),
                );
              },
              child: _buildImageCard(doc.id, data),
            );
          },
        );
      },
    );
  }

  Widget _buildImageCard(String id, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Hero(
                  tag: data['imageUrl'],
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    child: Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('favourites')
                        .doc(id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // මෙතැනදී පින්තූරය favourite කර ඇත්නම් රතු පාටින් පෙන්වයි
                      bool isFav = snapshot.hasData && snapshot.data!.exists;
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                        ),
                        onPressed: () => toggleFavourite(id, data),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? 'Style', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                const SizedBox(height: 4),
                Text(data['category'] ?? '', style: const TextStyle(color: Color(0xFFD81B60), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}