import 'package:flutter/material.dart';
import 'dart:ui';

import 'menu.dart';
import 'rive_utils.dart';
import 'info_card.dart';
import 'side_menu.dart';
import '../../services/theme_service.dart';

class SideBar extends StatefulWidget {
  final Function(String)? onMenuTap;
  final Function()? onThemeToggle;
  final Function()? onNotificationTap;
  final Function()? onLogout;

  const SideBar({
    super.key,
    this.onMenuTap,
    this.onThemeToggle,
    this.onNotificationTap,
    this.onLogout,
  });

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Menu? selectedSideMenu;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
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

  void _handleMenuTap(Menu menu) {
    RiveUtils.chnageSMIBoolState(menu.rive.status!);
    setState(() {
      selectedSideMenu = menu;
    });

    // Appeler le callback approprié (le menu sera fermé par le parent)
    if (menu.title == "Métrique") {
      widget.onMenuTap?.call('metrique');
    } else if (menu.title == "Carte") {
      widget.onMenuTap?.call('map');
    } else if (menu.title == "Planification") {
      widget.onMenuTap?.call('planning');
    } else if (menu.title == "Mails") {
      widget.onMenuTap?.call('contacts');
    } else if (menu.title == "Notifications") {
      widget.onNotificationTap?.call();
    } else if (menu.title == "Mode clair" || menu.title == "Mode sombre") {
      widget.onThemeToggle?.call();
    } else if (menu.title == "Déconnexion") {
      widget.onLogout?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMenuTitle = _themeService.isDarkMode ? "Mode clair" : "Mode sombre";
    
    // Créer une liste modifiée pour sidebarMenus2 avec le titre dynamique
    final List<Menu> modifiedSidebarMenus2 = sidebarMenus2.map((menu) {
      if (menu.title == "Mode clair" || menu.title == "Mode sombre") {
        return Menu(
          title: themeMenuTitle,
          rive: menu.rive,
        );
      }
      return menu;
    }).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: 288,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _themeService.isDarkMode
                  ? [
                      const Color(0xFF1a1a1a).withOpacity(0.7),
                      const Color(0xFF2d2d2d).withOpacity(0.5),
                    ]
                  : [
                      const Color(0xFFffffff).withOpacity(0.7),
                      const Color(0xFFf5f5f5).withOpacity(0.5),
                    ],
            ),
            borderRadius: const BorderRadius.all(Radius.circular(30)),
            border: Border.all(
              width: 1.5,
              color: _themeService.isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: DefaultTextStyle(
              style: TextStyle(
                color: _themeService.isDarkMode ? Colors.white : Colors.black87,
              ),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InfoCard(
                name: "Dane De Bastos",
                bio: "Conducteur de travaux",
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
                child: Text(
                  "Applications".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(
                        color: _themeService.isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              ...sidebarMenus.map((menu) => SideMenu(
                    menu: menu,
                    selectedMenu: selectedSideMenu ?? sidebarMenus.first,
                    press: () => _handleMenuTap(menu),
                    riveOnInit: (artboard) {
                      menu.rive.status = RiveUtils.getRiveInput(artboard,
                          stateMachineName: menu.rive.stateMachineName);
                    },
                  )),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                child: Text(
                  "Paramètres".toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(
                        color: _themeService.isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              ...modifiedSidebarMenus2.map((menu) => SideMenu(
                    menu: menu,
                    selectedMenu: selectedSideMenu ?? modifiedSidebarMenus2.first,
                    press: () => _handleMenuTap(menu),
                    riveOnInit: (artboard) {
                      menu.rive.status = RiveUtils.getRiveInput(artboard,
                          stateMachineName: menu.rive.stateMachineName);
                    },
                  )),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
