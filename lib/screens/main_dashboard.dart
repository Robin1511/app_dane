import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'mail_screen.dart';
import 'map_screen.dart';

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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _themeService.isDarkMode ? const Color(0xFF2D2D44) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
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
                color: _themeService.textColor,
              ),
              title: Text(
                'Métrique',
                style: TextStyle(color: _themeService.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _onCardTap('metrique');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.map,
                color: _themeService.textColor,
              ),
              title: Text(
                'Carte',
                style: TextStyle(color: _themeService.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _onCardTap('map');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today,
                color: _themeService.textColor,
              ),
              title: Text(
                'Planification',
                style: TextStyle(color: _themeService.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _onCardTap('planning');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.mail_outline,
                color: _themeService.textColor,
              ),
              title: Text(
                'Mails',
                style: TextStyle(color: _themeService.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _onCardTap('contacts');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                _themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: _themeService.textColor,
              ),
              title: Text(
                _themeService.isDarkMode ? 'Mode clair' : 'Mode sombre',
                style: TextStyle(color: _themeService.textColor),
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
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF2D2D44) : Colors.white,
        title: Text(
          'Notifications',
          style: TextStyle(color: _themeService.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: Text(
                'Bienvenue dans votre dashboard !',
                style: TextStyle(color: _themeService.textColor),
              ),
              subtitle: Text(
                'Il y a 2 minutes',
                style: TextStyle(color: _themeService.textColor.withOpacity(0.6)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.update, color: Colors.green),
              title: Text(
                'Mise à jour disponible',
                style: TextStyle(color: _themeService.textColor),
              ),
              subtitle: Text(
                'Il y a 1 heure',
                style: TextStyle(color: _themeService.textColor.withOpacity(0.6)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: _themeService.secondaryColor),
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
      backgroundColor: _themeService.isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _themeService.textColor,
              ),
        ),
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey[50],
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _showNotifications,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
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
        ],
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onTap: _showDrawer,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu_rounded,
                color: _themeService.isDarkMode ? Colors.white : Colors.blueGrey,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              "Mes Applications",
              style: TextStyle(
                color: _themeService.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildGrid(),
            ),
          ],
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