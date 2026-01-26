import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Appointments')),
        body: const Center(child: Text('Please login to view appointments')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFD81B60),
        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildAppointmentsList(user.uid)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', 'all'),
          _buildFilterChip('Pending', 'pending'),
          _buildFilterChip('Confirmed', 'confirmed'),
          _buildFilterChip('Completed', 'completed'),
          _buildFilterChip('Cancelled', 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD81B60) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(String userId) {
    // Real-time updates ලබා ගැනීමට StreamBuilder භාවිතා කරයි
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('customerId', isEqualTo: userId)
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No appointments found'));
        }

        // Filter එක අනුව දත්ත පෙරා ගැනීම
        List<Appointment> appointments = snapshot.data!.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .where((apt) => _filterStatus == 'all' || apt.status == _filterStatus)
            .toList();

        if (appointments.isEmpty) {
          return const Center(child: Text('No appointments in this category'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) => _buildAppointmentCard(appointments[index]),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    IconData statusIcon;

    switch (appointment.status) {
      case 'confirmed': statusColor = Colors.green; statusIcon = Icons.check_circle; break;
      case 'completed': statusColor = Colors.blue; statusIcon = Icons.done_all; break;
      case 'cancelled': statusColor = Colors.red; statusIcon = Icons.cancel; break;
      default: statusColor = Colors.orange; statusIcon = Icons.pending_actions;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFD81B60).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.spa, color: Color(0xFFD81B60), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.service, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(appointment.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('EEEE, MMM d, yyyy').format(appointment.dateTime), style: const TextStyle(color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('hh:mm a').format(appointment.dateTime), style: const TextStyle(color: Colors.black87)),
              ],
            ),

            // --- 1. සේවාව අවසන් නම් (Completed) රිවීව් එකක් දැමීමට ---
            if (appointment.status == 'completed') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReviewModal(context, appointment),
                  icon: const Icon(Icons.star_rate, color: Colors.white),
                  label: const Text('Add Review & Rate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // --- 2. තවමත් Pending නම් පමණක් Cancel කිරීමට ---
            if (appointment.status == 'pending') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancel(appointment.id!),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Cancel Appointment', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Cancel කිරීමට පෙර තහවුරු කරගැනීම ---
  void _confirmCancel(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("Do you really want to cancel this appointment?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              _cancelAppointment(id);
              Navigator.pop(context);
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Firestore හි තත්ත්වය වෙනස් කිරීම
  Future<void> _cancelAppointment(String id) async {
    try {
      await _firestore.collection('appointments').doc(id).update({'status': 'cancelled'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment cancelled successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- REVIEW MODAL Logic ---
  void _showReviewModal(BuildContext context, Appointment appointment) {
    final TextEditingController commentController = TextEditingController();
    double currentRating = 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Review your ${appointment.service}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "How was the service?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (commentController.text.isEmpty) return;
                  await _firestore.collection('reviews').add({
                    'serviceName': appointment.service,
                    'customerName': appointment.customerName,
                    'comment': commentController.text,
                    'rating': currentRating,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your review!")));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Submit Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}