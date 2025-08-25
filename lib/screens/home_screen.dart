import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../widgets/address_field.dart';
import '../services/theme_service.dart';
import 'summary_screen.dart';
import 'main_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    setState(() {
      _selectedReferent = null;
      _referentController.clear();
      _travauxController.clear();
      _adresseController.clear();
      _accesController.clear();
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tous les champs ont été effacés'),
        duration: const Duration(seconds: 2),
        backgroundColor: _themeService.isDarkMode ? Colors.grey[800] : null,
      ),
    );
  }

  void _addNewReferent() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
          title: Text(
            'Ajouter un nouveau référent',
            style: TextStyle(
              color: _themeService.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _newReferentController,
            style: TextStyle(
              color: _themeService.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Nom du référent',
              labelStyle: TextStyle(
                color: _themeService.subtitleColor,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _themeService.primaryColor, 
                  width: 2
                ),
              ),
              filled: true,
              fillColor: _themeService.isDarkMode ? Colors.grey[700] : Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newReferentController.clear();
              },
              child: Text(
                'Annuler',
                style: TextStyle(color: _themeService.subtitleColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_newReferentController.text.trim().isNotEmpty) {
                  setState(() {
                    _referents.add(_newReferentController.text.trim());
                  });
                  Navigator.of(context).pop();
                  _newReferentController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeService.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReferentDropdown() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
              border: _referentError 
                ? Border.all(color: Colors.red, width: 2)
                : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _isDropdownOpen = !_isDropdownOpen;
                    _referentError = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _referentError 
                              ? [Colors.red[400]!, Colors.red[600]!]
                              : (_themeService.isDarkMode 
                                ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                                : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)]),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _selectedReferent ?? 'Référent',
                                style: TextStyle(
                                  color: _selectedReferent != null 
                                    ? _themeService.textColor
                                    : (_referentError 
                                      ? Colors.red[600]
                                      : (_themeService.isDarkMode ? Colors.white70 : const Color(0xFF666666))),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        _isDropdownOpen ? Icons.expand_less : Icons.expand_more,
                        color: _themeService.isDarkMode ? Colors.white70 : const Color(0xFF666666),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isDropdownOpen) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ..._referents.map((referent) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedReferent = referent;
                          _isDropdownOpen = false;
                          _referentError = false;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Text(
                          referent,
                          style: TextStyle(
                            color: _themeService.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _isDropdownOpen = false;
                          });
                          _addNewReferent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _themeService.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _themeService.primaryColor, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: _themeService.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ajouter un référent',
                                style: TextStyle(
                                  color: _themeService.primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isError = false,
    int maxLines = 1,
    Widget? customField,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        customField ?? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _themeService.textColor,
            ),
            onChanged: (value) {
              if (isError) {
                setState(() {
                  if (label.contains('Référent')) _referentError = false;
                  if (label.contains('Travaux')) _travauxError = false;
                  if (label.contains('Adresse')) _adresseError = false;
                });
              }
            },
            decoration: InputDecoration(
              label: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label.replaceAll(' *', ''),
                      style: TextStyle(
                        color: isError 
                          ? Colors.red[600]
                          : (_themeService.isDarkMode ? Colors.white70 : const Color(0xFF666666)),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    if (label.contains('*')) TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isError 
                      ? [Colors.red[400]!, Colors.red[600]!]
                      : (_themeService.isDarkMode 
                        ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                        : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)]),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isError ? Colors.red : Colors.transparent,
                  width: isError ? 2 : 0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isError 
                    ? Colors.red 
                    : _themeService.primaryColor, 
                  width: 2
                ),
              ),
              filled: true,
              fillColor: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
        ),
      ],
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
    bool isDisposed = false;

    void disposeController() {
      if (!isDisposed) {
        titleController.dispose();
        isDisposed = true;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            disposeController();
            return true;
          },
          child: AlertDialog(
            backgroundColor: _themeService.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _themeService.isDarkMode 
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [Colors.white, const Color(0xFFF8F9FA)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header avec gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: _themeService.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Confirmer l\'enregistrement',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: titleController,
                              style: TextStyle(
                                color: _themeService.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                label: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Titre du projet',
                                        style: TextStyle(
                                          color: _themeService.isDarkMode ? Colors.white70 : const Color(0xFF666666),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' *',
                                        style: TextStyle(
                                          color: Colors.red[600],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: _themeService.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: _themeService.primaryColor, width: 2),
                                ),
                                filled: true,
                                fillColor: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Box résumé des informations
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _themeService.isDarkMode ? Colors.grey[800]?.withOpacity(0.5) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(Icons.person, 'Référent', _selectedReferent!),
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.construction, 'Travaux', _travauxController.text),
                                const SizedBox(height: 12),
                                _buildInfoRow(Icons.location_on, 'Adresse', _adresseController.text),
                                if (_accesController.text.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(Icons.directions, 'Accès', _accesController.text),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Boutons avec style moderne
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _themeService.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                disposeController();
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                'Annuler',
                                style: TextStyle(
                                  color: _themeService.subtitleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: _themeService.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _themeService.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (titleController.text.trim().isNotEmpty) {
                                  disposeController();
                                  Navigator.of(context).pop();
                                  
                                  // Navigation vers SummaryScreen
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => SummaryScreen(
                                        title: titleController.text.trim(),
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
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text(
                                'Confirmer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
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
        );
      },
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      width: 280,
      child: Container(
        color: _themeService.backgroundColor,
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _themeService.primaryGradient,
              ),
              child: const Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSidebarItem(
                    icon: Icons.home,
                    title: 'Retour Accueil',
                    onTap: () {
                      Navigator.of(context).pop(); // Fermer la sidebar
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MainDashboard()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.clear_all,
                    title: 'Effacer tout',
                    onTap: _clearAll,
                  ),
                  _buildSidebarItem(
                    icon: _themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    title: 'Dark Mode',
                    onTap: () async {
                      await _themeService.toggleTheme();
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                'v0.1',
                style: TextStyle(
                  color: _themeService.isDarkMode ? Colors.white.withOpacity(0.4) : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _themeService.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: _themeService.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: _themeService.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _themeService.subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: _themeService.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
      key: _scaffoldKey,
      backgroundColor: _themeService.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainDashboard()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: _themeService.primaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Métrique',
              style: TextStyle(
                color: _themeService.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          SettingsButton(
            isDarkMode: _themeService.isDarkMode,
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildSidebar(),
      body: Container(
        decoration: BoxDecoration(
          color: _themeService.backgroundColor,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo responsive selon l'orientation
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                      final screenHeight = MediaQuery.of(context).size.height;
                      
                      // En mode paysage ou sur petit écran, logo plus petit
                      if (isLandscape || screenHeight < 600) {
                        return Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          fit: BoxFit.contain,
                        );
                      } else {
                        // Mode portrait normal
                        return Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          fit: BoxFit.contain,
                        );
                      }
                    },
                  ),
                ),
                    
                const SizedBox(height: 20),
                    
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 200,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Référent *',
                            controller: _referentController,
                            icon: Icons.person,
                            isError: _referentError,
                            customField: _buildReferentDropdown(),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildTextField(
                            label: 'Travaux *',
                            controller: _travauxController,
                            icon: Icons.construction,
                            isError: _travauxError,
                          ),
                          const SizedBox(height: 24),
                          
                          _buildTextField(
                            label: 'Adresse *',
                            controller: _adresseController,
                            icon: Icons.location_on,
                            isError: _adresseError,
                            customField: AddressField(
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
                          const SizedBox(height: 24),
                          
                          _buildTextField(
                            label: 'Accès',
                            controller: _accesController,
                            icon: Icons.directions,
                          ),
                          const SizedBox(height: 40),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeService.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Enregistrer',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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
}