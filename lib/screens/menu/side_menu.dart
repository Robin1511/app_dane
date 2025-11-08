import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../../services/theme_service.dart';

import 'menu.dart';

class SideMenu extends StatelessWidget {
  const SideMenu(
      {super.key,
      required this.menu,
      required this.press,
      required this.riveOnInit,
      required this.selectedMenu});

  final Menu menu;
  final VoidCallback press;
  final ValueChanged<Artboard> riveOnInit;
  final Menu selectedMenu;

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();
    final bool isSelected = selectedMenu == menu;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        height: 56,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              width: isSelected ? 264 : 0,
              height: 56,
              left: 0,
              top: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeService.isDarkMode
                        ? [
                            const Color(0xFF4ECDC4).withOpacity(0.3),
                            const Color(0xFF44A8F0).withOpacity(0.3),
                          ]
                        : [
                            const Color(0xFF4ECDC4).withOpacity(0.2),
                            const Color(0xFF44A8F0).withOpacity(0.2),
                          ],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  border: Border.all(
                    color: themeService.isDarkMode
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              minVerticalPadding: 0,
              dense: false,
              onTap: press,
              leading: SizedBox(
                height: 36,
                width: 36,
                child: RiveAnimation.asset(
                  menu.rive.src,
                  artboard: menu.rive.artboard,
                  onInit: riveOnInit,
                ),
              ),
              title: Text(
                menu.title,
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}