import 'package:flutter/material.dart';

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

    return Container(
      width: 288,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF17203A),
        borderRadius: BorderRadius.all(
          Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
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
                      .copyWith(color: Colors.white70),
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
                      .copyWith(color: Colors.white70),
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
    );
  }
}
