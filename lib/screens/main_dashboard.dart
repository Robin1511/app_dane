import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../widgets/dashboard_card.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'mail_screen.dart';
import 'map_screen.dart';
import 'login/login_screen.dart';
import 'menu/menu_btn.dart';
import 'menu/side_bar.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with SingleTickerProviderStateMixin {
  final ThemeService _themeService = ThemeService();
  bool isSideBarOpen = false;
  SMIBool? _menuBtnInput;

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
    
    // Initialiser les animations
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(
        () {
          setState(() {});
        },
      );
    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.fastOutSlowIn));
    animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.fastOutSlowIn));
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onMenuBtnInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
        artboard, "State Machine");
    
    if (controller != null) {
      artboard.addController(controller);
      _menuBtnInput = controller.findInput<bool>("isOpen") as SMIBool?;
      if (_menuBtnInput != null) {
        _menuBtnInput!.value = true;
      }
    }
  }

  void _toggleMenu() {
    if (_menuBtnInput != null) {
      _menuBtnInput!.value = !_menuBtnInput!.value;
    }

    if (_animationController.value == 0) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    setState(() {
      isSideBarOpen = !isSideBarOpen;
    });
  }

  void _handleNotificationTap() {
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

  void _handleThemeToggle() async {
    await _themeService.toggleTheme();
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: _themeService.isDarkMode
          ? const Color(0xFF000000)
          : const Color(0xFFFAF7F0),
      body: Stack(
        children: [
          // Fond qui s'étend pour englober le contenu
          AnimatedPositioned(
            width: isSideBarOpen ? MediaQuery.of(context).size.width : 0,
            height: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: 0,
            top: 0,
            child: Container(
              color: const Color(0xFF17203A),
            ),
          ),
          // SideBar avec coins arrondis à droite
          AnimatedPositioned(
            width: 288,
            height: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideBarOpen ? 0 : -288,
            top: 0,
            child: SideBar(
              onMenuTap: (cardType) {
                _toggleMenu(); // Fermer le menu après navigation
                _onCardTap(cardType);
              },
              onThemeToggle: () {
                _toggleMenu(); // Fermer le menu après toggle
                _handleThemeToggle();
              },
              onNotificationTap: () {
                _toggleMenu(); // Fermer le menu après ouverture notifications
                _handleNotificationTap();
              },
              onLogout: () {
                _handleLogout();
              },
            ),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(1 * animation.value - 30 * (animation.value) * pi / 180),
            child: Transform.translate(
              offset: Offset(animation.value * 265, 0),
              child: Transform.scale(
                scale: scalAnimation.value,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(24),
                  ),
                  child: Scaffold(
                    extendBodyBehindAppBar: true,
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
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
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideBarOpen ? 220 : 0,
            top: 16,
            child: MenuBtn(
              press: _toggleMenu,
              riveOnInit: _onMenuBtnInit,
            ),
          ),
        ],
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