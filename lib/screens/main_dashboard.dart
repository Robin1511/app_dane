import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'mail_screen.dart';
import 'map_screen.dart';
import 'login/login_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _themeService.isDarkMode 
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                top: BorderSide(
                  color: _themeService.isDarkMode
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.24),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_themeService.isDarkMode ? 0.35 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.architecture,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Métrique',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onCardTap('metrique');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.map,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Carte',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onCardTap('map');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Planification',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onCardTap('planning');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.mail_outline,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Mails',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _onCardTap('contacts');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      _themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                    ),
                    title: Text(
                      _themeService.isDarkMode ? 'Mode clair' : 'Mode sombre',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      await _themeService.toggleTheme();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode 
            ? const Color(0xFF000000) // noir profond
            : const Color(0xFFFAF7F0), // crème
        title: Text(
          'Notifications',
          style: TextStyle(
            color: _themeService.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.info,
                color: _themeService.isDarkMode ? Colors.white : Colors.blue,
              ),
              title: Text(
                'Bienvenue dans votre dashboard !',
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Il y a 2 minutes',
                style: TextStyle(
                  color: _themeService.isDarkMode 
                      ? Colors.white70 
                      : Colors.grey[600]!,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.update,
                color: _themeService.isDarkMode ? Colors.white : Colors.green,
              ),
              title: Text(
                'Mise à jour disponible',
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Il y a 1 heure',
                style: TextStyle(
                  color: _themeService.isDarkMode 
                      ? Colors.white70 
                      : Colors.grey[600]!,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: _themeService.isDarkMode 
                    ? Colors.white 
                    : _themeService.secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCardTap(String cardType) async {
    if (cardType == 'metrique') {
      // Navigation vers l'app métrique actuelle
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else if (cardType == 'planning') {
      // Navigation vers le calendrier
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CalendarScreen()),
      );
    } else if (cardType == 'contacts') {
      // Navigation vers l'app de mail
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MailScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else if (cardType == 'map') {
      // Navigation vers l'app de carte
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MapScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
    // Ajouter d'autres navigations ici pour les autres cartes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _themeService.textColor,
              ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _showNotifications,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _themeService.isDarkMode 
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white.withOpacity(0.24),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_themeService.isDarkMode ? 0.35 : 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: _themeService.isDarkMode ? Colors.white : Colors.blueGrey,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onTap: _showDrawer,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _themeService.isDarkMode 
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _themeService.isDarkMode
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white.withOpacity(0.24),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(_themeService.isDarkMode ? 0.35 : 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: _themeService.isDarkMode ? Colors.white : Colors.blueGrey,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: _themeService.isDarkMode
            ? const Color(0xFF000000) // fond noir profond
            : const Color(0xFFFAF7F0), // fond crème en light
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mes Applications",
                  style: TextStyle(
                    color: _themeService.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 0.8,
      children: [
        DashboardCard(
          title: "Métrique",
          subtitle: "Gestion des projets",
          icon: Icons.architecture,
          color: Colors.blue,
          onTap: () => _onCardTap('metrique'),
        ),
        DashboardCard(
          title: "Carte",
          subtitle: "Navigation & POI",
          icon: Icons.map,
          color: Colors.green,
          isSmall: true,
          onTap: () => _onCardTap('map'),
        ),
        DashboardCard(
          title: "Planification",
          subtitle: "Calendrier & tâches",
          icon: Icons.calendar_today,
          color: Colors.orange,
          onTap: () => _onCardTap('planning'),
        ),
        DashboardCard(
          title: "Mails",
          subtitle: "Outlook & messagerie",
          icon: Icons.mail_outline,
          color: Colors.purple,
          isSmall: true,
          onTap: () => _onCardTap('contacts'),
        ),
      ],
    );
  }
} 