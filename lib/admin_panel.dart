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
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFFFFAFA)],
          ).createShader(bounds),
          child: const Text(
            "Welcome  Admin",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
              fontSize: 22,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
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
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Stats", icon: Icon(Icons.analytics_rounded, size: 22)),
            Tab(text: "Bookings", icon: Icon(Icons.book_online_rounded, size: 22)),
            Tab(text: "Gallery", icon: Icon(Icons.photo_library_rounded, size: 22)),
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

  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Business Performance", Icons.trending_up_rounded, isDark),
            const SizedBox(height: 18),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoDataCard("No appointment data available.", isDark);
                }

                // Stats ගණනය කිරීම - Total වෙනුවට Completed එක් කළා
                int completed = snapshot.data!.docs.where((d) => d['status'] == 'completed').length;
                int active = snapshot.data!.docs.where((d) => d['status'] == 'pending').length;
                int confirmed = snapshot.data!.docs.where((d) => d['status'] == 'confirmed').length;

                return Row(
                  children: [
                    _statBox("Active", active.toString(), Icons.timer_rounded, Colors.orange, isDark),
                    const SizedBox(width: 12),
                    _statBox("Confirmed", confirmed.toString(), Icons.check_circle_rounded, Colors.green, isDark),
                    const SizedBox(width: 12),
                    _statBox("Completed", completed.toString(), Icons.done_all_rounded, const Color(0xFFD81B60), isDark),
                  ],
                );
              },
            ),

            const SizedBox(height: 35),
            _buildSectionHeader("Quick Management", Icons.settings_suggest_rounded, isDark),
            const SizedBox(height: 18),
            _buildQuickActionItem(
                "Manage Specialists",
                "Edit salon team profiles",
                Icons.people_rounded,
                Colors.blue,
                isDark,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSpecialists()))
            ),
            _buildQuickActionItem(
                "Price List",
                "Update service pricing",
                Icons.monetization_on_rounded,
                Colors.green,
                isDark,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePrices()))
            ),
            _buildQuickActionItem(
                "Add New Style",
                "Upload style link to gallery",
                Icons.add_a_photo_rounded,
                const Color(0xFFD81B60),
                isDark,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddPhoto()))
            ),
          ],
        ),
      ),
    );
  }

  // --- Appointments Tab with Completed logic ---
  Widget _buildAppointmentsTab() {
    return DefaultTabController(
      length: 4, // Completed සඳහා අලුත් එකක් එක් කළා
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: const TabBar(
              isScrollable: true, // ටැබ් 4ක් ඇති බැවින් scrollable කළා
              labelColor: Color(0xFFD81B60),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFD81B60),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: "Pending"),
                Tab(text: "Confirmed"),
                Tab(text: "Completed"), // අලුත් ටැබ් එක
                Tab(text: "Cancelled"),
              ],
            ),
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
        if (docs.isEmpty) return Center(child: Text("No $status appointments"));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            Appointment apt = Appointment.fromFirestore(docs[index]);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A1A2E), const Color(0xFF1F1620)]
                      : [Colors.white, const Color(0xFFFFFAFD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(status).withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: _getStatusColor(status).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 4))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_getStatusColor(status).withOpacity(0.2), _getStatusColor(status).withOpacity(0.1)]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                ),
                title: Text(apt.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(apt.service),
                trailing: _buildTrailingActions(status, apt.id!),
              ),
            );
          },
        );
      },
    );
  }

  // බට්න් ක්‍රියාකාරිත්වය කළමනාකරණය - Confirmed ටැබ් එකේදී Complete බට්න් එක පෙන්වයි
  Widget? _buildTrailingActions(String status, String id) {
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(Icons.check_circle_rounded, Colors.green, () => _updateStatus(id, 'confirmed')),
          const SizedBox(width: 8),
          _actionButton(Icons.cancel_rounded, Colors.red, () => _updateStatus(id, 'cancelled')),
        ],
      );
    } else if (status == 'confirmed') {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFD81B60), Color(
              0xFFD81B60)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton.icon(
          onPressed: () => _updateStatus(id, 'completed'),
          icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
          label: const Text("Complete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      );
    }
    return null;
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
        shape: BoxShape.circle,
      ),
      child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
    );
  }

  // Firestore update logic
  void _updateStatus(String id, String status) {
    FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': status});

    String message = status == 'completed' ? "Appointment marked as Completed!" : "Status updated to $status";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _getStatusColor(status)),
    );
  }

  // --- පවතින අනෙකුත් UI Helpers (StatBox, Header, etc.) එලෙසම පවතී ---

  Widget _statBox(String label, String val, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2A1A2E), const Color(0xFF1F1620)]
                : [Colors.white, const Color(0xFFFFFAFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- Gallery, Header, QuickActionItem ආදිය ඔබගේ පැරණි කේතයේ CSS එලෙසම භාවිතා කර ඇත ---
  // (කේතය කෙටි කිරීම සඳහා ඒවා මෙහි නැවත සඳහන් නොකළද ඔබගේ ගොනුවේ ඒවා එලෙසම තබා ගන්න)

  Widget _buildGalleryManagementTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gallery').orderBy('uploadedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildNoDataCard("Gallery is empty.", isDark);

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.85,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A1A2E), const Color(0xFF1F1620)]
                      : [Colors.white, const Color(0xFFFFFAFD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFD81B60).withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFFD81B60).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                          child: Image.network(data['imageUrl'], fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image))),
                        ),
                        Positioned(
                          top: 10, right: 10,
                          child: GestureDetector(
                            onTap: () => _confirmDelete(docs[index].id, 'gallery'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF1744), Color(0xFFD32F2F)]), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(data['title'] ?? 'Style', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFD81B60).withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: const Color(0xFFD81B60))),
      const SizedBox(width: 12),
      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
    ]);
  }

  Widget _buildQuickActionItem(String t, String s, IconData i, Color c, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: c.withOpacity(0.1), blurRadius: 10)],
      ),
      child: ListTile(
        leading: Icon(i, color: c),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(s),
        trailing: Icon(Icons.chevron_right, color: c),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNoDataCard(String message, bool isDark) {
    return Center(child: Text(message));
  }

  void _confirmDelete(String id, String collection) {
    FirebaseFirestore.instance.collection(collection).doc(id).delete();
  }

  Color _getStatusColor(String s) => s == 'confirmed' ? Colors.green : (s == 'cancelled' ? Colors.red : (s == 'completed' ? Colors.blue : Colors.orange));
  IconData _getStatusIcon(String s) => s == 'confirmed' ? Icons.done_all : (s == 'cancelled' ? Icons.close : (s == 'completed' ? Icons.verified : Icons.timer));
}