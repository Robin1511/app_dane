import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'home_screen.dart';
import 'photo_screen.dart';
import 'mail_screen.dart';
import 'map_screen.dart';
import 'login/login_screen.dart';
import '../services/theme_service.dart';
import 'menu/rive_utils.dart';

import 'menu/menu.dart';
import 'menu/menu_btn.dart';
import 'menu/side_bar.dart';
import 'main_dashboard.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint>
    with SingleTickerProviderStateMixin {
  bool isSideBarOpen = false;

  Menu selectedBottonNav = bottomNavItems.first;
  Menu selectedSideMenu = sidebarMenus.first;

  SMIBool? isMenuOpenInput;
  final ThemeService _themeService = ThemeService();

  void updateSelectedBtmNav(Menu menu) {
    if (selectedBottonNav != menu) {
      setState(() {
        selectedBottonNav = menu;
      });
    }
  }

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  @override
  void initState() {
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
    
    _themeService.addListener(_onThemeChanged);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleMenu() {
    if (isMenuOpenInput != null) {
      isMenuOpenInput!.value = !isMenuOpenInput!.value;
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

  void _handleMenuTap(String menuType) {
    _toggleMenu(); // Fermer le menu
    
    // Navigation selon le type
    if (menuType == 'metrique') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (menuType == 'map') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
    } else if (menuType == 'planning') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PhotoScreen()),
      );
    } else if (menuType == 'contacts') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MailScreen()),
      );
    }
  }

  void _handleNotificationTap() {
    _toggleMenu();
    final ThemeService themeService = ThemeService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeService.isDarkMode 
            ? const Color(0xFF000000) // noir profond
            : const Color(0xFFFAF7F0), // crème
        title: Text(
          'Notifications',
          style: TextStyle(
            color: themeService.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.info,
                color: themeService.isDarkMode ? Colors.white : Colors.blue,
              ),
              title: Text(
                'Bienvenue dans votre dashboard !',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Il y a 2 minutes',
                style: TextStyle(
                  color: themeService.isDarkMode 
                      ? Colors.white70 
                      : Colors.grey[600]!,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.update,
                color: themeService.isDarkMode ? Colors.white : Colors.green,
              ),
              title: Text(
                'Mise à jour disponible',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Il y a 1 heure',
                style: TextStyle(
                  color: themeService.isDarkMode 
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
                color: themeService.isDarkMode 
                    ? Colors.white 
                    : themeService.secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleThemeToggle() async {
    _toggleMenu();
    // Toggle theme
    await ThemeService().toggleTheme();
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();
    
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: themeService.isDarkMode
          ? const Color(0xFF000000) // Noir profond comme main_dashboard
          : const Color(0xFFFAF7F0), // Crème comme main_dashboard
      body: Stack(
        children: [
          AnimatedPositioned(
            width: 288,
            height: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideBarOpen ? 0 : -288,
            top: 0,
            child: SideBar(
              onMenuTap: _handleMenuTap,
              onThemeToggle: _handleThemeToggle,
              onNotificationTap: _handleNotificationTap,
              onLogout: _handleLogout,
            ),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(
                  1 * animation.value - 30 * (animation.value) * pi / 180),
            child: Transform.translate(
              offset: Offset(animation.value * 265, 0),
              child: Transform.scale(
                scale: scalAnimation.value,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(24),
                  ),
                  child: HomePage(),
                ),
              ),
            ),
          ),
          // Menu désactivé temporairement
          // AnimatedPositioned(
          //   duration: const Duration(milliseconds: 200),
          //   curve: Curves.fastOutSlowIn,
          //   left: isSideBarOpen ? 220 : 0,
          //   top: 16,
          //   child: MenuBtn(
          //     press: _toggleMenu,
          //     riveOnInit: (artboard) {
          //       final controller = StateMachineController.fromArtboard(
          //           artboard, "State Machine");
          //
          //       if (controller != null) {
          //         artboard.addController(controller);
          //         isMenuOpenInput = controller.findInput<bool>("isOpen") as SMIBool?;
          //         if (isMenuOpenInput != null) {
          //           isMenuOpenInput!.value = true;
          //         }
          //       }
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
