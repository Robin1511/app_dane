import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../services/excel_export_service.dart';
import 'entry_point.dart';
import '../services/theme_service.dart';

class TableItem {
  String descriptif;
  double quantite;
  double longueur;
  double largeur;
  double hauteur;
  String unite; // 'm2', 'm3', 'U'
  double coef; // Nouveau: coefficient
  String uniqueId; // Identifiant unique pour chaque ligne
  
  TableItem({
    this.descriptif = '',
    this.quantite = 0,
    this.longueur = 0,
    this.largeur = 0,
    this.hauteur = 0,
    this.unite = 'm2',
    this.coef = 1.0, // Valeur par défaut
  }) : uniqueId = DateTime.now().millisecondsSinceEpoch.toString() + '_${(1000 * (DateTime.now().microsecond / 1000)).round()}';
  
  double get total {
    switch (unite) {
      case 'm2':
        return quantite * longueur * largeur * coef;
      case 'm3':
        return quantite * longueur * largeur * hauteur * coef;
      case 'mL':
        return quantite * longueur * coef;
      case 'rp':
        return quantite * (longueur + largeur) * hauteur * coef;
      default:
        return quantite * coef;
    }
  }
}

class SubTitle {
  String name;
  List<TableItem> items;
  
  SubTitle({required this.name, List<TableItem>? items}) 
    : items = items ?? [];
    
  double get total => items.fold(0, (sum, item) => sum + item.total);
}

class MainTitle {
  String name;
  List<SubTitle> subTitles;
  List<TableItem> directItems; // Nouveau: items directement sous le titre
  
  MainTitle({required this.name, List<SubTitle>? subTitles, List<TableItem>? directItems}) 
    : subTitles = subTitles ?? [],
      directItems = directItems ?? [];
    
  double get total {
    final subTitlesTotal = subTitles.fold(0.0, (sum, subTitle) => sum + subTitle.total);
    final directTotal = directItems.fold(0.0, (sum, item) => sum + item.total);
    return subTitlesTotal + directTotal;
  }
}



class SummaryScreen extends StatefulWidget {
  final String title;
  final String referent;
  final String travaux;
  final String adresse;
  final String acces;
  final bool isDarkMode;

  const SummaryScreen({
    super.key,
    required this.title,
    required this.referent,
    required this.travaux,
    required this.adresse,
    required this.acces,
    required this.isDarkMode,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<MainTitle> _mainTitles = [];
  Map<String, double> _adjustments = {}; // Stockage des ajustements
  bool _isDisposed = false; // Flag pour éviter les erreurs après dispose
  late ThemeService _themeService; // Restaurer le ThemeService
  bool _isDarkMode = false; // Variable locale pour le thème
  
  // Titres prédéfinis pour Cage d'escalier
  final List<String> _cageEscalierTitles = [
    'SOLS',
    'PLAFONDS',
    'MURS',
    'DÉDUCTION OUVERTURES',
    'BOISERIES BP',
    'BOISERIES VERNIS',
    'BOISERIES DECORS',
    'OUVRAGE PVC/ALU',
    'PILONE D\'ASCENSEUR',
    'PORTE ASCENSEUR',
    'FUSEAUX',
    'TAPIS',
    'ELEC',
    'PLOMBERIE',
    'MENUISERIE',
    'SERRURERIE',
  ];
  
  // Titres prédéfinis pour Ravalement
  final List<String> _ravalementTitles = [
    'SURFACE ÉCHAFAUDAGE',
    'SURFACE À TRAITÉ',
    'DÉDUCTION OUVERTURES',
    'REPORT TABLEAU',
    'JOINT DE CALFEUTREMENT',
    'BANDEAUX',
    'APPUIS',
    'CORCHINES',
    'BOISERIES',
    'GARDES CORPS',
    'PORTE D\'ENTRÉE',
    'ZINGUERIE BANDEAUX',
    'ZINGUERIE APPUIS',
    'DESCENTES',
    'BALCON PLOMB',
    'SERRURIE',
  ];
  
  // Variables pour le swipe avec identifiants contextuels
  Map<String, double> _swipeOffsets = {};
  Map<String, bool> _isSwiping = {};
  
  // Controllers persistants pour éviter les problèmes de curseur
  Map<String, TextEditingController> _descriptifControllers = {};
  Map<String, TextEditingController> _quantiteControllers = {};
  Map<String, TextEditingController> _longueurControllers = {};
  Map<String, TextEditingController> _largeurControllers = {};
  Map<String, TextEditingController> _hauteurControllers = {};
  Map<String, TextEditingController> _coefControllers = {};
  
  // Variables pour l'édition des titres et sous-titres
  Map<String, TextEditingController> _titleControllers = {};
  Map<String, TextEditingController> _subTitleControllers = {};
  Map<String, FocusNode> _titleFocusNodes = {};
  Map<String, FocusNode> _subTitleFocusNodes = {};
  Map<String, bool> _isEditingTitle = {};
  Map<String, bool> _isEditingSubTitle = {};

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _isDarkMode = widget.isDarkMode;
    
    // Écouter les changements de thème de manière sécurisée
    _themeService.addListener(_onThemeChanged);
    
    // Forcer la reconstruction immédiate pour éviter le flash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _safeSetState(() {});
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Nettoyer tous les controllers
    _descriptifControllers.values.forEach((controller) => controller.dispose());
    _quantiteControllers.values.forEach((controller) => controller.dispose());
    _longueurControllers.values.forEach((controller) => controller.dispose());
    _largeurControllers.values.forEach((controller) => controller.dispose());
    _hauteurControllers.values.forEach((controller) => controller.dispose());
    _coefControllers.values.forEach((controller) => controller.dispose());
    _titleControllers.values.forEach((controller) => controller.dispose());
    _subTitleControllers.values.forEach((controller) => controller.dispose());
    
    // Nettoyer tous les FocusNode
    _titleFocusNodes.values.forEach((focusNode) => focusNode.dispose());
    _subTitleFocusNodes.values.forEach((focusNode) => focusNode.dispose());
    
    _descriptifControllers.clear();
    _quantiteControllers.clear();
    _longueurControllers.clear();
    _largeurControllers.clear();
    _hauteurControllers.clear();
    _coefControllers.clear();
    _titleControllers.clear();
    _subTitleControllers.clear();
    _titleFocusNodes.clear();
    _subTitleFocusNodes.clear();
    
    // Nettoyer les variables de swipe et d'édition
    _swipeOffsets.clear();
    _isSwiping.clear();
    _isEditingTitle.clear();
    _isEditingSubTitle.clear();
    
    // Retirer le listener de manière sécurisée
    try {
      _themeService.removeListener(_onThemeChanged);
    } catch (e) {
      // Ignorer les erreurs si le service est déjà disposé
    }
    super.dispose();
  }

  // Méthode helper pour setState sécurisé
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // Gestionnaire de changement de thème sécurisé
  void _onThemeChanged() {
    if (!_isDisposed && mounted) {
      _safeSetState(() {
        _isDarkMode = _themeService.isDarkMode;
      });
    }
  }

  // Vérifier s'il y a des données non sauvegardées
  bool _hasUnsavedData() {
    return _mainTitles.isNotEmpty;
  }

  // Gérer le bouton de retour avec confirmation
  void _handleBackButton() {
    if (_hasUnsavedData()) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
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
                    colors: _isDarkMode
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
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Données non sauvegardées',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vous avez des données non sauvegardées. Êtes-vous sûr de vouloir quitter ?',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: _isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.white : Colors.black87,
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
                              Navigator.pop(context); // Fermer la boîte de dialogue
                              Navigator.of(context).pop(); // Quitter la page
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Quitter',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Pas de données, quitter directement
      Navigator.of(context).pop();
    }
  }

