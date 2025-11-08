import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/settings_button.dart';
import '../widgets/address_field.dart';
import '../services/theme_service.dart';
import 'summary_screen.dart';
import 'entry_point.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _referentController = TextEditingController();
  final TextEditingController _travauxController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _accesController = TextEditingController();
  final TextEditingController _newReferentController = TextEditingController();
  
  final ThemeService _themeService = ThemeService();
  bool _isDropdownOpen = false;
  String? _selectedReferent;
  List<String> _referents = [
    'Dane De Bastos',
    'Jose De Bastos', 
    'Robin De Bastos',
  ];
  
  // Variables pour la validation
  bool _referentError = false;
  bool _travauxError = false;
  bool _adresseError = false;

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _referentController.dispose();
    _travauxController.dispose();
    _adresseController.dispose();
    _accesController.dispose();
    _newReferentController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.trash_fill,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Effacer tout ?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tous les champs seront effacés',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _themeService.isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                _selectedReferent = null;
                                _referentController.clear();
                                _travauxController.clear();
                                _adresseController.clear();
                                _accesController.clear();
                              });
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.of(context).pop(); // Close sidebar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Tous les champs ont été effacés'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: _themeService.isDarkMode ? Colors.grey[800] : null,
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Effacer',
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
      },
    );
  }

  void _addNewReferent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                      'Ajouter un référent',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _newReferentController,
                      style: TextStyle(
                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nom du référent',
                        labelStyle: TextStyle(
                          color: _themeService.isDarkMode ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _newReferentController.clear();
                            },
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
                              if (_newReferentController.text.trim().isNotEmpty) {
                                setState(() {
                                  _referents.add(_newReferentController.text.trim());
                                });
                                Navigator.of(context).pop();
                                _newReferentController.clear();
                              }
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
        );
      },
    );
  }



  void _saveData() {
    // Reset des erreurs
    setState(() {
      _referentError = false;
      _travauxError = false;
      _adresseError = false;
    });

    // Validation
    bool hasError = false;
    if (_selectedReferent == null) {
      setState(() => _referentError = true);
      hasError = true;
    }
    if (_travauxController.text.trim().isEmpty) {
      setState(() => _travauxError = true);
      hasError = true;
    }
    if (_adresseController.text.trim().isEmpty) {
      setState(() => _adresseError = true);
      hasError = true;
    }

    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Si tout est valide, montrer le dialog de confirmation
    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
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
                      // Header simple
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ECDC4).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: Color(0xFF4ECDC4),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Confirmer l\'enregistrement',
                                style: TextStyle(
                                  color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Divider(
                        height: 1,
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                      ),
                  
                  // Contenu scrollable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Input titre du projet
                          Container(
                            decoration: BoxDecoration(
                              color: _themeService.isDarkMode
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _themeService.isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1),
                                width: 1.5,
                              ),
                              boxShadow: _themeService.isDarkMode
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4ECDC4).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.pencil,
                                      color: Color(0xFF4ECDC4),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 14),
                                    child: TextField(
                                      controller: titleController,
                                      style: TextStyle(
                                        color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Titre du projet *',
                                        hintStyle: TextStyle(
                                          color: _themeService.isDarkMode ? Colors.white60 : Colors.black45,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        filled: false,
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Box résumé des informations
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _themeService.isDarkMode
                                  ? Colors.white.withOpacity(0.03)
                                  : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _themeService.isDarkMode
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(CupertinoIcons.person_fill, 'Référent', _selectedReferent!),
                                const SizedBox(height: 14),
                                _buildInfoRow(CupertinoIcons.hammer_fill, 'Travaux', _travauxController.text),
                                const SizedBox(height: 14),
                                _buildInfoRow(CupertinoIcons.location_fill, 'Adresse', _adresseController.text),
                                if (_accesController.text.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _buildInfoRow(CupertinoIcons.compass_fill, 'Accès', _accesController.text),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Boutons modernes
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                titleController.dispose();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (titleController.text.trim().isNotEmpty) {
                                // Sauvegarder la valeur avant de fermer
                                final title = titleController.text.trim();
                                
                                // Fermer le dialog
                                Navigator.of(context).pop();
                                
                                // Attendre la prochaine frame, puis disposer et naviguer
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  titleController.dispose();
                                  
                                  // Navigation vers SummaryScreen
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => SummaryScreen(
                                        title: title,
                                        referent: _selectedReferent!,
                                        travaux: _travauxController.text,
                                        adresse: _adresseController.text,
                                        acces: _accesController.text,
                                        isDarkMode: _themeService.isDarkMode,
                                      ),
                                      transitionDuration: const Duration(milliseconds: 300),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                });
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4ECDC4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Confirmer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
        );
      },
    );
  }


  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4ECDC4), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeService.isDarkMode
          ? const Color(0xFF191919)
          : const Color(0xFFFAF7F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec bouton retour
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _themeService.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    const Spacer(),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Icône Métrique avec Hero animation
                Center(
                  child: Hero(
                    tag: 'metrique_hero',
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.architecture,
                        color: Color(0xFF4ECDC4),
                        size: 45,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Formulaire moderne
                _buildModernReferentField(),
                
                // Dropdown liste des référents
                if (_isDropdownOpen) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _themeService.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _themeService.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        width: 1.5,
                      ),
                      boxShadow: _themeService.isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        ..._referents.map((referent) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedReferent = referent;
                              _isDropdownOpen = false;
                              _referentError = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4ECDC4).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.person_fill,
                                    color: Color(0xFF4ECDC4),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  referent,
                                  style: TextStyle(
                                    color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                        
                        // Bouton ajouter référent
                        GestureDetector(
                          onTap: () {
                            setState(() => _isDropdownOpen = false);
                            _addNewReferent();
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ECDC4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF4ECDC4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.add_circled_solid,
                                  color: Color(0xFF4ECDC4),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Ajouter un référent',
                                  style: TextStyle(
                                    color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 15,
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
                ],
                
                const SizedBox(height: 20),
                
                _buildModernTextField(
                  label: 'Travaux',
                  controller: _travauxController,
                  icon: CupertinoIcons.hammer,
                  isError: _travauxError,
                ),
                const SizedBox(height: 20),
                
                _buildAddressField(),
                const SizedBox(height: 20),
                
                _buildModernTextField(
                  label: 'Accès (optionnel)',
                  controller: _accesController,
                  icon: CupertinoIcons.compass,
                  isError: false,
                ),
                
                const SizedBox(height: 40),
                
                // Bouton moderne
                GestureDetector(
                  onTap: _saveData,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4ECDC4),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernReferentField() {
    return GestureDetector(
      onTap: () => setState(() => _isDropdownOpen = !_isDropdownOpen),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _themeService.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _referentError
                ? Colors.red
                : (_themeService.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1)),
            width: 1.5,
          ),
          boxShadow: _themeService.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.person,
                color: Color(0xFF4ECDC4),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _selectedReferent ?? 'Référent *',
                style: TextStyle(
                  color: _selectedReferent != null
                      ? (_themeService.isDarkMode ? Colors.white : Colors.black87)
                      : (_themeService.isDarkMode ? Colors.white60 : Colors.black45),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              _isDropdownOpen ? Icons.expand_less : Icons.expand_more,
              color: _themeService.isDarkMode ? Colors.white60 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        color: _themeService.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _adresseError
              ? Colors.red
              : (_themeService.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1)),
          width: 1.5,
        ),
        boxShadow: _themeService.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.location,
                color: Color(0xFF4ECDC4),
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: AddressField(
                controller: _adresseController,
                isDarkMode: _themeService.isDarkMode,
                hasError: _adresseError,
                onChanged: (value) {
                  if (_adresseError) {
                    setState(() => _adresseError = false);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isError,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _themeService.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Colors.red
              : (_themeService.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1)),
          width: 1.5,
        ),
        boxShadow: _themeService.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4ECDC4),
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(
                    color: _themeService.isDarkMode ? Colors.white60 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  isDense: true,
                ),
                onChanged: (value) {
                  if (isError) {
                    setState(() {
                      if (label.contains('Travaux')) _travauxError = false;
                      if (label.contains('Adresse')) _adresseError = false;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}