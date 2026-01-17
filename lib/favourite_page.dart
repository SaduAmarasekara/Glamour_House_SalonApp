import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color primaryPink = Color(0xFFD81B60);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Favourites",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryPink,
        centerTitle: true,
        elevation: 0,
        // ආපසු යාමට ඇති Icon එක සුදු පැහැ ගැන්වීම
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? const Center(child: Text("Please login to see your favourites"))
          : StreamBuilder<QuerySnapshot>(
        // Gallery එකේදී Like කළ දත්ත මෙතැනින් ලබාගනී
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favourites')
            .orderBy('favouritedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPink));
          }

          // දත්ත කිසිවක් නොමැති විට පෙන්වන UI එක
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No favourites yet!",
                      style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text("Like some styles in the gallery to see them here.",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // දත්ත පවතින විට Grid එකක් ලෙස පෙන්වීම
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // පේළියකට දෙක බැගින්
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.75,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return _buildFavouriteCard(context, doc.id, data, user.uid);
            },
          );
        },
      ),
    );
  }

  // Favourite Card එක නිර්මාණය කිරීම
  Widget _buildFavouriteCard(BuildContext context, String id, Map<String, dynamic> data, String uid) {
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
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                  ),
                ),
                // Like එක අයින් කිරීමට ඇති බටන් එක
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('favourites')
                          .doc(id)
                          .delete();
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      radius: 16,
                      child: const Icon(Icons.favorite, color: Colors.red, size: 18),
                    ),
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
                Text(
                  data['title'] ?? 'Style',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data['category'] ?? '',
                  style: const TextStyle(color: Color(0xFFD81B60), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}