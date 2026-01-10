import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';
import 'models.dart';

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
    'Hair Spa', 'Hair Styling', 'Hair Treatment', 'Massage',
    'Hair Cut', 'Blade & Trim', 'Skin Care', 'Beard Styling', 'Manicure'
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.selectedService;
    _fetchBookedSlots(_selectedDate); // පටන් ගන්නා විටම දත්ත ලබා ගැනීම
  }

  // එම දවසේ දැනටමත් වෙන්කර ඇති වේලාවන් පරීක්ෂා කිරීම
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
        _selectedTimeSlot = null; // දවස වෙනස් කළ විට තේරූ වේලාව ඉවත් කිරීම
      });
    } catch (e) {
      debugPrint("Error fetching slots: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // සැලූන් එකේ වැඩ කරන වේලාවන් අනුව Slots ජනනය කිරීම
  List<String> _generateTimeSlots() {
    List<String> slots = [];
    DateTime start = DateTime(2024, 1, 1, 9, 0); // පෙ.ව. 9:00
    DateTime end = DateTime(2024, 1, 1, 18, 0);  // ප.ව. 6:00

    while (start.isBefore(end)) {
      slots.add(DateFormat('hh:mm a').format(start));
      start = start.add(const Duration(minutes: 30)); // විනාඩි 30 ක පරතරය
    }
    return slots;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchBookedSlots(picked);
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select service and time slot')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserModel? user = await _authService.getCurrentUserData();
      if (user == null) throw Exception('User login required');

      // String කාලය DateTime බවට පත් කිරීම
      DateTime slotTime = DateFormat('hh:mm a').parse(_selectedTimeSlot!);
      DateTime appointmentDT = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, slotTime.hour, slotTime.minute);

      await _firestore.collection('appointments').add({
        'customerId': user.uid,
        'customerName': user.name,
        'service': _selectedService,
        'dateTime': Timestamp.fromDate(appointmentDT), // Firestore Timestamp
        'status': 'pending',
        'notes': _notesController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Confirmed!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Now"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildDatePicker(),
              const SizedBox(height: 25),
              const Text("Select a Time Slot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              _buildTimeSlotsGrid(),
              const SizedBox(height: 25),
              _buildNotesField(),
              const SizedBox(height: 35),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedService,
      decoration: InputDecoration(labelText: "Service", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => setState(() => _selectedService = v),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      tileColor: Colors.pink.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.calendar_month, color: Colors.pink),
      title: Text(DateFormat('EEEE, MMM dd').format(_selectedDate)),
      trailing: const Text("Change", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
      onTap: _selectDate,
    );
  }

  Widget _buildTimeSlotsGrid() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _generateTimeSlots().map((slot) {
        bool isBooked = _bookedSlots.contains(slot);
        bool isSelected = _selectedTimeSlot == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: isBooked ? null : (selected) => setState(() => _selectedTimeSlot = slot),
          selectedColor: Colors.pink,
          labelStyle: TextStyle(color: isSelected ? Colors.white : (isBooked ? Colors.grey : Colors.black)),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return TextField(controller: _notesController, decoration: const InputDecoration(hintText: "Any special notes? (Optional)", border: OutlineInputBorder()));
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirm Booking"),
      ),
    );
  }
}