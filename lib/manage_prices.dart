import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class ManagePrices extends StatelessWidget {
  const ManagePrices({super.key});

  final List<String> availableServices = const [
    'Skin Care', 'Facial', 'Coloring', 'Make-up',
    'Waxing', 'Manicure', 'Hair Spa', 'Hair Cut',
  ];

  // සේවාවට ගැළපෙන අයිකනය ලබා ගැනීමට
  IconData _getServiceIcon(String serviceName) {
    switch (serviceName) {
      case 'Skin Care': return Icons.face_retouching_natural;
      case 'Facial': return Icons.spa;
      case 'Coloring': return Icons.color_lens;
      case 'Make-up': return Icons.brush;
      case 'Waxing': return Icons.dry_cleaning;
      case 'Manicure': return Icons.back_hand;
      case 'Hair Spa': return Icons.waves;
      case 'Hair Cut': return Icons.content_cut;
      default: return Icons.auto_fix_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF5F7),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Service Price List 💰",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22),
        ),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: Container(
        height: 65, width: 65,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFD81B60)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFFD81B60).withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 35),
          onPressed: () => _showServiceDialog(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              SalonService service = SalonService.fromFirestore(doc);

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                  border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 55, height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD81B60).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(_getServiceIcon(service.name), color: const Color(0xFFD81B60), size: 28),
                    ),
                    title: Text(
                      service.name,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: isDark ? Colors.white : Colors.black87),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(service.duration ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Rs. ${service.price.toStringAsFixed(0)}",
                          style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () => _confirmDelete(context, service.id!),
                          child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
                        )
                      ],
                    ),
                    onTap: () => _showServiceDialog(context, service: service),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("No services listed yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Text("Tap + to add your first service price", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String serviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Service?"),
        content: const Text("Are you sure you want to remove this service price from the list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('services').doc(serviceId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? "Update Service ✨" : "Add New Service ✨", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Service Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedServiceName,
                    hint: const Text("Select Service Name"),
                    items: availableServices.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedServiceName = v),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              _buildModernTextField(priceCtrl, "Price (Rs.)", Icons.money, isDark, type: TextInputType.number),
              _buildModernTextField(durCtrl, "Duration (e.g. 45 mins)", Icons.timer, isDark),

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
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
                  child: Text(isEdit ? "Update Price" : "Save Service", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController ctrl, String hint, IconData icon, bool isDark, {TextInputType type = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFD81B60)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}