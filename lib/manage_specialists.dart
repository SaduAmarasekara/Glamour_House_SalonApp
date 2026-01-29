import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class ManageSpecialists extends StatelessWidget {
  const ManageSpecialists({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF5F7),
      appBar: AppBar(
        title: const Text("Salon Team", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD81B60), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD81B60),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        onPressed: () => _showSpecialistBottomSheet(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('specialists').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No specialists added yet.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              SpecialistModel person = SpecialistModel.fromFirestore(doc);

              return Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: const Color(0xFFD81B60).withOpacity(0.1)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(person.imageUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                  title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.specialization, style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(" ${person.rating}  |  ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Icon(Icons.phone_iphone, size: 14, color: Colors.grey),
                          Text(" ${person.phone ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- නවීන BOTTOM SHEET එක (Form එක මෙහි ඇත) ---
  void _showSpecialistBottomSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ratingCtrl = TextEditingController();
    final imgCtrl = TextEditingController();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Keyboard එක නිසා Form එක උඩට ඒමට මෙය අත්‍යවශ්‍යයි
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Keyboard එකට ඉඩ තැබීම
          left: 25, right: 25, top: 25,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Specialist ✨", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
              const SizedBox(height: 20),
              _buildField(nameCtrl, "Full Name", Icons.person),
              _buildField(specCtrl, "Expertise (e.g. Hair Stylist)", Icons.work),
              _buildField(phoneCtrl, "Phone Number", Icons.phone, type: TextInputType.phone),
              _buildField(ratingCtrl, "Rating (1.0 - 5.0)", Icons.star, type: TextInputType.number),
              _buildField(imgCtrl, "Image URL", Icons.link),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || imgCtrl.text.isEmpty) return;

                    SpecialistModel newSpecialist = SpecialistModel(
                      name: nameCtrl.text.trim(),
                      imageUrl: imgCtrl.text.trim(),
                      specialization: specCtrl.text.trim(),
                      rating: double.tryParse(ratingCtrl.text) ?? 5.0,
                      phone: phoneCtrl.text.trim(),
                    );

                    await FirebaseFirestore.instance.collection('specialists').add(newSpecialist.toMap());
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Save Specialist", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFD81B60), size: 20),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Specialist?"),
        content: const Text("Are you sure you want to remove this person?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              FirebaseFirestore.instance.collection('specialists').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}