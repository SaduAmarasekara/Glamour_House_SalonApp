import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'models.dart';
import 'login_page.dart';
import 'booking_page.dart';
import 'gallery_page.dart';
import 'admin_panel.dart';
import 'my_appointments.dart';
import 'firebase_options.dart';

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
  State<SaloonApp> createState() => _SaloonAppState();
}

class _SaloonAppState extends State<SaloonApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode themeMode) {
    setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glamour House Salon',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: _themeMode,
      home: const AuthWrapper(),
    );
  }
}

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
        return const SaloonHomeScreen();
      },
    );
  }
}

class SaloonHomeScreen extends StatefulWidget {
  const SaloonHomeScreen({super.key});
  @override
  State<SaloonHomeScreen> createState() => _SaloonHomeScreenState();
}

class _SaloonHomeScreenState extends State<SaloonHomeScreen> {
  int _currentIndex = 2; // Default to Home
  final _authService = AuthService();

  final List<Map<String, dynamic>> services = const [
    {"name": "Hair Spa", "icon": Icons.water_drop, "color": Color(0xFF9C27B0)},
    {"name": "Hair Styling", "icon": Icons.face_retouching_natural, "color": Color(0xFFFFB300)},
    {"name": "Massage", "icon": Icons.spa, "color": Color(0xFF4CAF50)},
    {"name": "Hair Cut", "icon": Icons.content_cut, "color": Color(0xFFFF5252)},
    {"name": "Skin Care", "icon": Icons.face, "color": Color(0xFFFF9800)},
    {"name": "Manicure", "icon": Icons.pan_tool, "color": Color(0xFFE91E63)},
  ];

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentIndex) {
      case 0: currentBody = _buildFavouritePage(); break;
      case 1: currentBody = const MyAppointmentsPage(); break;
      case 2: currentBody = _buildHomeContent(); break;
      case 3: currentBody = const GalleryPage(); break;
      case 4: currentBody = _buildProfilePage(); break;
      default: currentBody = _buildHomeContent();
    }

    return Scaffold(
      body: SafeArea(child: currentBody),
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
          _buildBannerSlider(),
          _buildSearchBar(),
          _buildSectionTitle("Our Premium Services"),
          _buildServicesGrid(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- HEADER WITH LOGOUT & ADMIN LOGIC ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF8A80)], begin: Alignment.topLeft),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Glamour House ", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Elegance in every touch", style: TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.login, color: Colors.white, size: 28),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                );
              }

              // ඇතුළු වී සිටින පරිශීලකයාගේ දත්ත ලබා ගැනීම
              return FutureBuilder<UserModel?>(
                future: _authService.getCurrentUserData(),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    onSelected: (value) async {
                      if (value == 'admin') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanel()));
                      } else if (value == 'logout') {
                        await _authService.signOut();
                      }
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        user?.name[0].toUpperCase() ?? "U",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text("Hi, ${user?.name ?? 'User'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      const PopupMenuDivider(),
                      if (user?.role == 'admin')
                        const PopupMenuItem(
                          value: 'admin',
                          child: ListTile(
                            leading: Icon(Icons.admin_panel_settings, color: Colors.blue),
                            title: Text('Admin Panel'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
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

  // --- පවතින අනෙක් UI කොටස් ---

  Widget _buildBannerSlider() {
    return Container(
      height: 160, margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=1000&auto=format&fit=crop'), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black.withValues(alpha: 0.3)),
        child: const Center(child: Text("30% OFF ON HAIR SPA", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search services...", prefixIcon: const Icon(Icons.search),
          filled: true, fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(selectedService: s['name']))),
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(s['icon'], color: s['color'], size: 32),
              const SizedBox(height: 8),
              Text(s['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Fav'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Trendy'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildFavouritePage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login to see favourites"));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favourites').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildInspirationCard(data);
          },
        );
      },
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
          _buildMenuTile(Icons.dark_mode, "Dark Mode", trailing: Switch(value: Theme.of(context).brightness == Brightness.dark, onChanged: (val) => SaloonApp.of(context).changeTheme(val ? ThemeMode.dark : ThemeMode.light))),
          _buildMenuTile(Icons.calendar_month, "My Appointments", onTap: () => setState(() => _currentIndex = 1)),
          _buildMenuTile(Icons.logout, "Logout", color: Colors.red, onTap: () async => await _authService.signOut()),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildHeaderTitle(String title) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFFE91E63)), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)));

  Widget _buildProfileCard(User? user) => Container(
    margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      const CircleAvatar(radius: 30, backgroundColor: Color(0xFFE91E63), child: Icon(Icons.person, color: Colors.white)),
      const SizedBox(width: 15),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user?.email?.split('@')[0].toUpperCase() ?? "Guest", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(user?.email ?? "Sign in to book", style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ])
    ]),
  );

  Widget _buildMenuTile(IconData icon, String title, {VoidCallback? onTap, Widget? trailing, Color? color}) => ListTile(leading: Icon(icon, color: color ?? const Color(0xFFE91E63)), title: Text(title, style: TextStyle(color: color)), trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14), onTap: onTap);

  Widget _buildInspirationCard(Map<String, dynamic> data) => Container(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover)),
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Colors.transparent, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      padding: const EdgeInsets.all(8),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
    ),
  );

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
}