import 'package:flutter/material.dart';

class NavigationButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDarkMode;
  final IconData icon;
  final String tooltip;
  final Color? customColor;

  const NavigationButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.isDarkMode = false,
    this.tooltip = '',
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
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
          icon,
          color: customColor ?? (isDarkMode ? Colors.white : const Color(0xFF2196F3)),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

// Widget spécialisé pour les réglages (pour compatibilité)
class SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDarkMode;

  const SettingsButton({
    super.key,
    required this.onPressed,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationButton(
      onPressed: onPressed,
      icon: Icons.settings,
      isDarkMode: isDarkMode,
      tooltip: 'Réglages',
    );
  }
}

// Nouveau widget pour le bouton home
class HomeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDarkMode;

  const HomeButton({
    super.key,
    required this.onPressed,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationButton(
      onPressed: onPressed,
      icon: Icons.home_rounded,
      isDarkMode: isDarkMode,
      tooltip: 'Accueil',
      customColor: isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFFE91E63),
    );
  }
} 