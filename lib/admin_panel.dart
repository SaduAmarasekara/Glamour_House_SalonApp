import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'admin_add_photo.dart';
import 'manage_specialists.dart';
import 'manage_prices.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});
  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFD81B60);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Admin Suite Pro",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryPink, Color(0xFFFF6090)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Stats", icon: Icon(Icons.analytics_rounded)),
            Tab(text: "Bookings", icon: Icon(Icons.book_online_rounded)),
            Tab(text: "Gallery", icon: Icon(Icons.photo_library_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAppointmentsTab(),
          _buildGalleryManagementTab(),
        ],
      ),
    );
  }

  // --- 1. STATS & OVERVIEW TAB ---
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Business Performance", Icons.trending_up_rounded),
            const SizedBox(height: 18),

            // --- STATS CARDS SECTION (3 CARDS IN ONE ROW) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoDataCard("No appointment data available.");
                }

                int total = snapshot.data!.docs.length;
                int active = snapshot.data!.docs.where((d) => d['status'] == 'pending').length;
                int confirmed = snapshot.data!.docs.where((d) => d['status'] == 'confirmed').length;

                return Row(
                  children: [
                    _statBox("Active", active.toString(), Icons.timer_rounded, Colors.orange),
                    const SizedBox(width: 8),
                    _statBox("Confirmed", confirmed.toString(), Icons.check_circle_rounded, Colors.green),
                    const SizedBox(width: 8),
                    _statBox("Total", total.toString(), Icons.assignment_rounded, const Color(0xFFD81B60)),
                  ],
                );
              },
            ),

            const SizedBox(height: 35),
            _buildSectionHeader("Quick Management", Icons.settings_suggest_rounded),
            const SizedBox(height: 18),
            _buildQuickActionItem(
                "Manage Specialists",
                "Edit salon team profiles",
                Icons.people_rounded,
                Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSpecialists()))
            ),
            _buildQuickActionItem(
                "Price List",
                "Update service pricing",
                Icons.monetization_on_rounded,
                Colors.green,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePrices()))
            ),
            _buildQuickActionItem(
                "Add New Style",
                "Upload style link to gallery",
                Icons.add_a_photo_rounded,
                const Color(0xFFD81B60),
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddPhoto()))
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED StatBox for 3-Column Layout
  Widget _statBox(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. GALLERY MANAGEMENT TAB ---
  Widget _buildGalleryManagementTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gallery').orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildNoDataCard("Gallery is empty.");

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => _confirmDelete(docs[index].id, 'gallery'),
                            child: CircleAvatar(
                                backgroundColor: Colors.red.withOpacity(0.9),
                                radius: 16,
                                child: const Icon(Icons.close_rounded, size: 20, color: Colors.white)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(data['title'] ?? 'Style',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- 3. BOOKINGS TAB ---
  Widget _buildAppointmentsTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFFD81B60),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFD81B60),
            tabs: const [Tab(text: "Pending"), Tab(text: "Confirmed"), Tab(text: "Cancelled")],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredList('pending'),
                _buildFilteredList('confirmed'),
                _buildFilteredList('cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("No $status appointments found."));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            Appointment apt = Appointment.fromFirestore(docs[index]);
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.grey.shade100)
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    child: Icon(_getStatusIcon(status), color: _getStatusColor(status))
                ),
                title: Text(apt.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(apt.service),
                trailing: status == 'pending' ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _updateStatus(apt.id!, 'confirmed')),
                    IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.red), onPressed: () => _updateStatus(apt.id!, 'cancelled')),
                  ],
                ) : null,
              ),
            );
          },
        );
      },
    );
  }

  // --- UI HELPERS ---
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFD81B60).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFFD81B60), size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
      ],
    );
  }

  Widget _buildQuickActionItem(String t, String s, IconData i, Color c, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(i, color: c)
        ),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[300], size: 50),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _updateStatus(String id, String status) {
    FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': status});
  }

  void _confirmDelete(String id, String collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to remove this?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              FirebaseFirestore.instance.collection(collection).doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String s) => s == 'confirmed' ? Colors.green : (s == 'cancelled' ? Colors.red : Colors.orange);
  IconData _getStatusIcon(String s) => s == 'confirmed' ? Icons.done_all : (s == 'cancelled' ? Icons.close : Icons.timer);
}