  void _addMainTitle() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  colors: _isDarkMode
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
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF4ECDC4),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Nouveau titre',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nom du titre',
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.white60 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              controller.dispose();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black87,
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
                            if (controller.text.trim().isNotEmpty) {
                              _safeSetState(() {
                                _mainTitles.add(MainTitle(name: controller.text.trim()));
                              });
                              Navigator.pop(context);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                controller.dispose();
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
                            'Ajouter',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addSubTitle(int mainIndex) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  colors: _isDarkMode
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
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.subdirectory_arrow_right,
                          color: Color(0xFF4ECDC4),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Nouveau sous-titre',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nom du sous-titre',
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.white60 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              controller.dispose();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black87,
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
                            if (controller.text.trim().isNotEmpty) {
                              _safeSetState(() {
                                _mainTitles[mainIndex].subTitles.add(
                                  SubTitle(name: controller.text.trim()),
                                );
                              });
                              Navigator.pop(context);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                controller.dispose();
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
                            'Ajouter',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPredefinedTitlesDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header avec gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDarkMode 
                        ? [const Color(0xFF4ECDC4), const Color(0xFF45B8AC)]
                        : [const Color(0xFF4ECDC4), const Color(0xFF5FA8D3)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Titres Prédéfinis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Contenu
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Sélection du type de travaux
                        Text(
                          'Choisissez le type de travaux :',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Boutons pour choisir le type
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showTitlesSelectionDialog('Cage d\'escalier', _cageEscalierTitles),
                                icon: const Icon(Icons.stairs, color: Colors.white),
                                label: const Text(
                                  'Cage d\'escalier',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4ECDC4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showTitlesSelectionDialog('Ravalement', _ravalementTitles),
                                icon: const Icon(Icons.brush, color: Colors.white),
                                label: const Text(
                                  'Ravalement',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4ECDC4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Informations
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: _isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sélectionnez un type de travaux pour voir les titres disponibles',
                                style: TextStyle(
                                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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

  void _showTitlesSelectionDialog(String workType, List<String> titles) {
    Set<String> selectedTitles = {};
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header avec gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDarkMode 
                        ? [const Color(0xFF4ECDC4), const Color(0xFF45B8AC)]
                        : [const Color(0xFF4ECDC4), const Color(0xFF5FA8D3)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        workType == 'Cage d\'escalier' ? Icons.stairs : Icons.brush,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Titres $workType',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Contenu
                Expanded(
                  child: Column(
                    children: [
                      // Instructions
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Cochez les titres que vous souhaitez ajouter :',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Liste des titres avec checkboxes
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: titles.map((title) {
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: CheckboxListTile(
                                  title: Text(
                                    title,
                                    style: TextStyle(
                                      color: _isDarkMode ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  value: selectedTitles.contains(title),
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedTitles.add(title);
                                      } else {
                                        selectedTitles.remove(title);
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFF4ECDC4),
                                  checkColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  tileColor: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      
                      // Boutons d'action
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selectedTitles.isNotEmpty
                                  ? () {
                                      _addSelectedTitles(selectedTitles.toList(), workType);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    }
                                  : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4ECDC4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: Text(
                                  'Creer',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  void _addSelectedTitles(List<String> titles, String category) {
    _safeSetState(() {
      // Créer un seul titre principal avec le nom de la catégorie
      MainTitle mainTitle = MainTitle(name: category.toUpperCase());
      
      // Ajouter tous les titres sélectionnés comme sous-titres
      for (String title in titles) {
        mainTitle.subTitles.add(SubTitle(name: title));
      }
      
      _mainTitles.add(mainTitle);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Titre principal "$category" créé avec ${titles.length} sous-titre${titles.length > 1 ? 's' : ''}'),
        backgroundColor: const Color(0xFF4ECDC4),
        duration: const Duration(seconds: 3),
      ),
    );
  }



  void _showCalculatorDialog() {
    String? selectedFromKey;
    String? selectedToKey;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header avec gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDarkMode 
                        ? [const Color(0xFF4ECDC4), const Color(0xFF45B8AC)]
                        : [const Color(0xFF4ECDC4), const Color(0xFF5FA8D3)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Calculatrice Directe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Contenu
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // SOUSTRAIRE (de quel élément)
                        _buildSelectorSection(
                          'SOUSTRAIRE :',
                          selectedFromKey,
                          Colors.red,
                          (key) {
                            setDialogState(() {
                              selectedFromKey = key;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // DE (à quel élément)  
                        _buildSelectorSection(
                          'DE :',
                          selectedToKey,
                          Colors.blue,
                          (key) {
                            setDialogState(() {
                              selectedToKey = key;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Calcul et résultat
                        if (selectedFromKey != null && selectedToKey != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'CALCUL :',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_getDisplayNameFromKey(selectedToKey!)} - ${_getDisplayNameFromKey(selectedFromKey!)}',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_getAdjustedTotal(selectedToKey!).toStringAsFixed(2)} - ${_getAdjustedTotal(selectedFromKey!).toStringAsFixed(2)} = ${(_getAdjustedTotal(selectedToKey!) - _getAdjustedTotal(selectedFromKey!)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFF4ECDC4),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 30),
                        
                        // Boutons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Annuler',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (selectedFromKey != null || selectedToKey != null)
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedFromKey = null;
                                      selectedToKey = null;
                                    });
                                  },
                                  child: Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (selectedFromKey != null && selectedToKey != null) 
                                  ? () {
                                      _applyDeduction(selectedFromKey!, selectedToKey!);
                                      Navigator.pop(context);
                                    }
                                  : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4ECDC4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: const Text(
                                  'Appliquer',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildSelectorSection(String title, String? selectedKey, Color color, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selectedKey != null 
              ? color.withOpacity(0.1) 
              : (_isDarkMode ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedKey != null 
                ? color 
                : (_isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
            ),
          ),
          child: selectedKey != null
            ? Row(
                children: [
                  Icon(
                    selectedKey.startsWith('main_') ? Icons.folder : Icons.subdirectory_arrow_right,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDisplayNameFromKey(selectedKey),
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                                         _getDisplayTotal(selectedKey),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: () => _showSelectionDialog(color, onSelect),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cliquer pour sélectionner',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }

  void _showSelectionDialog(Color color, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sélectionner un élément',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          height: 500, // Augmenté pour accommoder plus d'éléments
          child: SingleChildScrollView(
            child: Column(
              children: [
                ..._mainTitles.expand((mainTitle) {
                  List<Widget> widgets = [];
                  int mainIndex = _mainTitles.indexOf(mainTitle);
                  
                  // Ajouter le titre principal
                  String mainTitleKey = 'main_${mainTitle.name}';
                  widgets.add(
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () {
                          onSelect(mainTitleKey);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.folder, color: color, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${mainIndex + 1}. ${mainTitle.name}',
                                        style: TextStyle(
                                          color: _isDarkMode ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (_adjustments.containsKey(mainTitleKey))
                                      Icon(
                                        Icons.calculate,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                _getDisplayTotal(mainTitleKey),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                  
                  // Ajouter les lignes directes du titre principal
                  for (int itemIndex = 0; itemIndex < mainTitle.directItems.length; itemIndex++) {
                    final item = mainTitle.directItems[itemIndex];
                    String itemKey = 'main_${mainTitle.name}_item_$itemIndex';
                    
                    widgets.add(
                      Container(
                        margin: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
                        child: InkWell(
                          onTap: () {
                            onSelect(itemKey);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.table_chart, color: color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${mainIndex + 1}.L${itemIndex + 1} ${item.descriptif.isNotEmpty ? item.descriptif : 'Ligne ${itemIndex + 1}'}',
                                          style: TextStyle(
                                            color: _isDarkMode ? Colors.white : Colors.black,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (_adjustments.containsKey(itemKey))
                                        Icon(
                                          Icons.calculate,
                                          color: Colors.orange,
                                          size: 12,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _getDisplayTotal(itemKey),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // Ajouter les sous-titres
                  for (int subIndex = 0; subIndex < mainTitle.subTitles.length; subIndex++) {
                    final subTitle = mainTitle.subTitles[subIndex];
                    String subTitleKey = 'sub_${mainTitle.name}_${subTitle.name}';
                    
                    widgets.add(
                      Container(
                        margin: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
                        child: InkWell(
                          onTap: () {
                            onSelect(subTitleKey);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.subdirectory_arrow_right, color: color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${mainIndex + 1}.${subIndex + 1} ${subTitle.name}',
                                          style: TextStyle(
                                            color: _isDarkMode ? Colors.white : Colors.black,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (_adjustments.containsKey(subTitleKey))
                                        Icon(
                                          Icons.calculate,
                                          color: Colors.orange,
                                          size: 12,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _getDisplayTotal(subTitleKey),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    
                    // Ajouter les lignes du sous-titre
                    for (int itemIndex = 0; itemIndex < subTitle.items.length; itemIndex++) {
                      final item = subTitle.items[itemIndex];
                      String itemKey = 'sub_${mainTitle.name}_${subTitle.name}_item_$itemIndex';
                      
                      widgets.add(
                        Container(
                          margin: const EdgeInsets.only(left: 40, top: 2, bottom: 2),
                          child: InkWell(
                            onTap: () {
                              onSelect(itemKey);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart, color: color, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${mainIndex + 1}.${subIndex + 1}.L${itemIndex + 1} ${item.descriptif.isNotEmpty ? item.descriptif : 'Ligne ${itemIndex + 1}'}',
                                            style: TextStyle(
                                              color: _isDarkMode ? Colors.white : Colors.black,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        if (_adjustments.containsKey(itemKey))
                                          Icon(
                                            Icons.calculate,
                                            color: Colors.orange,
                                            size: 10,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _getDisplayTotal(itemKey),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                  
                  return widgets;
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDeduction(String fromKey, String toKey) {
    double fromAmount = _getTotalFromKey(fromKey);
    
    _safeSetState(() {
      // Stocker l'ajustement
      if (_adjustments.containsKey(toKey)) {
        _adjustments[toKey] = _adjustments[toKey]! - fromAmount;
      } else {
        _adjustments[toKey] = -fromAmount;
      }
    });
  }

  double _getAdjustedTotal(String key) {
    double baseTotal = _getTotalFromKey(key);
    
    // Si c'est un titre ou sous-titre, calculer les ajustements des lignes individuelles
    if (key.startsWith('main_') && !key.contains('_item_')) {
      String titleName = key.substring(5);
      final mainTitle = _mainTitles.firstWhere((mt) => mt.name == titleName, orElse: () => MainTitle(name: ''));
      if (mainTitle.name.isNotEmpty) {
        int mainIndex = _mainTitles.indexOf(mainTitle);
        return _getMainTitleAdjustedTotal(mainTitle, mainIndex);
      }
    } else if (key.startsWith('sub_') && !key.contains('_item_')) {
      String keyWithoutPrefix = key.substring(4);
      List<String> parts = keyWithoutPrefix.split('_');
      if (parts.length >= 2) {
        String mainTitleName = parts[0];
        String subTitleName = parts.sublist(1).join('_');
        
        final mainTitle = _mainTitles.firstWhere((mt) => mt.name == mainTitleName, orElse: () => MainTitle(name: ''));
        if (mainTitle.name.isNotEmpty) {
          final subTitle = mainTitle.subTitles.firstWhere((st) => st.name == subTitleName, orElse: () => SubTitle(name: ''));
          if (subTitle.name.isNotEmpty) {
            int subIndex = mainTitle.subTitles.indexOf(subTitle);
            return _getSubTitleAdjustedTotal(subTitle, mainTitle, subIndex);
          }
        }
      }
    }
    
    // Pour les lignes individuelles ou fallback
    double adjustment = _adjustments[key] ?? 0;
    return baseTotal + adjustment;
  }

  String _getDisplayTotal(String key) {
    double baseTotal = _getTotalFromKey(key);
    double adjustment = _adjustments[key] ?? 0;
    
    // Si c'est un titre ou sous-titre, calculer les ajustements des lignes individuelles
    if (key.startsWith('main_') && !key.contains('_item_')) {
      String titleName = key.substring(5);
      final mainTitle = _mainTitles.firstWhere((mt) => mt.name == titleName, orElse: () => MainTitle(name: ''));
      if (mainTitle.name.isNotEmpty) {
        int mainIndex = _mainTitles.indexOf(mainTitle);
        double adjustedTotal = _getMainTitleAdjustedTotal(mainTitle, mainIndex);
        if (adjustedTotal != baseTotal) {
          return adjustedTotal.toStringAsFixed(2);
        }
      }
    } else if (key.startsWith('sub_') && !key.contains('_item_')) {
      String keyWithoutPrefix = key.substring(4);
      List<String> parts = keyWithoutPrefix.split('_');
      if (parts.length >= 2) {
        String mainTitleName = parts[0];
        String subTitleName = parts.sublist(1).join('_');
        
        final mainTitle = _mainTitles.firstWhere((mt) => mt.name == mainTitleName, orElse: () => MainTitle(name: ''));
        if (mainTitle.name.isNotEmpty) {
          final subTitle = mainTitle.subTitles.firstWhere((st) => st.name == subTitleName, orElse: () => SubTitle(name: ''));
          if (subTitle.name.isNotEmpty) {
            int subIndex = mainTitle.subTitles.indexOf(subTitle);
            double adjustedTotal = _getSubTitleAdjustedTotal(subTitle, mainTitle, subIndex);
            if (adjustedTotal != baseTotal) {
              return adjustedTotal.toStringAsFixed(2);
            }
          }
        }
      }
    }
    
    // Affichage normal pour les lignes individuelles ou si pas d'ajustement
    if (adjustment == 0) {
      return baseTotal.toStringAsFixed(2);
    } else {
      double adjustedTotal = baseTotal + adjustment;
      return adjustedTotal.toStringAsFixed(2);
    }
  }



  double _getTotalFromKey(String key) {
    if (key.startsWith('main_')) {
      String keyWithoutPrefix = key.substring(5); // Enlever "main_"
      
      // Vérifier si c'est une ligne individuelle
      if (keyWithoutPrefix.contains('_item_')) {
        List<String> parts = keyWithoutPrefix.split('_item_');
        if (parts.length == 2) {
          String titleName = parts[0];
          int itemIndex = int.tryParse(parts[1]) ?? -1;
          
          final mainTitle = _mainTitles.firstWhere((mt) => mt.name == titleName, orElse: () => MainTitle(name: ''));
          if (mainTitle.name.isNotEmpty && itemIndex >= 0 && itemIndex < mainTitle.directItems.length) {
            return mainTitle.directItems[itemIndex].total;
          }
        }
      } else {
        // Titre principal
        final mainTitle = _mainTitles.firstWhere((mt) => mt.name == keyWithoutPrefix, orElse: () => MainTitle(name: ''));
        return mainTitle.name.isNotEmpty ? mainTitle.total : 0;
      }
    } else if (key.startsWith('sub_')) {
      String keyWithoutPrefix = key.substring(4); // Enlever "sub_"
      
      // Vérifier si c'est une ligne individuelle
      if (keyWithoutPrefix.contains('_item_')) {
        List<String> parts = keyWithoutPrefix.split('_item_');
        if (parts.length == 2) {
          String subKey = parts[0];
          int itemIndex = int.tryParse(parts[1]) ?? -1;
          
          List<String> subParts = subKey.split('_');
          if (subParts.length >= 2) {
            String mainTitleName = subParts[0];
            String subTitleName = subParts.sublist(1).join('_');
            
            final mainTitle = _mainTitles.firstWhere((mt) => mt.name == mainTitleName, orElse: () => MainTitle(name: ''));
            if (mainTitle.name.isNotEmpty) {
              final subTitle = mainTitle.subTitles.firstWhere((st) => st.name == subTitleName, orElse: () => SubTitle(name: ''));
              if (subTitle.name.isNotEmpty && itemIndex >= 0 && itemIndex < subTitle.items.length) {
                return subTitle.items[itemIndex].total;
              }
            }
          }
        }
      } else {
        // Sous-titre
        List<String> parts = keyWithoutPrefix.split('_');
        if (parts.length >= 2) {
          String mainTitleName = parts[0];
          String subTitleName = parts.sublist(1).join('_');
          
          final mainTitle = _mainTitles.firstWhere((mt) => mt.name == mainTitleName, orElse: () => MainTitle(name: ''));
          if (mainTitle.name.isNotEmpty) {
            final subTitle = mainTitle.subTitles.firstWhere((st) => st.name == subTitleName, orElse: () => SubTitle(name: ''));
            return subTitle.name.isNotEmpty ? subTitle.total : 0;
          }
        }
      }
    }
    return 0;
  }

  String _getDisplayNameFromKey(String key) {
    if (key.startsWith('main_')) {
      String keyWithoutPrefix = key.substring(5);
      
      // Vérifier si c'est une ligne individuelle
      if (keyWithoutPrefix.contains('_item_')) {
        List<String> parts = keyWithoutPrefix.split('_item_');
        if (parts.length == 2) {
          String titleName = parts[0];
          int itemIndex = int.tryParse(parts[1]) ?? -1;
          
          final mainTitle = _mainTitles.firstWhere((mt) => mt.name == titleName, orElse: () => MainTitle(name: ''));
          if (mainTitle.name.isNotEmpty && itemIndex >= 0 && itemIndex < mainTitle.directItems.length) {
            int mainIndex = _mainTitles.indexOf(mainTitle);
            final item = mainTitle.directItems[itemIndex];
            String displayName = item.descriptif.isNotEmpty ? item.descriptif : 'Ligne ${itemIndex + 1}';
            return '${mainIndex + 1}.L${itemIndex + 1} $displayName';
          }
        }
      } else {
        // Titre principal
        final mainTitle = _mainTitles.firstWhere((mt) => mt.name == keyWithoutPrefix, orElse: () => MainTitle(name: ''));
        if (mainTitle.name.isNotEmpty) {
          int index = _mainTitles.indexOf(mainTitle);
          return '${index + 1}. ${keyWithoutPrefix}';
        }
      }
    } else if (key.startsWith('sub_')) {
      String keyWithoutPrefix = key.substring(4);
      
      // Vérifier si c'est une ligne individuelle
      if (keyWithoutPrefix.contains('_item_')) {
        List<String> parts = keyWithoutPrefix.split('_item_');
        if (parts.length == 2) {
          String subKey = parts[0];
          int itemIndex = int.tryParse(parts[1]) ?? -1;
          
          List<String> subParts = subKey.split('_');
          if (subParts.length >= 2) {
            String mainTitleName = subParts[0];
            String subTitleName = subParts.sublist(1).join('_');
            
            final mainTitle = _mainTitles.firstWhere((mt) => mt.name == mainTitleName, orElse: () => MainTitle(name: ''));
            if (mainTitle.name.isNotEmpty) {
              final subTitle = mainTitle.subTitles.firstWhere((st) => st.name == subTitleName, orElse: () => SubTitle(name: ''));
              if (subTitle.name.isNotEmpty && itemIndex >= 0 && itemIndex < subTitle.items.length) {
                int mainIndex = _mainTitles.indexOf(mainTitle);
                int subIndex = mainTitle.subTitles.indexOf(subTitle);
                final item = subTitle.items[itemIndex];
                String displayName = item.descriptif.isNotEmpty ? item.descriptif : 'Ligne ${itemIndex + 1}';
                return '${mainIndex + 1}.${subIndex + 1}.L${itemIndex + 1} $displayName';
              }
            }
          }
        }
      } else {
        // Sous-titre
        List<String> parts = keyWithoutPrefix.split('_');
        if (parts.length >= 2) {
          String mainTitleName = parts[0];
          String subTitleName = parts.sublist(1).join('_');
          
          final mainTitle = _mainTitles.firstWhere((mt) => mt.name == mainTitleName, orElse: () => MainTitle(name: ''));
          if (mainTitle.name.isNotEmpty) {
            final subTitle = mainTitle.subTitles.firstWhere((st) => st.name == subTitleName, orElse: () => SubTitle(name: ''));
            if (subTitle.name.isNotEmpty) {
              int mainIndex = _mainTitles.indexOf(mainTitle);
              int subIndex = mainTitle.subTitles.indexOf(subTitle);
              return '${mainIndex + 1}.${subIndex + 1} $subTitleName';
            }
          }
        }
      }
    }
    return key; // Fallback
  }

  void _showUniteDialog(TableItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Choisir l\'unité',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['m2', 'm3', 'mL', 'rp', 'U'].map((unit) {
            return InkWell(
              onTap: () {
                if (!_isDisposed && mounted) {
                  _safeSetState(() {
                    item.unite = unit;
                    if (unit != 'm3' && unit != 'rp') item.hauteur = 0;
                    if (unit == 'U') {
                      item.longueur = 0;
                      item.largeur = 0;
                    }
                    if (unit == 'mL') {
                      item.largeur = 0;
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: item.unite == unit
                    ? const Color(0xFF4ECDC4).withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.unite == unit
                      ? const Color(0xFF4ECDC4)
                      : Colors.transparent,
                  ),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: item.unite == unit
                      ? const Color(0xFF4ECDC4)
                      : (_isDarkMode ? Colors.white : Colors.black),
                    fontWeight: item.unite == unit ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Couleur de fond par défaut pour éviter le flash
    final backgroundColor = _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0);
    
    return Container(
      color: backgroundColor,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: backgroundColor,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
            elevation: 0,
            leading: GestureDetector(
              onTap: _handleBackButton,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                  size: 18,
                ),
              ),
            ),
            title: Text(
              widget.title.toUpperCase(),
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showCalculatorDialog,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ECDC4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calculate,
                          color: Color(0xFF4ECDC4),
                          size: 22,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.menu,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          endDrawer: _buildSidebar(),
          body: GestureDetector(
            onTap: () {
              // Fermer le clavier quand on tape en dehors des champs
              FocusScope.of(context).unfocus();
            },
            child: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // Bouton d'ajout de titre principal
                  Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
                  child: Row(
                    children: [
                      // Bouton principal "Ajouter un titre"
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: _addMainTitle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ECDC4),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ECDC4).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Ajouter un titre',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Bouton pour les titres prédéfinis
                      GestureDetector(
                        onTap: _showPredefinedTitlesDialog,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF4ECDC4).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.list_alt,
                            color: Color(0xFF4ECDC4),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Liste des titres et tableaux
                Expanded(
                  child: _mainTitles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart,
                              size: 80,
                              color: _isDarkMode ? Colors.white30 : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun tableau créé',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cliquez sur "Ajouter un titre" pour commencer',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.white54 : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            // Affichage des titres principaux
                            ...List.generate(_mainTitles.length, (mainIndex) {
                              final mainTitle = _mainTitles[mainIndex];
                              return _buildMainTitleWidget(mainTitle, mainIndex);
                            }),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ),
            ),
        ),
      ),
    );
  }

  Widget _buildMainTitleWidget(MainTitle mainTitle, int mainIndex) {
    String mainTitleKey = 'main_${mainTitle.name}';
    double adjustedTotal = _getAdjustedTotal(mainTitleKey);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal avec boutons d'ajout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode 
                  ? [const Color(0xFF4ECDC4), const Color(0xFF45B8AC)]
                  : [const Color(0xFF4ECDC4), const Color(0xFF5FA8D3)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                                              child: _isEditingTitle['main_$mainIndex'] == true
                                                ? TextField(
                            controller: _titleControllers['main_$mainIndex'] ?? (() {
                              _titleControllers['main_$mainIndex'] = TextEditingController(text: mainTitle.name);
                              return _titleControllers['main_$mainIndex']!;
                            })(),
                            focusNode: _titleFocusNodes['main_$mainIndex'] ?? (() {
                              _titleFocusNodes['main_$mainIndex'] = FocusNode();
                              _titleFocusNodes['main_$mainIndex']!.addListener(() {
                                if (!_titleFocusNodes['main_$mainIndex']!.hasFocus) {
                                  // Sauvegarder quand le focus est perdu
                                  _safeSetState(() {
                                    mainTitle.name = _titleControllers['main_$mainIndex']!.text;
                                    _isEditingTitle['main_$mainIndex'] = false;
                                  });
                                }
                              });
                              return _titleFocusNodes['main_$mainIndex']!;
                            })(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                              onSubmitted: (value) {
                                _safeSetState(() {
                                  mainTitle.name = value;
                                  _isEditingTitle['main_$mainIndex'] = false;
                                });
                              },
                              onEditingComplete: () {
                                _safeSetState(() {
                                  mainTitle.name = _titleControllers['main_$mainIndex']!.text;
                                  _isEditingTitle['main_$mainIndex'] = false;
                                });
                              },
                            )
                          : Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${mainIndex + 1}. ${mainTitle.name.toUpperCase()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    _safeSetState(() {
                                      _isEditingTitle['main_$mainIndex'] = true;
                                      if (!_titleControllers.containsKey('main_$mainIndex')) {
                                        _titleControllers['main_$mainIndex'] = TextEditingController(text: mainTitle.name);
                                      }
                                    });
                                  },
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getDisplayTotal(mainTitleKey),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_adjustments.containsKey(mainTitleKey))
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    _safeSetState(() {
                                      _adjustments.remove(mainTitleKey);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
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
                // Bouton d'ajout direct au tableau
                IconButton(
                  onPressed: () {
                    _safeSetState(() {
                      mainTitle.directItems.add(TableItem());
                    });
                  },
                  icon: const Icon(Icons.add_box, color: Colors.white),
                  tooltip: 'Ajouter au tableau',
                ),
                // Bouton d'ajout de sous-titre
                IconButton(
                  onPressed: () => _addSubTitle(mainIndex),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Ajouter un sous-titre',
                ),
                // Bouton de suppression du titre
                IconButton(
                  onPressed: () => _deleteMainTitle(mainIndex),
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  tooltip: 'Supprimer le titre',
                ),
              ],
            ),
          ),
          
          // Tableau direct du titre principal (si il y en a)
          if (mainTitle.directItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTable(mainTitle.directItems),
                  // Bouton ajouter ligne + Total
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _safeSetState(() {
                                  mainTitle.directItems.add(TableItem());
                                });
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF4ECDC4),
                                size: 16,
                              ),
                              label: const Text(
                                'Ajouter ligne',
                                style: TextStyle(
                                  color: Color(0xFF4ECDC4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (mainTitle.directItems.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text(
                                        'Vider le tableau',
                                        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                                      ),
                                      content: Text(
                                        'Voulez-vous vraiment supprimer toutes les lignes de ce tableau ?',
                                        style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(
                                            'Annuler',
                                            style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _safeSetState(() {
                                              mainTitle.directItems.clear();
                                            });
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[600],
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Vider', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.clear_all,
                                  color: Colors.red[400],
                                  size: 16,
                                ),
                                label: Text(
                                  'Vider tableau',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Total: ',
                              style: TextStyle(
                                color: _isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${mainTitle.directItems.fold(0.0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF4ECDC4),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Sous-titres et tableaux
          ...List.generate(mainTitle.subTitles.length, (subIndex) {
            final subTitle = mainTitle.subTitles[subIndex];
            return _buildSubTitleWidget(mainTitle, subTitle, mainIndex, subIndex);
          }),
        ],
      ),
    );
  }

  Widget _buildSubTitleWidget(MainTitle mainTitle, SubTitle subTitle, int mainIndex, int subIndex) {
    return Column(
      children: [
        // En-tête du sous-titre (séparé)
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4ECDC4),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _isEditingSubTitle['sub_${mainIndex}_${subIndex}'] == true
                        ? TextField(
                            controller: _subTitleControllers['sub_${mainIndex}_${subIndex}'] ?? (() {
                              _subTitleControllers['sub_${mainIndex}_${subIndex}'] = TextEditingController(text: subTitle.name);
                              return _subTitleControllers['sub_${mainIndex}_${subIndex}']!;
                            })(),
                            focusNode: _subTitleFocusNodes['sub_${mainIndex}_${subIndex}'] ?? (() {
                              _subTitleFocusNodes['sub_${mainIndex}_${subIndex}'] = FocusNode();
                              _subTitleFocusNodes['sub_${mainIndex}_${subIndex}']!.addListener(() {
                                if (!_subTitleFocusNodes['sub_${mainIndex}_${subIndex}']!.hasFocus) {
                                  // Sauvegarder quand le focus est perdu
                                  _safeSetState(() {
                                    subTitle.name = _subTitleControllers['sub_${mainIndex}_${subIndex}']!.text;
                                    _isEditingSubTitle['sub_${mainIndex}_${subIndex}'] = false;
                                  });
                                }
                              });
                              return _subTitleFocusNodes['sub_${mainIndex}_${subIndex}']!;
                            })(),
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            onSubmitted: (value) {
                              _safeSetState(() {
                                subTitle.name = value;
                                _isEditingSubTitle['sub_${mainIndex}_${subIndex}'] = false;
                              });
                            },
                            onEditingComplete: () {
                              _safeSetState(() {
                                subTitle.name = _subTitleControllers['sub_${mainIndex}_${subIndex}']!.text;
                                _isEditingSubTitle['sub_${mainIndex}_${subIndex}'] = false;
                              });
                            },
                          )
                        : Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${mainIndex + 1}.${subIndex + 1} ${subTitle.name}',
                                  style: TextStyle(
                                    color: _isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  _safeSetState(() {
                                    _isEditingSubTitle['sub_${mainIndex}_${subIndex}'] = true;
                                    if (!_subTitleControllers.containsKey('sub_${mainIndex}_${subIndex}')) {
                                      _subTitleControllers['sub_${mainIndex}_${subIndex}'] = TextEditingController(text: subTitle.name);
                                    }
                                  });
                                },
                                child: Icon(
                                  Icons.edit,
                                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF4ECDC4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getDisplayTotal('sub_${mainTitle.name}_${subTitle.name}'),
                            style: const TextStyle(
                              color: Color(0xFF4ECDC4),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_adjustments.containsKey('sub_${mainTitle.name}_${subTitle.name}'))
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () {
                                  _safeSetState(() {
                                    _adjustments.remove('sub_${mainTitle.name}_${subTitle.name}');
                                  });
                                },
                                                                 child: Container(
                                   padding: const EdgeInsets.all(1),
                                   decoration: BoxDecoration(
                                     color: Colors.red.withOpacity(0.8),
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: const Icon(
                                     Icons.close,
                                     color: Colors.white,
                                     size: 10,
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
              // Bouton de suppression du sous-titre
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        'Supprimer le sous-titre',
                        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      ),
                      content: Text(
                        'Voulez-vous vraiment supprimer "${subTitle.name}" et son tableau ?',
                        style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Annuler',
                            style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _safeSetState(() {
                              // Nettoyer les ajustements avant de supprimer
                              _cleanupAdjustmentsForSubTitle(mainTitle, subTitle);
                              mainTitle.subTitles.removeAt(subIndex);
                              
                              // Nettoyer tous les controllers pour éviter la persistance
                              _cleanupAllControllers();
                              
                              // Forcer la reconstruction complète
                              _forceRebuild();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                  Icons.delete_outline, 
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
                tooltip: 'Supprimer le sous-titre',
              ),
            ],
          ),
        ),
        
        // Tableau (séparé)
        Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTable(subTitle.items),
              
              // Bouton ajouter ligne + Total du sous-titre
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _safeSetState(() {
                              subTitle.items.add(TableItem());
                            });
                          },
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFF4ECDC4),
                            size: 16,
                          ),
                          label: const Text(
                            'Ajouter ligne',
                            style: TextStyle(
                              color: Color(0xFF4ECDC4),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (subTitle.items.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text(
                                    'Vider le tableau',
                                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                                  ),
                                  content: Text(
                                    'Voulez-vous vraiment supprimer toutes les lignes de ce tableau ?',
                                    style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Annuler',
                                        style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _safeSetState(() {
                                          subTitle.items.clear();
                                          subTitle.items.add(TableItem()); // Garder au moins une ligne vide
                                        });
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Vider', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.clear_all,
                              color: Colors.red[400],
                              size: 16,
                            ),
                            label: Text(
                              'Vider tableau',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Total: ',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_getAdjustedTotal('sub_${mainTitle.name}_${subTitle.name}').toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF4ECDC4),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<TableItem> items) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En-tête du tableau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                // Instruction discrète pour le swipe
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.swipe_left,
                        size: 14,
                        color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe pour supprimer',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white60 : Colors.grey[500],
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // En-têtes des colonnes
                Row(
                  children: [
                    // Descriptif - Expanded avec contrainte stricte
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Descriptif',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Quantité - Expanded avec contrainte stricte
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qté',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Unité - Expanded avec contrainte stricte
                    Expanded(
                      flex: 1,
                      child: Text(
                        'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Longueur - Expanded avec contrainte stricte (toujours présent)
                    Expanded(
                      flex: 1,
                      child: Text(
                        'L',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Largeur - Expanded avec contrainte stricte (toujours présent)
                    Expanded(
                      flex: 1,
                      child: Text(
                        'l',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Hauteur - Expanded avec contrainte stricte (toujours présent)
                    Expanded(
                      flex: 1,
                      child: Text(
                        'H',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Coef - Expanded avec contrainte stricte
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Coef',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Total - Expanded avec contrainte stricte
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Espace minimal pour le swipe
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
          
          // Lignes du tableau
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            TableItem item = entry.value;
            return _buildSwipeableRow(item, index);
          }).toList(),
        ],
      ),
    );
  }

  // Fonction pour générer un identifiant contextuel unique
  String _getContextId(TableItem item, int index) {
    // Utiliser directement l'identifiant unique de l'item pour éviter les conflits
    return item.uniqueId;
  }


  // Fonction pour obtenir la clé d'ajustement d'une ligne individuelle
  String _getItemAdjustmentKey(TableItem item) {
    // Chercher dans quel titre principal et sous-titre se trouve cet item
    for (int mainIndex = 0; mainIndex < _mainTitles.length; mainIndex++) {
      MainTitle mainTitle = _mainTitles[mainIndex];
      
      // Chercher dans les items directs
      int itemIndex = mainTitle.directItems.indexOf(item);
      if (itemIndex != -1) {
        return 'main_${mainTitle.name}_item_$itemIndex';
      }
      
      // Chercher dans les sous-titres
      for (int subIndex = 0; subIndex < mainTitle.subTitles.length; subIndex++) {
        SubTitle subTitle = mainTitle.subTitles[subIndex];
        itemIndex = subTitle.items.indexOf(item);
        if (itemIndex != -1) {
          return 'sub_${mainTitle.name}_${subTitle.name}_item_$itemIndex';
        }
      }
    }
    
    return ''; // Pas trouvé
  }

  // Fonction pour obtenir le total ajusté d'une ligne individuelle
  double _getItemAdjustedTotal(TableItem item) {
    String key = _getItemAdjustmentKey(item);
    if (key.isNotEmpty) {
      double baseTotal = item.total;
      double adjustment = _adjustments[key] ?? 0;
      return baseTotal + adjustment;
    }
    return item.total;
  }

  // Fonction pour obtenir l'affichage du total d'une ligne individuelle
  String _getItemDisplayTotal(TableItem item) {
    String key = _getItemAdjustmentKey(item);
    if (key.isNotEmpty && _adjustments.containsKey(key)) {
      double baseTotal = item.total;
      double adjustment = _adjustments[key]!;
      double adjustedTotal = baseTotal + adjustment;
      return adjustedTotal.toStringAsFixed(2);
    }
    return item.total.toStringAsFixed(2);
  }

  // Fonction pour calculer le total ajusté d'un sous-titre
  double _getSubTitleAdjustedTotal(SubTitle subTitle, MainTitle mainTitle, int subIndex) {
    double baseTotal = subTitle.total;
    double itemAdjustments = 0.0;
    
    // Ajouter les ajustements des lignes individuelles
    for (int itemIndex = 0; itemIndex < subTitle.items.length; itemIndex++) {
      String itemKey = 'sub_${mainTitle.name}_${subTitle.name}_item_$itemIndex';
      itemAdjustments += _adjustments[itemKey] ?? 0.0;
    }
    
    // Ajouter l'ajustement du sous-titre lui-même
    String subTitleKey = 'sub_${mainTitle.name}_${subTitle.name}';
    double subTitleAdjustment = _adjustments[subTitleKey] ?? 0.0;
    
    return baseTotal + itemAdjustments + subTitleAdjustment;
  }

  // Fonction pour calculer le total ajusté d'un titre principal
  double _getMainTitleAdjustedTotal(MainTitle mainTitle, int mainIndex) {
    double baseTotal = mainTitle.total;
    double itemAdjustments = 0.0;
    
    // Ajouter les ajustements des lignes directes
    for (int itemIndex = 0; itemIndex < mainTitle.directItems.length; itemIndex++) {
      String itemKey = 'main_${mainTitle.name}_item_$itemIndex';
      itemAdjustments += _adjustments[itemKey] ?? 0.0;
    }
    
    // Ajouter les ajustements des sous-titres et leurs lignes
    for (int subIndex = 0; subIndex < mainTitle.subTitles.length; subIndex++) {
      SubTitle subTitle = mainTitle.subTitles[subIndex];
      itemAdjustments += _getSubTitleAdjustedTotal(subTitle, mainTitle, subIndex) - subTitle.total;
    }
    
    // Ajouter l'ajustement du titre principal lui-même
    String mainTitleKey = 'main_${mainTitle.name}';
    double mainTitleAdjustment = _adjustments[mainTitleKey] ?? 0.0;
    
    return baseTotal + itemAdjustments + mainTitleAdjustment;
  }

  Widget _buildTableRow(TableItem item, int index, List<TableItem> items) {
    // Utiliser l'identifiant unique de l'item pour éviter les conflits
    String contextId = item.uniqueId;
    
    // Créer ou récupérer les controllers persistants avec l'identifiant unique
    if (!_descriptifControllers.containsKey(contextId)) {
      _descriptifControllers[contextId] = TextEditingController(text: item.descriptif);
        _quantiteControllers[contextId] = TextEditingController(text: item.quantite == 0 ? '' : item.quantite.toString());
      _longueurControllers[contextId] = TextEditingController(text: item.longueur == 0 ? '' : item.longueur.toString());
      _largeurControllers[contextId] = TextEditingController(text: item.largeur == 0 ? '' : item.largeur.toString());
      _hauteurControllers[contextId] = TextEditingController(text: item.hauteur == 0 ? '' : item.hauteur.toString());
      _coefControllers[contextId] = TextEditingController(text: item.coef == 1.0 ? '' : item.coef.toString());
    }
    
    // Mettre à jour les valeurs des controllers si elles ont changé
    if (_descriptifControllers[contextId]!.text != item.descriptif) {
      _descriptifControllers[contextId]!.text = item.descriptif;
    }
    // Ne pas mettre à jour les controllers automatiquement pour éviter le formatage pendant la saisie
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : const Color(0xFFE9ECEF),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Descriptif - Flexible avec contrainte
          Flexible(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.only(right: 2),
              child: TextField(
                controller: _descriptifControllers[_getContextId(item, index)],
                onChanged: (value) {
                  if (!_isDisposed && mounted) {
                    _safeSetState(() {
                      item.descriptif = value;
                    });
                  }
                },
                maxLines: null,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Description...',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  fillColor: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
                  filled: true,
                ),
              ),
            ),
          ),
          
          // Quantité - Flexible avec contrainte
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: TextField(
                controller: _quantiteControllers[_getContextId(item, index)],
                onChanged: (value) {
                  if (!_isDisposed && mounted) {
                    _safeSetState(() {
                      if (value.isEmpty) {
                        item.quantite = 0;
                      } else {
                        double? parsed = double.tryParse(value.replaceAll(',', '.'));
                        if (parsed != null) {
                          item.quantite = parsed;
                        }
                      }
                    });
                  }
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  fillColor: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
                  filled: true,
                ),
              ),
            ),
          ),
          
          // Unité - Flexible avec contrainte
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: GestureDetector(
                onTap: () => _showUniteDialog(item),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          item.unite,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 1),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Longueur - Flexible avec contrainte
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: item.unite != 'U' 
                ? TextField(
                    controller: _longueurControllers[_getContextId(item, index)],
                    onChanged: (value) {
                      if (!_isDisposed && mounted) {
                        _safeSetState(() {
                          if (value.isEmpty) {
                            item.longueur = 0;
                          } else {
                            double? parsed = double.tryParse(value.replaceAll(',', '.'));
                            if (parsed != null) {
                              item.longueur = parsed;
                            }
                          }
                        });
                      }
                    },
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      isDense: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      fillColor: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
                      filled: true,
                    ),
                  )
                : Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '-',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ),
            ),
          ),
          
          // Largeur - Flexible avec contrainte
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: (item.unite != 'U' && item.unite != 'mL') || item.unite == 'rp'
                ? TextField(
                    controller: _largeurControllers[_getContextId(item, index)],
                    onChanged: (value) {
                      if (!_isDisposed && mounted) {
                        _safeSetState(() {
                          if (value.isEmpty) {
                            item.largeur = 0;
                          } else {
                            double? parsed = double.tryParse(value.replaceAll(',', '.'));
                            if (parsed != null) {
                              item.largeur = parsed;
                            }
                          }
                        });
                      }
                    },
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      isDense: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      fillColor: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
                      filled: true,
                    ),
                  )
                : Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '-',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ),
            ),
          ),
          
          // Hauteur - Flexible avec contrainte
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: item.unite == 'm3' || item.unite == 'rp' 
                ? TextField(
                    controller: _hauteurControllers[_getContextId(item, index)],
                    onChanged: (value) {
                      if (!_isDisposed && mounted) {
                        _safeSetState(() {
                          if (value.isEmpty) {
                            item.hauteur = 0;
                          } else {
                            double? parsed = double.tryParse(value.replaceAll(',', '.'));
                            if (parsed != null) {
                              item.hauteur = parsed;
                            }
                          }
                        });
                      }
                    },
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      isDense: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      fillColor: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
                      filled: true,
                    ),
                  )
                : Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '-',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ),
            ),
          ),
          // Coef - Flexible avec contrainte
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: TextField(
                controller: _coefControllers[_getContextId(item, index)],
                onChanged: (value) {
                  if (!_isDisposed && mounted) {
                    _safeSetState(() {
                      if (value.isEmpty) {
                        item.coef = 1.0;
                      } else {
                        double? parsed = double.tryParse(value.replaceAll(',', '.'));
                        if (parsed != null) {
                          item.coef = parsed;
                        }
                      }
                    });
                  }
                },
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: item.coef == 1.0 ? "1" : item.coef.toString(),
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  fillColor: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
                  filled: true,
                ),
              ),
            ),
          ),
          // Total - Flexible avec contrainte
          Flexible(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.only(left: 1),
              height: 40,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      _getItemDisplayTotal(item),
                      style: TextStyle(
                        color: _getItemAdjustmentKey(item).isNotEmpty && _adjustments.containsKey(_getItemAdjustmentKey(item))
                          ? Colors.orange
                          : const Color(0xFF4ECDC4),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_getItemAdjustmentKey(item).isNotEmpty && _adjustments.containsKey(_getItemAdjustmentKey(item)))
                    GestureDetector(
                      onTap: () {
                        _safeSetState(() {
                          _adjustments.remove(_getItemAdjustmentKey(item));
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 2),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Espace minimal pour le swipe
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _deleteMainTitle(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer le titre',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${_mainTitles[index].name}" et tous ses tableaux ?',
          style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _safeSetState(() {
                // Nettoyer les ajustements avant de supprimer
                _cleanupAdjustmentsForMainTitle(_mainTitles[index]);
                _mainTitles.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Fonction pour nettoyer les ajustements d'un titre principal
  void _cleanupAdjustmentsForMainTitle(MainTitle mainTitle) {
    // Nettoyer les ajustements des lignes directes
    for (int itemIndex = 0; itemIndex < mainTitle.directItems.length; itemIndex++) {
      String itemKey = 'main_${mainTitle.name}_item_$itemIndex';
      if (_adjustments.containsKey(itemKey)) {
        _adjustments.remove(itemKey);
      }
    }
    
    // Nettoyer les ajustements des sous-titres et leurs lignes
    for (int subIndex = 0; subIndex < mainTitle.subTitles.length; subIndex++) {
      SubTitle subTitle = mainTitle.subTitles[subIndex];
      String subTitleKey = 'sub_${mainTitle.name}_${subTitle.name}';
      if (_adjustments.containsKey(subTitleKey)) {
        _adjustments.remove(subTitleKey);
      }
      
      // Nettoyer les ajustements des lignes du sous-titre
      for (int itemIndex = 0; itemIndex < subTitle.items.length; itemIndex++) {
        String itemKey = 'sub_${mainTitle.name}_${subTitle.name}_item_$itemIndex';
        if (_adjustments.containsKey(itemKey)) {
          _adjustments.remove(itemKey);
        }
      }
    }
    
    // Nettoyer l'ajustement du titre principal lui-même
    String mainTitleKey = 'main_${mainTitle.name}';
    if (_adjustments.containsKey(mainTitleKey)) {
      _adjustments.remove(mainTitleKey);
    }
  }

  // Fonction pour nettoyer les ajustements d'un sous-titre
  void _cleanupAdjustmentsForSubTitle(MainTitle mainTitle, SubTitle subTitle) {
    String subTitleKey = 'sub_${mainTitle.name}_${subTitle.name}';
    if (_adjustments.containsKey(subTitleKey)) {
      _adjustments.remove(subTitleKey);
    }
    
    // Nettoyer les ajustements des lignes du sous-titre
    for (int itemIndex = 0; itemIndex < subTitle.items.length; itemIndex++) {
      String itemKey = 'sub_${mainTitle.name}_${subTitle.name}_item_$itemIndex';
      if (_adjustments.containsKey(itemKey)) {
        _adjustments.remove(itemKey);
      }
      
      // Nettoyer aussi les controllers de cette ligne
      String contextId = 'main_${_mainTitles.indexOf(mainTitle)}_sub_${mainTitle.subTitles.indexOf(subTitle)}_$itemIndex';
      _descriptifControllers.remove(contextId);
      _quantiteControllers.remove(contextId);
      _longueurControllers.remove(contextId);
      _largeurControllers.remove(contextId);
      _hauteurControllers.remove(contextId);
      _coefControllers.remove(contextId);
    }
  }

  // Fonction pour nettoyer tous les ajustements (debug)
  void _cleanupAllAdjustments() {
    _adjustments.clear();
  }

  // Fonction pour nettoyer complètement tous les controllers
  void _cleanupAllControllers() {
    _descriptifControllers.clear();
    _quantiteControllers.clear();
    _longueurControllers.clear();
    _largeurControllers.clear();
    _hauteurControllers.clear();
    _coefControllers.clear();
  }

  // Fonction pour forcer la reconstruction complète
  void _forceRebuild() {
    if (mounted) {
      setState(() {});
    }
  }


  Widget _buildSidebar() {
    return Drawer(
      width: 280,
      child: Container(
        color: _isDarkMode ? const Color(0xFF191919) : const Color(0xFFFAF7F0),
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode 
                    ? [const Color(0xFF4ECDC4), const Color(0xFF45B8AC)]
                    : [const Color(0xFF4ECDC4), const Color(0xFF5FA8D3)],
                ),
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
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildSidebarItem(
                    icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    title: 'Dark Mode',
                    onTap: () async {
                      await _themeService.toggleTheme();
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.table_chart,
                    title: 'Exporter Excel',
                    onTap: () async {
                      Navigator.of(context).pop();
                      
                      // Afficher un indicateur de chargement
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('Export Excel en cours...'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF4ECDC4),
                          duration: const Duration(seconds: 3),
                        ),
                      );

                      try {
                        String? filePath = await ExcelExportService.exportToExcel(
                          projectTitle: widget.title,
                          referent: widget.referent,
                          travaux: widget.travaux,
                          adresse: widget.adresse,
                          acces: widget.acces,
                          mainTitles: _mainTitles,
                          adjustments: _adjustments,
                        );

                        if (filePath != null && !filePath.startsWith('Erreur:')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fichier Excel exporté !\n$filePath'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'OK',
                                textColor: Colors.white,
                                onPressed: () {},
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(filePath ?? 'Erreur lors de l\'export Excel'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.restore,
                    title: 'Réinitialiser Calculs',
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text(
                            'Réinitialiser les calculs',
                            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                          ),
                          content: Text(
                            'Voulez-vous remettre tous les totaux à leur valeur originale ?',
                            style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Annuler',
                                style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _safeSetState(() {
                                  _adjustments.clear();
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4ECDC4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Réinitialiser', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
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
                  color: _isDarkMode ? Colors.white.withOpacity(0.4) : Colors.grey[400],
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
                    gradient: LinearGradient(
                      colors: _isDarkMode 
                        ? [const Color(0xFF4ECDC4), const Color(0xFF45B8AC)]
                        : [const Color(0xFF4ECDC4), const Color(0xFF5FA8D3)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
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

    Widget _buildSwipeableRow(TableItem item, int index) {
    // Utiliser l'identifiant contextuel pour le swipe
    String contextId = _getContextId(item, index);
    double swipeOffset = _swipeOffsets[contextId] ?? 0.0;
    bool isSwiping = _isSwiping[contextId] ?? false;
    
    return GestureDetector(
      onPanStart: (details) {
        _safeSetState(() {
          _isSwiping[contextId] = true;
        });
      },
      onPanUpdate: (details) {
        _safeSetState(() {
          _swipeOffsets[contextId] = (swipeOffset + details.delta.dx).clamp(-200.0, 0.0);
        });
      },
      onPanEnd: (details) {
        _safeSetState(() {
          _isSwiping[contextId] = false;
          
          // Déterminer l'action basée sur la distance de swipe
          if (swipeOffset < -80) {
            // Swipe complet - Supprimer
            _showDeleteDialog(item, index);
          } else if (swipeOffset < -20) {
            // Swipe partiel - Dupliquer
            _duplicateRow(item, index);
          }
          
          // Réinitialiser le swipe
          _swipeOffsets[contextId] = 0.0;
        });
      },
      child: Container(
        height: 80, // Hauteur fixe pour la ligne
        child: Stack(
          children: [
            // Actions en arrière-plan (seulement visibles lors du swipe)
            if (swipeOffset < 0)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Action Dupliquer (orange) - visible si swipe > 20px
                    if (swipeOffset < -20)
                      Container(
                        width: 80,
                        height: double.infinity,
                        color: Colors.orange[400],
                        child: const Icon(
                          Icons.copy,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    // Action Supprimer (rouge) - visible si swipe > 80px
                    if (swipeOffset < -80)
                      Container(
                        width: 80,
                        height: double.infinity,
                        color: Colors.red[400],
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            // Contenu principal
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(swipeOffset, 0, 0),
                child: _buildTableRow(item, index, _getCurrentItems()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _duplicateRow(TableItem item, int index) {
    // Trouver la bonne liste d'items et l'index exact
    List<TableItem>? targetList;
    int targetIndex = -1;
    MainTitle? foundMainTitle;
    SubTitle? foundSubTitle;
    
    // Chercher dans les items directs des titres principaux
    for (int mainIndex = 0; mainIndex < _mainTitles.length; mainIndex++) {
      MainTitle mainTitle = _mainTitles[mainIndex];
      int itemIndex = mainTitle.directItems.indexOf(item);
      if (itemIndex != -1) {
        targetList = mainTitle.directItems;
        targetIndex = itemIndex;
        foundMainTitle = mainTitle;
        break;
      }
    }
    
    // Si pas trouvé, chercher dans les sous-titres
    if (targetList == null) {
      for (int mainIndex = 0; mainIndex < _mainTitles.length; mainIndex++) {
        MainTitle mainTitle = _mainTitles[mainIndex];
        for (int subIndex = 0; subIndex < mainTitle.subTitles.length; subIndex++) {
          SubTitle subTitle = mainTitle.subTitles[subIndex];
          int itemIndex = subTitle.items.indexOf(item);
          if (itemIndex != -1) {
            targetList = subTitle.items;
             targetIndex = itemIndex;
            foundMainTitle = mainTitle;
            foundSubTitle = subTitle;
            break;
          }
        }
        if (targetList != null) break;
      }
    }
    
    if (targetList != null && targetIndex != -1) {
      _safeSetState(() {
        // Créer une nouvelle ligne avec des données fraîches
        TableItem newItem = TableItem(
          descriptif: item.descriptif.isNotEmpty ? '${item.descriptif}' : '',
          quantite: item.quantite,
          longueur: item.longueur,
          largeur: item.largeur,
          hauteur: item.hauteur,
          unite: item.unite,
          coef: item.coef,
        );
        
        // Insérer la nouvelle ligne juste après la ligne actuelle
        targetList!.insert(targetIndex + 1, newItem);
        
        // Créer les controllers pour la nouvelle ligne avec son ID unique
        _descriptifControllers[newItem.uniqueId] = TextEditingController(text: newItem.descriptif);
        _quantiteControllers[newItem.uniqueId] = TextEditingController(text: newItem.quantite == 0 ? '' : newItem.quantite.toString());
        _longueurControllers[newItem.uniqueId] = TextEditingController(text: newItem.longueur == 0 ? '' : newItem.longueur.toString());
        _largeurControllers[newItem.uniqueId] = TextEditingController(text: newItem.largeur == 0 ? '' : newItem.largeur.toString());
        _hauteurControllers[newItem.uniqueId] = TextEditingController(text: newItem.hauteur == 0 ? '' : newItem.hauteur.toString());
        _coefControllers[newItem.uniqueId] = TextEditingController(text: newItem.coef == 1.0 ? '' : newItem.coef.toString());
      });
    }
  }

  void _showDeleteDialog(TableItem item, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Supprimer la ligne',
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer cette ligne ?',
            style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRow(item, index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteRow(TableItem item, int index) {
    // Trouver la bonne liste d'items et l'index exact
    List<TableItem>? targetList;
    int targetIndex = -1;
    
    // Chercher dans les items directs des titres principaux
    for (int mainIndex = 0; mainIndex < _mainTitles.length; mainIndex++) {
      MainTitle mainTitle = _mainTitles[mainIndex];
      int itemIndex = mainTitle.directItems.indexOf(item);
      if (itemIndex != -1) {
        targetList = mainTitle.directItems;
        targetIndex = itemIndex;
        break;
      }
    }
    
    // Si pas trouvé, chercher dans les sous-titres
    if (targetList == null) {
      for (int mainIndex = 0; mainIndex < _mainTitles.length; mainIndex++) {
        MainTitle mainTitle = _mainTitles[mainIndex];
        for (int subIndex = 0; subIndex < mainTitle.subTitles.length; subIndex++) {
          SubTitle subTitle = mainTitle.subTitles[subIndex];
          int itemIndex = subTitle.items.indexOf(item);
          if (itemIndex != -1) {
            targetList = subTitle.items;
            targetIndex = itemIndex;
            break;
          }
        }
        if (targetList != null) break;
      }
    }
    
    if (targetList != null && targetIndex != -1) {
      _safeSetState(() {
        // Nettoyer l'ajustement de la ligne supprimée
        String itemKey = _getItemAdjustmentKey(item);
        if (itemKey.isNotEmpty) {
          print('Suppression de l\'ajustement de ligne: $itemKey');
          _adjustments.remove(itemKey);
        }
        
        // Nettoyer aussi les ajustements des lignes suivantes qui vont changer d'index
        for (int mainIndex = 0; mainIndex < _mainTitles.length; mainIndex++) {
          MainTitle mainTitle = _mainTitles[mainIndex];
          
          // Vérifier si c'est une ligne directe du titre principal
          if (mainTitle.directItems == targetList) {
            for (int i = targetIndex + 1; i < mainTitle.directItems.length; i++) {
              String oldKey = 'main_${mainTitle.name}_item_$i';
              String newKey = 'main_${mainTitle.name}_item_${i-1}';
              if (_adjustments.containsKey(oldKey)) {
                print('Déplacement de l\'ajustement: $oldKey -> $newKey');
                _adjustments[newKey] = _adjustments.remove(oldKey)!;
              }
            }
            break;
          }
          
          // Vérifier si c'est une ligne d'un sous-titre
          for (int subIndex = 0; subIndex < mainTitle.subTitles.length; subIndex++) {
            SubTitle subTitle = mainTitle.subTitles[subIndex];
            if (subTitle.items == targetList) {
              for (int i = targetIndex + 1; i < subTitle.items.length; i++) {
                String oldKey = 'sub_${mainTitle.name}_${subTitle.name}_item_$i';
                String newKey = 'sub_${mainTitle.name}_${subTitle.name}_item_${i-1}';
                if (_adjustments.containsKey(oldKey)) {
                  print('Déplacement de l\'ajustement: $oldKey -> $newKey');
                  _adjustments[newKey] = _adjustments.remove(oldKey)!;
                }
              }
              break;
            }
          }
        }
        
        targetList!.removeAt(targetIndex);
        
        // Nettoyer les controllers de la ligne supprimée avec l'identifiant unique
        _descriptifControllers.remove(item.uniqueId);
        _quantiteControllers.remove(item.uniqueId);
        _longueurControllers.remove(item.uniqueId);
        _largeurControllers.remove(item.uniqueId);
        _hauteurControllers.remove(item.uniqueId);
        _coefControllers.remove(item.uniqueId);
      });
    }
  }

  List<TableItem> _getCurrentItems() {
    // Retourner la liste des items du titre principal actuel
    for (MainTitle mainTitle in _mainTitles) {
      if (mainTitle.directItems.isNotEmpty) {
        return mainTitle.directItems;
      }
      for (SubTitle subTitle in mainTitle.subTitles) {
        if (subTitle.items.isNotEmpty) {
          return subTitle.items;
        }
      }
    }
    return [];
  }
} 