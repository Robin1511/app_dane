import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/theme_service.dart';
import 'login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  void _showReportProblemDialog() {
    final ThemeService themeService = ThemeService();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final emailController = TextEditingController();
    String selectedSubject = 'Bug';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeService.isDarkMode
                      ? [
                          const Color(0xFF2A2A2A).withOpacity(0.95),
                          const Color(0xFF1A1A1A).withOpacity(0.95),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.95),
                          const Color(0xFFF5F5F5).withOpacity(0.95),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: themeService.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signaler un problème',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Dropdown Sujet
                    Text(
                      'Sujet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: themeService.isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeService.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubject,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          dropdownColor: themeService.isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          style: TextStyle(
                            color: themeService.isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          items: ['Bug', 'Suggestion', 'Autre'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setDialogState(() {
                                selectedSubject = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      style: TextStyle(
                        color: themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'votre@email.com',
                        hintStyle: TextStyle(
                          color: themeService.isDarkMode
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: themeService.isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeService.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeService.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeService.isDarkMode
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 5,
                      style: TextStyle(
                        color: themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Décrivez le problème...',
                        hintStyle: TextStyle(
                          color: themeService.isDarkMode
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: themeService.isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeService.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeService.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: themeService.isDarkMode
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Boutons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: themeService.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implémenter l'envoi du rapport
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Problème signalé avec succès !'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Envoyer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final ThemeService themeService = ThemeService();
    
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: themeService.isDarkMode
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: themeService.isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
            ),
          ),
          title: Text(
            'À propos',
            style: TextStyle(
              color: themeService.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  themeService.isDarkMode
                      ? 'assets/logo_app_blanc.png'
                      : 'assets/logo_app_noir.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MetriX',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: themeService.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $_appVersion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Application de gestion pour conducteurs de travaux.',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
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
                  color: const Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) {
        final ThemeService themeService = ThemeService();
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: themeService.isDarkMode
                ? const Color(0xFF2A2A2A)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: themeService.isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            title: Text(
              'Déconnexion',
              style: TextStyle(
                color: themeService.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Voulez-vous vraiment vous déconnecter ?',
              style: TextStyle(
                color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: themeService.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: themeService.isDarkMode
          ? const Color(0xFF191919)
          : const Color(0xFFFAF7F0),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logo
              Center(
                child: Image.asset(
                  themeService.isDarkMode
                      ? 'assets/logo_app_blanc.png'
                      : 'assets/logo_app_noir.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              
              // Section Apparence
              _buildSectionCard(
                title: 'APPARENCE',
                children: [
                  _buildSettingTile(
                    icon: themeService.isDarkMode
                        ? CupertinoIcons.moon_fill
                        : CupertinoIcons.sun_max_fill,
                    title: 'Mode sombre',
                    trailing: CupertinoSwitch(
                      value: themeService.isDarkMode,
                      onChanged: (value) async {
                        await themeService.toggleTheme();
                        setState(() {});
                      },
                      activeColor: const Color(0xFF34C759), // iOS green
                      trackColor: themeService.isDarkMode
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.08),
                    ),
                    themeService: themeService,
                  ),
                ],
                themeService: themeService,
              ),
              const SizedBox(height: 16),
              
              // Section Support
              _buildSectionCard(
                title: 'SUPPORT',
                children: [
                  _buildSettingTile(
                    icon: CupertinoIcons.exclamationmark_bubble_fill,
                    title: 'Signaler un problème',
                    onTap: _showReportProblemDialog,
                    themeService: themeService,
                  ),
                ],
                themeService: themeService,
              ),
              const SizedBox(height: 16),
              
              // Section Informations
              _buildSectionCard(
                title: 'INFORMATIONS',
                children: [
                  _buildSettingTile(
                    icon: CupertinoIcons.info_circle_fill,
                    title: 'Version',
                    subtitle: _appVersion.isEmpty ? 'Chargement...' : _appVersion,
                    themeService: themeService,
                  ),
                  Divider(
                    height: 1,
                    color: themeService.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                  _buildSettingTile(
                    icon: CupertinoIcons.doc_text_fill,
                    title: 'Conditions d\'utilisation',
                    onTap: () {
                      // TODO: Afficher les CGU
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CGU - À venir')),
                      );
                    },
                    themeService: themeService,
                  ),
                  Divider(
                    height: 1,
                    color: themeService.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                  _buildSettingTile(
                    icon: CupertinoIcons.shield_fill,
                    title: 'Politique de confidentialité',
                    onTap: () {
                      // TODO: Afficher la politique de confidentialité
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Politique de confidentialité - À venir')),
                      );
                    },
                    themeService: themeService,
                  ),
                ],
                themeService: themeService,
              ),
              const SizedBox(height: 16),
              
              // Section Compte
              _buildSectionCard(
                title: 'COMPTE',
                children: [
                  _buildSettingTile(
                    icon: CupertinoIcons.info_circle,
                    title: 'À propos',
                    onTap: _showAboutDialog,
                    themeService: themeService,
                  ),
                  Divider(
                    height: 1,
                    color: themeService.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                  _buildSettingTile(
                    icon: CupertinoIcons.arrow_right_square_fill,
                    title: 'Se déconnecter',
                    onTap: _handleLogout,
                    themeService: themeService,
                    textColor: Colors.red,
                  ),
                ],
                themeService: themeService,
              ),
              const SizedBox(height: 100), // Espace pour la navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required ThemeService themeService,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeService.isDarkMode
                  ? [
                      const Color(0xFF2A2A2A).withOpacity(0.7),
                      const Color(0xFF1A1A1A).withOpacity(0.5),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withOpacity(0.7),
                      const Color(0xFFF5F5F5).withOpacity(0.5),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 1.5,
              color: themeService.isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: themeService.isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required ThemeService themeService,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: textColor ?? (themeService.isDarkMode
                    ? Colors.white
                    : Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor ?? (themeService.isDarkMode
                            ? Colors.white
                            : Colors.black87),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: themeService.isDarkMode
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: themeService.isDarkMode
                      ? Colors.white.withOpacity(0.3)
                      : Colors.black.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

