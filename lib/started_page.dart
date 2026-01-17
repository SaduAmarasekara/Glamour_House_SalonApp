import 'package:flutter/material.dart';
import 'main.dart';

class StartedPage extends StatelessWidget {
  const StartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFFFE5196),
              Color(0xFFE91E63),
              Color(0xFFD81B60),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background circles
              _buildBackgroundCircles(size),

              // Scrollable content to prevent overflow
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: size.height * 0.04),
                          _buildBrandHeader(),
                          SizedBox(height: size.height * 0.04),
                          _buildHeroTitle(),
                        ],
                      ),

                      // Central Image with dynamic sizing
                      _buildCentralIllustration(size),

                      Column(
                        children: [
                          _buildFeaturesRow(),
                          SizedBox(height: size.height * 0.03),
                          _buildStartButton(context),
                          SizedBox(height: size.height * 0.05),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCircles(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -50, right: -50,
          child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.08)),
        ),
        Positioned(
          bottom: 100, left: -80,
          child: CircleAvatar(radius: 125, backgroundColor: Colors.white.withOpacity(0.06)),
        ),
        Positioned(
          top: size.height * 0.3, right: -40,
          child: CircleAvatar(radius: 75, backgroundColor: Colors.white.withOpacity(0.05)),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)]),
            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20)],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 35),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: const Text(
            "The Glamour House",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 3),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroTitle() {
    return const Column(
      children: [
        Text(
          "Discover Your",
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: 1),
        ),
        Text(
          "True Beauty",
          style: TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900, height: 1),
        ),
        SizedBox(height: 8),
        Text(
          "Experience luxury and elegance",
          style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildCentralIllustration(Size size) {
    double imageSize = size.width * 0.6;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: imageSize * 1.2, height: imageSize * 1.2,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withOpacity(0.15), Colors.transparent])),
          ),
          Container(
            width: imageSize, height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFC1CC), Color(0xFFFFA6B8)]),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa, size: imageSize * 0.3, color: Colors.white),
                const SizedBox(height: 10),
                const Text("Premium Beauty", style: TextStyle(color: Color(0xFF8B4A5E), fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFeatureItem(Icons.diamond, "Premium"),
          _buildDivider(),
          _buildFeatureItem(Icons.timer, "Quick"),
          _buildDivider(),
          _buildFeatureItem(Icons.star_rounded, "Expert"),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3));

  Widget _buildStartButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: InkWell(
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthWrapper())),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4A1F2C), Color(0xFF2D1410)]),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Begin Your Journey", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}