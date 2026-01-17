import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class ManagePrices extends StatelessWidget {
  const ManagePrices({super.key});

  final List<String> availableServices = const [
    'Skin Care', 'Facial', 'Coloring', 'Make-up',
    'Waxing', 'Manicure', 'Hair Spa', 'Hair Cut',
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFD81B60);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Manage Service Prices",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryPink,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPink,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () => _showServiceDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPink));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No services found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              SalonService service = SalonService.fromFirestore(doc);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: primaryPink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.auto_fix_high_rounded, color: primaryPink),
                  ),
                  title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("Duration: ${service.duration ?? 'N/A'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Rs. ${service.price.toStringAsFixed(0)}",
                        style: const TextStyle(color: primaryPink, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                        onPressed: () => _confirmDelete(context, service.id!),
                      ),
                    ],
                  ),
                  onTap: () => _showServiceDialog(context, service: service),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- DELETE CONFIRMATION DIALOG ---
  void _confirmDelete(BuildContext context, String serviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to remove this service?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('services').doc(serviceId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Yes, Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showServiceDialog(BuildContext context, {SalonService? service}) {
    final isEdit = service != null;
    String? selectedServiceName = service?.name;
    final priceCtrl = TextEditingController(text: service?.price.toString() ?? "");
    final durCtrl = TextEditingController(text: service?.duration ?? "30 mins");
    const Color primaryPink = Color(0xFFD81B60);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? "Update Service" : "Add Service", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Service"),
                      value: selectedServiceName,
                      items: availableServices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => selectedServiceName = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(priceCtrl, "Price (Rs.)", Icons.payments_rounded, type: TextInputType.number),
                _buildField(durCtrl, "Duration (e.g. 1 hour)", Icons.timer_rounded),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                if (selectedServiceName == null || priceCtrl.text.isEmpty) return;

                SalonService updatedData = SalonService(
                  name: selectedServiceName!,
                  price: double.tryParse(priceCtrl.text) ?? 0.0,
                  category: "Salon",
                  duration: durCtrl.text.trim(),
                );

                if (isEdit) {
                  await FirebaseFirestore.instance.collection('services').doc(service.id).update(updatedData.toMap());
                } else {
                  await FirebaseFirestore.instance.collection('services').add(updatedData.toMap());
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(isEdit ? "Update" : "Save", style: const TextStyle(color: Colors.white)),
            ),
          ],
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
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}