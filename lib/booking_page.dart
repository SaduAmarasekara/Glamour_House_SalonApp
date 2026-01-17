import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'models.dart';
import 'login_page.dart'; // Login page එක import කළ යුතුය

class BookingPage extends StatefulWidget {
  final String? selectedService;
  const BookingPage({super.key, this.selectedService});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  String? _selectedService;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  bool _isLoading = false;
  List<String> _bookedSlots = [];

  final List<String> services = [
    'Skin Care', 'Facial', 'Coloring', 'Make-up',
    'Waxing', 'Manicure', 'Hair Spa', 'Hair Cut',
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.selectedService;
    _fetchBookedSlots(_selectedDate);
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    setState(() => _isLoading = true);
    try {
      var snapshot = await _firestore.collection('appointments')
          .where('status', isNotEqualTo: 'cancelled')
          .get();
      setState(() {
        _bookedSlots = snapshot.docs
            .where((doc) {
          DateTime dt = (doc['dateTime'] as Timestamp).toDate();
          return DateFormat('yyyy-MM-dd').format(dt) == formattedDate;
        })
            .map((doc) => DateFormat('hh:mm a').format((doc['dateTime'] as Timestamp).toDate()))
            .toList();
        _selectedTimeSlot = null;
      });
    } catch (e) {
      debugPrint("Error fetching slots: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _generateTimeSlots() {
    List<String> slots = [];
    DateTime start = DateTime(2024, 1, 1, 9, 0);
    DateTime end = DateTime(2024, 1, 1, 18, 0);
    while (start.isBefore(end)) {
      slots.add(DateFormat('hh:mm a').format(start));
      start = start.add(const Duration(minutes: 30));
    }
    return slots;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD81B60),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2D2D2D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchBookedSlots(picked);
    }
  }

  // --- මෙතැනදී Login Logic එක ක්‍රියාත්මක වේ ---
  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select service and time slot'), backgroundColor: Color(0xFFD81B60)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. දැනට සිටින පරිශීලකයා බලන්න
      User? currentUser = FirebaseAuth.instance.currentUser;

      // 2. ලොග් වී නැති නම් Login Page එකට යවන්න
      if (currentUser == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to confirm booking'), backgroundColor: Color(0xFFD81B60)),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        return;
      }

      // 3. ලොග් වී ඇත්නම් පමණක් Firestore එකට දත්ත යවන්න
      UserModel? user = await _authService.getCurrentUserData();
      DateTime slotTime = DateFormat('hh:mm a').parse(_selectedTimeSlot!);
      DateTime appointmentDT = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, slotTime.hour, slotTime.minute);

      await _firestore.collection('appointments').add({
        'customerId': user!.uid,
        'customerName': user.name,
        'service': _selectedService,
        'dateTime': Timestamp.fromDate(appointmentDT),
        'status': 'pending',
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking Confirmed!'), backgroundColor: Color(0xFF4CAF50)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        elevation: 0, backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D2D2D), size: 18), onPressed: () => Navigator.pop(context)),
        ),
        title: const Text("Book Appointment", style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Select Service", Icons.spa_rounded),
              const SizedBox(height: 12),
              _buildDropdown(),
              const SizedBox(height: 24),
              _buildSectionTitle("Choose Date", Icons.calendar_today_rounded),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildSectionTitle("Available Time Slots", Icons.access_time_rounded),
              const SizedBox(height: 12),
              _buildTimeSlotsGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle("Additional Notes", Icons.edit_note_rounded),
              const SizedBox(height: 12),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // සෙසු UI Widgets එලෙසම පවතී (SectionTitle, Dropdown, Grid ආදිය)
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFD81B60).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFFD81B60), size: 20)),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2D2D2D))),
    ]);
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: DropdownButtonFormField<String>(
        value: _selectedService,
        decoration: InputDecoration(
          labelText: "Choose a service", labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
          prefixIcon: const Icon(Icons.design_services_rounded, color: Color(0xFFD81B60)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: services.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
        onChanged: (v) => setState(() => _selectedService = v),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFD81B60).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFD81B60), size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Selected Date", style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2D2D2D))),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Color(0xFFD81B60), size: 16),
        ]),
      ),
    );
  }

  Widget _buildTimeSlotsGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD81B60)));
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: _generateTimeSlots().map((slot) {
        bool isBooked = _bookedSlots.contains(slot);
        bool isSelected = _selectedTimeSlot == slot;
        return GestureDetector(
          onTap: isBooked ? null : () => setState(() => _selectedTimeSlot = slot),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected ? const LinearGradient(colors: [Color(0xFFD81B60), Color(0xFFFF6090)]) : null,
              color: isSelected ? null : (isBooked ? Colors.grey[200] : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.transparent : (isBooked ? Colors.grey[300]! : const Color(0xFFE0E0E0)), width: 1.5),
            ),
            child: Text(slot, style: TextStyle(color: isSelected ? Colors.white : (isBooked ? Colors.grey[400] : const Color(0xFF2D2D2D)), fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: TextField(controller: _notesController, maxLines: 4, decoration: InputDecoration(hintText: "Any special requests?", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: Colors.white)),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFD81B60), Color(0xFFFF6090)]), borderRadius: BorderRadius.circular(16)),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}