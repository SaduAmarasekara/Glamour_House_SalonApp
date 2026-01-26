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
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFF5F7),
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B9D), Color(0xFFD81B60), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          // --- වර්ණයන් වෙනස් කළ ස්ථානය ---
          labelColor: Colors.white, // තෝරාගත් Tab එකේ අකුරු සුදු පැහැයට
          unselectedLabelColor: Colors.white70, // තෝරා නොගත් Tab එකේ අකුරු ලා සුදු පැහැයට
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          _buildOverviewTab(isDark),
          _buildAppointmentsTab(),
          _buildGalleryManagementTab(isDark),
        ],
      ),
    );
  }

  // --- 1. Stats Tab ---
  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader("Real-time Stats", Icons.speed_rounded, isDark),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              int completed = snapshot.data!.docs.where((d) => d['status'] == 'completed').length;
              int active = snapshot.data!.docs.where((d) => d['status'] == 'pending').length;
              int confirmed = snapshot.data!.docs.where((d) => d['status'] == 'confirmed').length;
              return Row(
                children: [
                  _statBox("Pending", active.toString(), Icons.timer, Colors.orange, isDark),
                  const SizedBox(width: 10),
                  _statBox("Confirmed", confirmed.toString(), Icons.check_circle, Colors.green, isDark),
                  const SizedBox(width: 10),
                  _statBox("Finished", completed.toString(), Icons.done_all, const Color(0xFFD81B60), isDark),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          _buildSectionHeader("Quick Actions", Icons.bolt_rounded, isDark),
          const SizedBox(height: 15),
          _buildQuickActionItem("Manage Specialists", "Team profiles", Icons.people, Colors.blue, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSpecialists()))),
          _buildQuickActionItem("Price List", "Service costs", Icons.monetization_on, Colors.green, isDark, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePrices()))),
          _buildQuickActionItem("New Gallery Style", "Upload link", Icons.add_photo_alternate, const Color(0xFFD81B60), isDark, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddPhoto()))),
        ],
      ),
    );
  }

  // --- 2. Bookings Tab ---
  Widget _buildAppointmentsTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            labelColor: Color(0xFFD81B60),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFD81B60),
            tabs: [
              Tab(text: "Pending"),
              Tab(text: "Confirmed"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredList('pending'),
                _buildFilteredList('confirmed'),
                _buildFilteredList('completed'),
                _buildFilteredList('cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(String status) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("No $status bookings"));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            Appointment apt = Appointment.fromFirestore(docs[index]);
            Color sColor = _getStatusColor(status);

            String dateOnly = apt.dateTime.toString().split(' ')[0];
            String timeOnly = apt.dateTime.toString().split(' ')[1].substring(0, 5);

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: sColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: sColor.withOpacity(0.2), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: sColor.withOpacity(0.1),
                          child: Icon(_getStatusIcon(status), color: sColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(apt.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(apt.service, style: TextStyle(color: const Color(0xFFD81B60), fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (status != 'completed' && status != 'cancelled') _buildTrailingActions(status, apt.id!),
                      ],
                    ),
                    const Divider(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoChip(Icons.calendar_today, dateOnly, Colors.blue),
                        _infoChip(Icons.access_time, timeOnly, Colors.orange),
                        _infoChip(Icons.person_outline, "Assigned", Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTrailingActions(String status, String id) {
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleBtn(Icons.check, Colors.green, () => _updateStatus(id, 'confirmed')),
          const SizedBox(width: 8),
          _circleBtn(Icons.close, Colors.red, () => _updateStatus(id, 'cancelled')),
        ],
      );
    } else if (status == 'confirmed') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => _updateStatus(id, 'completed'),
        child: const Text("Finish", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox();
  }

  Widget _circleBtn(IconData i, Color c, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(i, color: c, size: 18),
      ),
    );
  }

  void _updateStatus(String id, String status) {
    FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': status});
  }

  // --- 3. Gallery Tab ---
  Widget _buildGalleryManagementTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gallery').orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Stack(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
                Positioned(top: 5, right: 5, child: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('gallery').doc(docs[index].id).delete())),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statBox(String l, String v, IconData i, Color c, bool d) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: d ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: c.withOpacity(0.3))),
        child: Column(children: [Icon(i, color: c), const SizedBox(height: 5), Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)), Text(l, style: const TextStyle(fontSize: 10))]),
      ),
    );
  }

  Widget _buildSectionHeader(String t, IconData i, bool d) {
    return Row(children: [Icon(i, color: const Color(0xFFD81B60)), const SizedBox(width: 10), Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]);
  }

  Widget _buildQuickActionItem(String t, String s, IconData i, Color c, bool d, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ListTile(leading: Icon(i, color: c), title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(s), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: onTap),
    );
  }

  Color _getStatusColor(String s) => s == 'confirmed' ? Colors.green : (s == 'cancelled' ? Colors.red : (s == 'completed' ? Colors.blue : Colors.orange));
  IconData _getStatusIcon(String s) => s == 'confirmed' ? Icons.check_circle : (s == 'cancelled' ? Icons.cancel : (s == 'completed' ? Icons.verified : Icons.history));
}