import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart'; // SalonService model එක සඳහා

class ManagePrices extends StatelessWidget {
  const ManagePrices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Service Price List", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // අලුතින් සේවාවක් එක් කිරීමට බොත්තමක්
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add_business_rounded, color: Colors.white),
        onPressed: () => _showServiceDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No services found. Add your first service!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              SalonService service = SalonService.fromFirestore(doc); // Model භාවිතය

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[50],
                    child: Icon(Icons.content_cut_rounded, color: Colors.green[700]),
                  ),
                  title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("Category: ${service.category} | ${service.duration ?? 'N/A'}", style: TextStyle(color: Colors.grey[600])),
                  trailing: Text(
                    "Rs. ${service.price.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  onTap: () => _showServiceDialog(context, service: service), // Edit කිරීම සඳහා
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- ADD / EDIT සේවා සඳහා පොදු DIALOG එක ---
  void _showServiceDialog(BuildContext context, {SalonService? service}) {
    final isEdit = service != null;
    final nameCtrl = TextEditingController(text: service?.name ?? "");
    final priceCtrl = TextEditingController(text: service?.price.toString() ?? "");
    final catCtrl = TextEditingController(text: service?.category ?? "Hair");
    final durCtrl = TextEditingController(text: service?.duration ?? "30 mins");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? "Update Price" : "Add New Service", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(nameCtrl, "Service Name", Icons.edit),
              _buildField(priceCtrl, "Price (Rs.)", Icons.money, type: TextInputType.number),
              _buildField(catCtrl, "Category (e.g. Hair, Skin)", Icons.category),
              _buildField(durCtrl, "Duration (e.g. 1 hour)", Icons.timer),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;

              // SalonService object එකක් සාදා ගැනීම
              SalonService updatedData = SalonService(
                name: nameCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text) ?? 0.0,
                category: catCtrl.text.trim(),
                duration: durCtrl.text.trim(),
              );

              if (isEdit) {
                // පවතින සේවාව Update කිරීම
                await FirebaseFirestore.instance.collection('services').doc(service.id).update(updatedData.toMap());
              } else {
                // අලුත් සේවාවක් Add කිරීම
                await FirebaseFirestore.instance.collection('services').add(updatedData.toMap());
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? "Update Now" : "Save Service", style: const TextStyle(color: Colors.white)),
          ),
        ],
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
          prefixIcon: Icon(icon, color: Colors.green[700], size: 20),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}