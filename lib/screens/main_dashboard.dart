import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'mail_screen.dart';
import 'map_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();
    
    return Scaffold(
      backgroundColor: themeService.isDarkMode
          ? const Color(0xFF191919) // Gris très foncé
          : const Color(0xFFFAF7F0), // Crème
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo centré qui change selon le thème
            Center(
              child: Image.asset(
                themeService.isDarkMode
                    ? 'assets/logo_app_blanc.png'
                    : 'assets/logo_app_noir.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(flex: 2), // Pousse les cartes vers le bas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.2,
                children: [
              _buildModernCard(
                context: context,
                title: "Métrique",
                icon: Icons.architecture,
                iconColor: const Color(0xFF4ECDC4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                themeService: themeService,
              ),
              _buildModernCard(
                context: context,
                title: "Carte",
                icon: Icons.map,
                iconColor: const Color(0xFF5FA8D3),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );
                },
                themeService: themeService,
              ),
              _buildModernCard(
                context: context,
                title: "Planification",
                icon: Icons.calendar_today,
                iconColor: const Color(0xFFE85D75),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CalendarScreen()),
                  );
                },
                themeService: themeService,
              ),
              _buildModernCard(
                context: context,
                title: "Mails",
                icon: Icons.mail_outline,
                iconColor: const Color(0xFFFFA07A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MailScreen()),
                  );
                },
                themeService: themeService,
              ),
                ],
              ),
            ),
            const Spacer(flex: 1), // Espace pour la future navbar
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: themeService.isDarkMode
              ? const Color(0xFF2A2A2A) // Gris foncé pour les cartes
              : const Color(0xFFFFFFFF), // Blanc
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: themeService.isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
