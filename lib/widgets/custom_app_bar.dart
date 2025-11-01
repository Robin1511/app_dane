import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../screens/entry_point.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showHomeButton;
  final bool showDarkModeToggle;
  final bool showSettingsButton;
  final VoidCallback? onSettingsPressed;
  final bool isTransparent;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showHomeButton = true,
    this.showDarkModeToggle = true,
    this.showSettingsButton = true,
    this.onSettingsPressed,
    this.isTransparent = false,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return AppBar(
          backgroundColor: isTransparent 
            ? Colors.transparent 
            : themeService.backgroundColor,
          elevation: 0,
          leading: showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: themeService.textColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
          automaticallyImplyLeading: false,
          title: title.isNotEmpty
            ? Text(
                title,
                style: TextStyle(
                  color: themeService.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : null,
          actions: _buildActions(context, themeService),
        );
      },
    );
  }

  List<Widget> _buildActions(BuildContext context, ThemeService themeService) {
    List<Widget> actions = [];

    // Bouton Home
    if (showHomeButton) {
      actions.add(
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8),
          decoration: BoxDecoration(
            color: themeService.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.home_rounded,
              color: themeService.primaryColor,
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const EntryPoint()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Retour au dashboard',
          ),
        ),
      );
    }

    // Bouton Dark Mode Toggle
    if (showDarkModeToggle) {
      actions.add(
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8),
          decoration: BoxDecoration(
            color: themeService.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: themeService.secondaryColor,
            ),
            onPressed: () async {
              await themeService.toggleTheme();
            },
            tooltip: themeService.isDarkMode ? 'Mode clair' : 'Mode sombre',
          ),
        ),
      );
    }

    // Bouton Settings
    if (showSettingsButton) {
      actions.add(
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8),
          decoration: BoxDecoration(
            color: themeService.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.settings,
              color: themeService.isDarkMode ? Colors.white : const Color(0xFF2196F3),
            ),
            onPressed: onSettingsPressed ?? () {
              scaffoldKey?.currentState?.openEndDrawer();
            },
            tooltip: 'Réglages',
          ),
        ),
      );
    }

    return actions;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 