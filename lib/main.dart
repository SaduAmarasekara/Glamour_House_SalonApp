import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'booking_page.dart';
import 'gallery_page.dart';
import 'admin_panel.dart';
import 'my_appointments.dart';
import 'servicespage.dart';
import 'profile_page.dart';
import 'firebase_options.dart';
import 'started_page.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SaloonApp());
}

class SaloonApp extends StatefulWidget {
  const SaloonApp({super.key});
  static _SaloonAppState of(BuildContext context) => context.findAncestorStateOfType<_SaloonAppState>()!;
  @override
  State<SaloonApp> createState() => _SaloonAppState();
}

class _SaloonAppState extends State<SaloonApp> {
  ThemeMode _themeMode = ThemeMode.system;
  void changeTheme(ThemeMode themeMode) => setState(() => _themeMode = themeMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beautix Salon',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD81B60), brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFFFF5F7),
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD81B60), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Poppins',
      ),
      themeMode: _themeMode,
      home: const StartedPage(),
    );
  }
}

// --- AUTH WRAPPER ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const SaloonHomeScreen();
        return const LoginPage();
      },
    );
  }
}

// --- MAIN HOME SCREEN ---
class SaloonHomeScreen extends StatefulWidget {
  const SaloonHomeScreen({super.key});
  @override
  State<SaloonHomeScreen> createState() => _SaloonHomeScreenState();
}

class _SaloonHomeScreenState extends State<SaloonHomeScreen> {
  int _currentIndex = 2; // Home Button in Middle (Index 2)
  final _authService = AuthService();

  // Booking Page එකේ සේවාවන්ට අනුකූල සම්පූර්ණ ලැයිස්තුව
  final List<Map<String, dynamic>> allServices = [
    {"n": "Skin Care", "i": Icons.face_rounded, "c": Color(0xFFFFE5EF)},
    {"n": "Facial", "i": Icons.self_improvement, "c": Color(0xFFF3E5F5)},
    {"n": "Coloring", "i": Icons.palette_rounded, "c": Color(0xFFE1F5FE)},
    {"n": "Make-up", "i": Icons.brush_rounded, "c": Color(0xFFFFEBEE)},
    {"n": "Waxing", "i": Icons.whatshot_rounded, "c": Color(0xFFFFF3E0)},
    {"n": "Manicure", "i": Icons.back_hand, "c": Color(0xFFFCE4EC)},
    {"n": "Hair Spa", "i": Icons.water_drop, "c": Color(0xFFE0F2F1)},
    {"n": "Hair Cut", "i": Icons.content_cut, "c": Color(0xFFE8F5E9)},
    {"n": "Blade & Trim", "i": Icons.content_cut_outlined, "c": Color(0xFFF5F5F5)},
    {"n": "Beard Styling", "i": Icons.face_retouching_natural, "c": Color(0xFFEFEBE9)},
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const MyAppointmentsPage(),
      const ServicesPage(),
      _buildHomeContent(),
      const GalleryPage(),
      const ProfilePage(),
    ];

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPromoBanner(),
          const SizedBox(height: 24),
          _buildSectionTitle("Our Services"),
          const SizedBox(height: 12),
          _buildFullServicesGrid(), // සියලුම සේවාවන් පෙන්වන Grid එක
          const SizedBox(height: 30),
          _buildSectionTitle("Trendy Styles", showViewAll: true, onTap: () => setState(() => _currentIndex = 3)),
          const SizedBox(height: 15),
          _buildTrendyStylesPreview(), // Trendy Styles Preview එක
          const SizedBox(height: 30),
          _buildSectionTitle("Hair Specialists"),
          const SizedBox(height: 15),
          _buildSpecialistsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello, Beautiful!", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const Text("Beautix Salon ✨", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFD81B60))),
            ],
          ),
          _buildProfileCircle(),
        ],
      ),
    );
  }

  Widget _buildProfileCircle() {
    return FutureBuilder<UserModel?>(
      future: _authService.getCurrentUserData(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          onSelected: (val) {
            if (val == 'admin') Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanel()));
            if (val == 'logout') _authService.signOut();
          },
          child: Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFD81B60), Color(0xFFFF6090)])),
            child: Center(child: Text(user?.name[0].toUpperCase() ?? "U", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          itemBuilder: (context) => [
            if (user?.role == 'admin') const PopupMenuItem(value: 'admin', child: Text("Admin Dashboard")),
            const PopupMenuItem(value: 'logout', child: Text("Logout")),
          ],
        );
      },
    );
  }

  // --- සියලුම සේවාවන් පෙන්වන Grid එක ---
  Widget _buildFullServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 0.8,
        ),
        itemCount: allServices.length,
        itemBuilder: (context, index) {
          final s = allServices[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(selectedService: s['n']))); //
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: s['c'] as Color, borderRadius: BorderRadius.circular(18)),
                  child: Icon(s['i'] as IconData, color: const Color(0xFFD81B60), size: 28),
                ),
                const SizedBox(height: 5),
                Text(s['n'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Trendy Styles Preview (Images from Gallery) ---
  Widget _buildTrendyStylesPreview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('gallery').limit(4).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final photo = docs[index]['imageUrl'];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSpecialistsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('specialists').orderBy('rating', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final sp = SpecialistModel.fromFirestore(docs[index]);
              return _buildSpecialistCard(sp);
            },
          ),
        );
      },
    );
  }

  Widget _buildSpecialistCard(SpecialistModel sp) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(sp.imageUrl, height: 130, width: 160, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 50)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                Text(sp.specialization, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    Text(" ${sp.rating}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFFD81B60),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.sell_outlined), label: 'Pricing'),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 32), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: 'Trendy'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [Color(0xFFD81B60), Color(0xFF880E4F)]),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Summer Glow Up!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Get 20% off on your first service.", style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.spa, size: 70, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showViewAll = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          if (showViewAll) TextButton(onPressed: onTap, child: const Text("View All")),
        ],
      ),
    );
  }
}