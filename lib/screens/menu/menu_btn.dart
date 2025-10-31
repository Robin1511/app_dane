import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../services/theme_service.dart';

class MenuBtn extends StatelessWidget {
  const MenuBtn({super.key, required this.press, required this.riveOnInit});

  final VoidCallback press;
  final ValueChanged<Artboard> riveOnInit;

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: press,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeService.isDarkMode 
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeService.isDarkMode
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.24),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(themeService.isDarkMode ? 0.35 : 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: RiveAnimation.asset(
                "assets/RiveAssets/menu_button.riv",
                onInit: riveOnInit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
