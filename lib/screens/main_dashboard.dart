import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'photo_screen.dart';
import 'mail_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;

  void _handleNavigation(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  void _showNotifications() {
    final ThemeService themeService = ThemeService();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeService.isDarkMode
                      ? [
                          const Color(0xFF2A2A2A).withOpacity(0.9),
                          const Color(0xFF1A1A1A).withOpacity(0.8),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.9),
                          const Color(0xFFF5F5F5).withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: themeService.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: themeService.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Notification 1
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: themeService.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.info_circle_fill,
                            color: Color(0xFF4ECDC4),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nouvelle mise à jour',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: themeService.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Il y a 2 minutes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Notification 2
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeService.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_down_circle_fill,
                            color: Color(0xFF34C759),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mise à jour disponible',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: themeService.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Il y a 1 heure',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeService.isDarkMode ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Fermer button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: themeService.isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();
    
    return AdaptiveScaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildDashboardContent(), // Page 0: Dashboard
          _buildRecentPlaceholder(),  // Page 1: Dossier récent
          const ProfileScreen(), // Page 2: Profil
          const SettingsScreen(),  // Page 3: Réglages
        ],
      ),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        items: const [
          AdaptiveNavigationDestination(
            icon: 'house.fill',
            label: 'Accueil',
          ),
          AdaptiveNavigationDestination(
            icon: 'folder.fill',
            label: 'Récent',
          ),
          AdaptiveNavigationDestination(
            icon: 'person.fill',
            label: 'Profil',
          ),
          AdaptiveNavigationDestination(
            icon: 'gearshape.fill',
            label: 'Réglages',
          ),
        ],
        selectedIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
          _handleNavigation(index);
        },
        useNativeBottomBar: true,
        selectedItemColor: themeService.isDarkMode 
            ? Colors.white 
            : Colors.black,
        unselectedItemColor: themeService.isDarkMode 
            ? Colors.white.withOpacity(0.5) 
            : Colors.black.withOpacity(0.4),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final ThemeService themeService = ThemeService();
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: themeService.isDarkMode
          ? const Color(0xFF191919)
          : const Color(0xFFFAF7F0),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
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
                    const SizedBox(height: 60),
                    GridView.count(
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
                          heroTag: 'metrique_hero',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
                                transitionDuration: const Duration(milliseconds: 500),
                                reverseTransitionDuration: const Duration(milliseconds: 500),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOutCubic,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          themeService: themeService,
                        ),
                        _buildModernCard(
                          context: context,
                          title: "Carte",
                          icon: Icons.map,
                          iconColor: const Color(0xFF5FA8D3),
                          heroTag: 'carte_hero',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => MapScreen(),
                                transitionDuration: const Duration(milliseconds: 500),
                                reverseTransitionDuration: const Duration(milliseconds: 500),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOutCubic,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          themeService: themeService,
                        ),
                        _buildModernCard(
                          context: context,
                          title: "Planification",
                          icon: Icons.camera_alt,
                          iconColor: const Color(0xFFE85D75),
                          heroTag: 'planning_hero',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => PhotoScreen(),
                                transitionDuration: const Duration(milliseconds: 500),
                                reverseTransitionDuration: const Duration(milliseconds: 500),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOutCubic,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          themeService: themeService,
                        ),
                        _buildModernCard(
                          context: context,
                          title: "Mails",
                          icon: Icons.mail_outline,
                          iconColor: const Color(0xFFFFA07A),
                          heroTag: 'mail_hero',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => MailScreen(),
                                transitionDuration: const Duration(milliseconds: 500),
                                reverseTransitionDuration: const Duration(milliseconds: 500),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeInOutCubic,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          themeService: themeService,
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // Bouton de notification en haut à droite
            Positioned(
              top: 16,
              right: 16,
              child: SizedBox(
                width: 36,
                height: 36,
                child: AdaptiveButton.sfSymbol(
                  onPressed: _showNotifications,
                  sfSymbol: const SFSymbol('bell.fill', size: 18),
                  style: AdaptiveButtonStyle.glass,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPlaceholder() {
    final ThemeService themeService = ThemeService();
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: themeService.isDarkMode
          ? const Color(0xFF191919)
          : const Color(0xFFFAF7F0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_rounded,
              size: 80,
              color: themeService.isDarkMode
                  ? Colors.white.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Dossiers récents',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: themeService.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'À venir',
              style: TextStyle(
                fontSize: 16,
                color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
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
    required String heroTag,
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
            Hero(
              tag: heroTag,
              child: Container(
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
