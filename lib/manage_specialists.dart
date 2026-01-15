import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart'; // SpecialistModel එක සඳහා

class ManageSpecialists extends StatelessWidget {
  const ManageSpecialists({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Salon Specialists", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFD81B60),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD81B60),
        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        onPressed: () => _showSpecialistDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('specialists').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No specialists added yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              SpecialistModel person = SpecialistModel.fromFirestore(doc); // Model එක භාවිතා කළා

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(person.imageUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                  title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person.specialization, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(" ${person.rating} | ", style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey),
                          Text(" ${person.phone ?? 'N/A'}", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
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

  // --- දත්ත ඇතුළත් කරන DIALOG එක ---
  void _showSpecialistDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ratingCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Specialist", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD81B60))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(nameCtrl, "Full Name", Icons.person),
              _buildField(specCtrl, "Expertise (e.g. Hair Stylist)", Icons.work),
              _buildField(phoneCtrl, "Phone Number", Icons.phone, type: TextInputType.phone),
              _buildField(ratingCtrl, "Rating (1.0 - 5.0)", Icons.star, type: TextInputType.number),
              _buildField(imgCtrl, "Image URL (Link)", Icons.image),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || imgCtrl.text.isEmpty) return;

              // Firestore එකට දත්ත යැවීම
              SpecialistModel newSpecialist = SpecialistModel(
                name: nameCtrl.text.trim(),
                imageUrl: imgCtrl.text.trim(),
                specialization: specCtrl.text.trim(),
                rating: double.tryParse(ratingCtrl.text) ?? 5.0,
                phone: phoneCtrl.text.trim(),
              );

              await FirebaseFirestore.instance.collection('specialists').add(newSpecialist.toMap());
              Navigator.pop(context);
            },
            child: const Text("Save Specialist", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: INPUT FIELD ---
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
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Specialist?"),
        content: const Text("Are you sure you want to remove this person from the team?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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