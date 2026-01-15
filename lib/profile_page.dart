import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'models.dart';
import 'main.dart';
import 'my_appointments.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(authService),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileTile(Icons.calendar_month, "My Appointments", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyAppointmentsPage()))),
                  _buildProfileTile(Icons.dark_mode, "Dark Mode", null, trailing: Switch(
                    value: isDark,
                    activeColor: const Color(0xFFD81B60),
                    onChanged: (v) => SaloonApp.of(context).changeTheme(v ? ThemeMode.dark : ThemeMode.light),
                  )),
                  _buildProfileTile(Icons.logout, "Logout", () => authService.signOut(), color: Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(AuthService authService) {
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        String name = snapshot.data?.name ?? "Guest User";
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFD81B60), Color(0xFFFF6090)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
          child: Column(
            children: [
              CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
              const SizedBox(height: 15),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback? onTap, {Widget? trailing, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFFD81B60)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}