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
import 'firebase_options.dart';
import 'started_page.dart'; // Startup Page එක Import කළා

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SaloonApp());
}

class SaloonApp extends StatefulWidget {
  const SaloonApp({super.key});

  static _SaloonAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_SaloonAppState>()!;

  @override
  State createState() => _SaloonAppState();
}

class _SaloonAppState extends State {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beautix Salon',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD81B60),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF5F7),
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD81B60),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'Poppins',
      ),
      themeMode: _themeMode,
      home: const StartedPage(), // මුලින්ම පෙන්වන පිටුව
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return const SaloonHomeScreen();
      },
    );
  }
}

class SaloonHomeScreen extends StatefulWidget {
  const SaloonHomeScreen({super.key});

  @override
  State createState() => _SaloonHomeScreenState();
}

class _SaloonHomeScreenState extends State {
  int _currentIndex = 0;
  final _authService = AuthService();

  final List<Map<String, dynamic>> services = const [
    {
      "name": "Skin Care",
      "icon": Icons.face_rounded,
      "color": Color(0xFFFF6B9D),
      "bgColor": Color(0xFFFFE5EF)
    },
    {
      "name": "Facial",
      "icon": Icons.self_improvement_rounded,
      "color": Color(0xFFB388FF),
      "bgColor": Color(0xFFF3E5F5)
    },
    {
      "name": "Coloring",
      "icon": Icons.palette_rounded,
      "color": Color(0xFF4FC3F7),
      "bgColor": Color(0xFFE1F5FE)
    },
    {
      "name": "Make-up",
      "icon": Icons.brush_rounded,
      "color": Color(0xFFFF8A80),
      "bgColor": Color(0xFFFFEBEE)
    },
    {
      "name": "Waxing",
      "icon": Icons.whatshot_rounded,
      "color": Color(0xFFFFB74D),
      "bgColor": Color(0xFFFFF3E0)
    },
    {
      "name": "Manicure",
      "icon": Icons.back_hand_rounded,
      "color": Color(0xFFE91E63),
      "bgColor": Color(0xFFFCE4EC)
    },
    {
      "name": "Hair Spa",
      "icon": Icons.water_drop_rounded,
      "color": Color(0xFF4DB6AC),
      "bgColor": Color(0xFFE0F2F1)
    },
    {
      "name": "View More",
      "icon": Icons.apps_rounded,
      "color": Color(0xFF9E9E9E),
      "bgColor": Color(0xFFF5F5F5)
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const MyAppointmentsPage(),
      const GalleryPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: _buildBottomNav(),
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
          _buildServicesGrid(),
          const SizedBox(height: 20),
          _buildSectionTitle("Hair Specialist", showViewAll: true),
          const SizedBox(height: 12),
          _buildSpecialistsList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, Guest",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Welcome to Beautix Salon",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              }

              return FutureBuilder(
                future: _authService.getCurrentUserData(),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, ${user?.name ?? 'User'}",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Welcome to Beautix Salon",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white60
                              : const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.login, color: Color(0xFFD81B60)),
                  ),
                );
              }

              return FutureBuilder(
                future: _authService.getCurrentUserData(),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return PopupMenuButton<String>(
                    offset: const Offset(0, 55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) async {
                      if (value == 'admin') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminPanel()),
                        );
                      } else if (value == 'logout') {
                        await _authService.signOut();
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD81B60), Color(0xFFFF6090)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD81B60).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user?.name[0].toUpperCase() ?? "U",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          "Hi, ${user?.name ?? 'User'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      if (user?.role == 'admin')
                        const PopupMenuItem<String>(
                          value: 'admin',
                          child: ListTile(
                            leading: Icon(Icons.admin_panel_settings,
                                color: Color(0xFF2196F3)),
                            title: Text('Admin Panel'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout, color: Color(0xFFD81B60)),
                          title: Text('Logout'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFD81B60), Color(0xFFB91650)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD81B60).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Look Awesome &",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  "Save Some",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Best Upto 50% Off",
                    style: TextStyle(
                      color: Color(0xFFD81B60),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 20,
          mainAxisSpacing: 24,
          childAspectRatio: 0.72, // Overflow දෝෂය විසඳීමට අනුපාතය වැඩි කළා
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index];
          return GestureDetector(
            onTap: () {
              if (s['name'] != "View More") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingPage(selectedService: s['name'] as String),
                  ),
                );
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: s['bgColor'],
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: (s['color'] as Color).withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      s['icon'],
                      color: s['color'],
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible( // අකුරු වැඩි නම් පහළට යාම වැළැක්වීමට
                  child: Text(
                    s['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF2D2D2D),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showViewAll = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2D2D2D),
            ),
          ),
          if (showViewAll)
            TextButton(
              onPressed: () {},
              child: const Text(
                "View More",
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialistsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('specialists')
          .orderBy('rating', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          final defaultSpecialists = [
            {
              "name": "Briey Alian",
              "phone": "880 552 098",
              "rating": 4.8,
              "image": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400"
            },
            {
              "name": "Axi Beton",
              "phone": "880 938 5630",
              "rating": 4.9,
              "image": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400"
            },
            {
              "name": "Lamina Mini",
              "phone": "880 568 4188",
              "rating": 5.0,
              "image": "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400"
            },
          ];

          return SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: defaultSpecialists.length,
              itemBuilder: (context, index) {
                final specialist = defaultSpecialists[index];
                return _buildSpecialistCard(
                  name: specialist['name'] as String,
                  phone: specialist['phone'] as String,
                  rating: specialist['rating'] as double,
                  imageUrl: specialist['image'] as String,
                  isLast: index == defaultSpecialists.length - 1,
                );
              },
            ),
          );
        }

        final specialists = snapshot.data!.docs;
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: specialists.length,
            itemBuilder: (context, index) {
              final data = specialists[index].data() as Map<String, dynamic>;
              return _buildSpecialistCard(
                name: data['name'] ?? 'Specialist',
                phone: data['phone'] ?? 'N/A',
                rating: (data['rating'] ?? 5.0).toDouble(),
                imageUrl: data['imageUrl'] ?? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
                isLast: index == specialists.length - 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSpecialistCard({
    required String name,
    required String phone,
    required double rating,
    required String imageUrl,
    required bool isLast,
  }) {
    return Container(
      width: 165,
      margin: EdgeInsets.only(right: isLast ? 0 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2D2D2D)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Image.network(
              imageUrl,
              height: 140,
              width: 165,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 140,
                  width: 165,
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2D2D2D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFC107),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.phone,
                      size: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : const Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8E8E93),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2D2D2D)
              : Colors.white,
          selectedItemColor: const Color(0xFFD81B60),
          unselectedItemColor: const Color(0xFF8E8E93),
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home_rounded, size: 26),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined, size: 24),
              activeIcon: Icon(Icons.calendar_today_rounded, size: 24),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined, size: 26),
              activeIcon: Icon(Icons.auto_awesome_rounded, size: 26),
              label: 'Trendy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 26),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderTitle("My Profile"),
          const SizedBox(height: 20),
          _buildProfileCard(user),
          _buildMenuTile(
            Icons.dark_mode_outlined,
            "Dark Mode",
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (val) => SaloonApp.of(context)
                  .changeTheme(val ? ThemeMode.dark : ThemeMode.light),
              activeColor: const Color(0xFFD81B60),
            ),
          ),
          _buildMenuTile(
            Icons.calendar_month_outlined,
            "My Appointments",
            onTap: () => setState(() => _currentIndex = 1),
          ),
          _buildMenuTile(
            Icons.logout_rounded,
            "Logout",
            color: const Color(0xFFD81B60),
            onTap: () async => await _authService.signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitle(String title) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFD81B60), Color(0xFFFF6090)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _buildProfileCard(User? user) => Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2D2D2D)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFD81B60), Color(0xFFFF6090)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD81B60).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.email?.split('@')[0].toUpperCase() ?? "Guest",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? "Sign in to book",
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildMenuTile(IconData icon, String title,
      {VoidCallback? onTap, Widget? trailing, Color? color}) =>
      ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFFD81B60)),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      );
}

