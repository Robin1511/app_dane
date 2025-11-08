import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/theme_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ThemeService _themeService = ThemeService();
  
  // User data state
  String _userName = 'Dane De Bastos';
  final String _userEmail = 'dane.debastos@privaterelay.appleid.com';
  String? _avatarPath;
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _nameController.text = _userName;
    _themeService.addListener(_onThemeChanged);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }
  
  void _onThemeChanged() {
    setState(() {});
  }
  
  void _showEditDialog() {
    _nameController.text = _userName;
    
    showDialog(
      context: context,
      builder: (context) => _buildEditDialog(),
    );
  }
  
  void _showAvatarPicker() {
    showDialog(
      context: context,
      builder: (context) => _buildAvatarPickerDialog(),
    );
  }
  
  void _showTeamManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildTeamManagementDialog(),
    );
  }
  
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _avatarPath = image.path;
      });
      if (mounted) Navigator.of(context).pop();
    }
  }
  
  void _selectPredefinedAvatar(int index) {
    setState(() {
      _avatarPath = 'predefined_$index';
    });
    Navigator.of(context).pop();
  }
  
  void _showConductorsList() {
    showDialog(
      context: context,
      builder: (context) => _buildConductorsListDialog(),
    );
  }
  
  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildAddMemberDialog(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _themeService.isDarkMode
          ? const Color(0xFF191919)
          : const Color(0xFFFAF7F0),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  
                  // Avatar
                  GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _themeService.isDarkMode
                              ? [
                                  const Color(0xFF4ECDC4),
                                  const Color(0xFF44A8F0),
                                ]
                              : [
                                  const Color(0xFF44A8F0),
                                  const Color(0xFF4ECDC4),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _avatarPath != null && _avatarPath!.startsWith('/') && File(_avatarPath!).existsSync()
                          ? ClipOval(
                              child: Image.file(
                                File(_avatarPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : _avatarPath != null && _avatarPath!.startsWith('predefined_')
                              ? ClipOval(
                                  child: Center(
                                    child: Icon(
                                      _getPredefinedAvatarIcon(int.parse(_avatarPath!.split('_')[1])),
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  CupertinoIcons.person_fill,
                                  size: 60,
                                  color: Colors.white,
                                ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Name
                  Text(
                    _userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Email
                  Text(
                    _userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: _themeService.isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Team Management Section
                  _buildSectionCard(
                    title: 'GESTION D\'ÉQUIPE',
                    children: [
                      _buildSettingTile(
                        icon: CupertinoIcons.person_2_fill,
                        title: 'Assigner des ouvriers',
                        onTap: _showTeamManagementDialog,
                      ),
                      Divider(
                        height: 1,
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                      _buildSettingTile(
                        icon: CupertinoIcons.person_3_fill,
                        title: 'Liste des conducteurs',
                        onTap: _showConductorsList,
                      ),
                      Divider(
                        height: 1,
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                      _buildSettingTile(
                        icon: CupertinoIcons.person_badge_plus_fill,
                        title: 'Ajouter un membre',
                        onTap: _showAddMemberDialog,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 100), // Space for navbar
                ],
              ),
            ),
            // Edit button in top right
            Positioned(
              top: 16,
              right: 16,
              child: SizedBox(
                width: 36,
                height: 36,
                child: AdaptiveButton.sfSymbol(
                  onPressed: _showEditDialog,
                  sfSymbol: const SFSymbol('square.and.pencil', size: 18),
                  style: AdaptiveButtonStyle.glass,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
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
              colors: _themeService.isDarkMode
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
              color: _themeService.isDarkMode
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
                    color: _themeService.isDarkMode
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
    VoidCallback? onTap,
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
                color: _themeService.isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _themeService.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 20,
                color: _themeService.isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEditDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _themeService.isDarkMode
                    ? [
                        const Color(0xFF2A2A2A).withOpacity(0.9),
                        const Color(0xFF1A1A1A).withOpacity(0.8),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withOpacity(0.9),
                        const Color(0xFFF5F5F5).withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1.5,
                color: _themeService.isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifier le profil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Avatar preview
                Center(
                  child: GestureDetector(
                    onTap: _showAvatarPicker,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _themeService.isDarkMode
                                  ? [
                                      const Color(0xFF4ECDC4),
                                      const Color(0xFF44A8F0),
                                    ]
                                  : [
                                      const Color(0xFF44A8F0),
                                      const Color(0xFF4ECDC4),
                                    ],
                            ),
                          ),
                          child: _avatarPath != null && _avatarPath!.startsWith('/') && File(_avatarPath!).existsSync()
                              ? ClipOval(
                                  child: Image.file(
                                    File(_avatarPath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _avatarPath != null && _avatarPath!.startsWith('predefined_')
                                  ? ClipOval(
                                      child: Center(
                                        child: Icon(
                                          _getPredefinedAvatarIcon(int.parse(_avatarPath!.split('_')[1])),
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      CupertinoIcons.person_fill,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _themeService.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.camera_fill,
                              size: 16,
                              color: _themeService.isDarkMode
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Name field
                Text(
                  'Nom',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _themeService.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _themeService.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Email field (read-only)
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _themeService.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _themeService.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _userEmail,
                    style: TextStyle(
                      color: _themeService.isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _themeService.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _userName = _nameController.text;
                          });
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF34C759),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enregistrer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAvatarPickerDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _themeService.isDarkMode
                    ? [
                        const Color(0xFF2A2A2A).withOpacity(0.9),
                        const Color(0xFF1A1A1A).withOpacity(0.8),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withOpacity(0.9),
                        const Color(0xFFF5F5F5).withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1.5,
                color: _themeService.isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choisir un avatar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Grid of predefined avatars
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _selectPredefinedAvatar(index),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getPredefinedAvatarColors(index),
                          ),
                        ),
                        child: Icon(
                          _getPredefinedAvatarIcon(index),
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Gallery button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _pickImageFromGallery,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _themeService.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.photo,
                          color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Choisir de la galerie',
                          style: TextStyle(
                            color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamManagementDialog() {
    // Hardcoded data
    final List<Map<String, dynamic>> conducteurs = [
      {'name': 'Dane De Bastos', 'assignedCount': 3},
      {'name': 'Marc Dubois', 'assignedCount': 5},
      {'name': 'Sophie Martin', 'assignedCount': 2},
    ];
    
    final List<String> ouvriers = [
      'Jean Dupont',
      'Pierre Martin',
      'Luc Bernard',
      'Paul Petit',
      'Antoine Rousseau',
    ];
    
    String? selectedConducteur = conducteurs.first['name'];
    String? selectedOuvrier = ouvriers.first;
    
    return StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _themeService.isDarkMode
                      ? [
                          const Color(0xFF2A2A2A).withOpacity(0.9),
                          const Color(0xFF1A1A1A).withOpacity(0.8),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.9),
                          const Color(0xFFF5F5F5).withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: _themeService.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigner des ouvriers',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Select conducteur
                    Text(
                      'Conducteur de travaux',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _themeService.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedConducteur,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: _themeService.isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        items: conducteurs.map((conducteur) {
                          return DropdownMenuItem<String>(
                            value: conducteur['name'],
                            child: Text('${conducteur['name']} (${conducteur['assignedCount']} ouvriers)'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedConducteur = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Select ouvrier
                    Text(
                      'Ouvrier',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _themeService.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedOuvrier,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: _themeService.isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        items: ouvriers.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedOuvrier = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: _themeService.isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$selectedOuvrier assigné à $selectedConducteur')),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF34C759),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Assigner',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
  
  Widget _buildConductorsListDialog() {
    final List<Map<String, dynamic>> conducteurs = [
      {'name': 'Dane De Bastos', 'assignedCount': 3, 'ouvriers': ['Jean Dupont', 'Pierre Martin', 'Luc Bernard']},
      {'name': 'Marc Dubois', 'assignedCount': 5, 'ouvriers': ['Paul Petit', 'Antoine Rousseau', 'Thomas Girard', 'Louis Moreau', 'François Lambert']},
      {'name': 'Sophie Martin', 'assignedCount': 2, 'ouvriers': ['Nicolas Bonnet', 'Julien Simon']},
    ];
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _themeService.isDarkMode
                    ? [
                        const Color(0xFF2A2A2A).withOpacity(0.9),
                        const Color(0xFF1A1A1A).withOpacity(0.8),
                      ]
                    : [
                        const Color(0xFFFFFFFF).withOpacity(0.9),
                        const Color(0xFFF5F5F5).withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1.5,
                color: _themeService.isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Conducteurs de travaux',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: conducteurs.map((conducteur) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _themeService.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF44A8F0),
                                          const Color(0xFF4ECDC4),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.person_fill,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          conducteur['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '${conducteur['assignedCount']} ouvriers assignés',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _themeService.isDarkMode ? Colors.white60 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (conducteur['ouvriers'] as List<String>).map((ouvrier) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _themeService.isDarkMode
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ouvrier,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _themeService.isDarkMode ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _themeService.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Fermer',
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAddMemberDialog() {
    final TextEditingController nameController = TextEditingController();
    String selectedRole = 'Ouvrier';
    
    return StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _themeService.isDarkMode
                      ? [
                          const Color(0xFF2A2A2A).withOpacity(0.9),
                          const Color(0xFF1A1A1A).withOpacity(0.8),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.9),
                          const Color(0xFFF5F5F5).withOpacity(0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1.5,
                  color: _themeService.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajouter un membre',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name field
                    Text(
                      'Nom',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _themeService.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Role dropdown
                    Text(
                      'Rôle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _themeService.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: _themeService.isDarkMode
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        style: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        items: ['Ouvrier', 'Conducteur de travaux'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              selectedRole = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: _themeService.isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${nameController.text} ajouté comme $selectedRole')),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF34C759),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Ajouter',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
  
  IconData _getPredefinedAvatarIcon(int index) {
    final icons = [
      CupertinoIcons.person_fill,
      CupertinoIcons.smiley_fill,
      CupertinoIcons.star_fill,
      CupertinoIcons.heart_fill,
      CupertinoIcons.flame_fill,
      CupertinoIcons.bolt_fill,
    ];
    return icons[index % icons.length];
  }
  
  List<Color> _getPredefinedAvatarColors(int index) {
    final colors = [
      [const Color(0xFF44A8F0), const Color(0xFF4ECDC4)],
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      [const Color(0xFFFFD93D), const Color(0xFFFFA83D)],
      [const Color(0xFF6BCF7F), const Color(0xFF4ECDC4)],
      [const Color(0xFFB388FF), const Color(0xFF7C4DFF)],
      [const Color(0xFFFF4081), const Color(0xFFF50057)],
    ];
    return colors[index % colors.length];
  }
}

