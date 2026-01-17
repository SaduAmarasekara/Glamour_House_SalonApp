import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'models.dart';
import 'main.dart';
import 'my_appointments.dart';
import 'favourite_page.dart'; // FavouritePage එක සාදා ඇති බවට සහතික වන්න

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryPink = Color(0xFFD81B60);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(authService),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "General Settings",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileCard([
                    _buildProfileTile(
                        Icons.calendar_month_rounded,
                        "My Appointments",
                            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAppointmentsPage()))
                    ),
                    _buildDivider(),
                    _buildProfileTile(
                      Icons.favorite_rounded,
                      "My Favourites",
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavouritePage())),
                      iconColor: Colors.redAccent,
                    ),
                  ]),
                  const SizedBox(height: 25),
                  const Text(
                    "Preferences",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileCard([
                    _buildProfileTile(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        "Appearance",
                        null,
                        trailing: Switch(
                          value: isDark,
                          activeColor: primaryPink,
                          onChanged: (v) => SaloonApp.of(context).changeTheme(v ? ThemeMode.dark : ThemeMode.light),
                        )
                    ),
                    _buildDivider(),
                    _buildProfileTile(
                        Icons.logout_rounded,
                        "Logout",
                            () => _showLogoutDialog(context, authService),
                        color: Colors.redAccent
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("v 1.0.2", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Header එක වඩාත් ලස්සනට (Premium Look)
  Widget _buildPremiumHeader(AuthService authService) {
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        String name = snapshot.data?.name ?? "Guest User";
        String email = snapshot.data?.email ?? "Welcome to Saloon Pro";

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD81B60), Color(0xFFFF6090)]
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8))
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)
                      )
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 18, color: Color(0xFFD81B60)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),
              Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
              ),
              Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)
              ),
            ],
          ),
        );
      },
    );
  }

  // Tiles ටික එකට ගොනු කර පෙන්වන Card එකක්
  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback? onTap, {Widget? trailing, Color? color, Color? iconColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFFD81B60)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? color ?? const Color(0xFFD81B60), size: 22),
      ),
      title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color ?? Colors.black87)
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60, endIndent: 20, color: Color(0xFFEEEEEE));
  }

  // Logout එකට Confirm Dialog එකක්
  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => authService.signOut(),
              child: const Text("Logout", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }
}