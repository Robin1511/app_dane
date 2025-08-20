import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../services/excel_export_service.dart';
import 'main_dashboard.dart';

class TableItem {
  String descriptif;
  double quantite;
  double longueur;
  double largeur;
  double hauteur;
  String unite; // 'm2', 'm3', 'U'
  
  TableItem({
    this.descriptif = '',
    this.quantite = 0,
    this.longueur = 0,
    this.largeur = 0,
    this.hauteur = 0,
    this.unite = 'm2',
  });
  
  double get total {
    switch (unite) {
      case 'm2':
        return quantite * longueur * largeur;
      case 'm3':
        return quantite * longueur * largeur * hauteur;
      case 'mL':
        return quantite * longueur;
      default:
        return quantite;
    }
  }
}

class SubTitle {
  String name;
  List<TableItem> items;
  
  SubTitle({required this.name, List<TableItem>? items}) 
    : items = items ?? [TableItem()];
    
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
  bool _isDarkMode = false;
  List<MainTitle> _mainTitles = [];
  Map<String, double> _adjustments = {}; // Stockage des ajustements

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _addMainTitle() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode 
                    ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                    : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Nouveau titre',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Nom du titre',
            labelStyle: TextStyle(
              color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
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
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _mainTitles.add(MainTitle(name: controller.text.trim()));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addSubTitle(int mainIndex) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nouveau sous-titre',
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: 'Nom du sous-titre',
            labelStyle: TextStyle(
              color: _isDarkMode ? Colors.white70 : const Color(0xFF666666),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
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
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _mainTitles[mainIndex].subTitles.add(
                    SubTitle(name: controller.text.trim()),
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                        ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                        : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
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
                                  style: TextStyle(
                                    color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
                                  backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ..._mainTitles.expand((mainTitle) {
                  List<Widget> widgets = [];
                  
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
                                          '${_mainTitles.indexOf(mainTitle) + 1}. ${mainTitle.name}',
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
                                            '${_mainTitles.indexOf(mainTitle) + 1}.${subIndex + 1} ${subTitle.name}',
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
    
    setState(() {
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
    double adjustment = _adjustments[key] ?? 0;
    return baseTotal + adjustment;
  }

  String _getDisplayTotal(String key) {
    double baseTotal = _getTotalFromKey(key);
    double adjustment = _adjustments[key] ?? 0;
    
    if (adjustment == 0) {
      return baseTotal.toStringAsFixed(2);
    } else {
      double adjustedTotal = baseTotal + adjustment;
      return '${baseTotal.toStringAsFixed(2)} ${adjustment.toStringAsFixed(2)} = ${adjustedTotal.toStringAsFixed(2)}';
    }
  }



  double _getTotalFromKey(String key) {
    if (key.startsWith('main_')) {
      String titleName = key.substring(5); // Enlever "main_"
      final mainTitle = _mainTitles.firstWhere((mt) => mt.name == titleName, orElse: () => MainTitle(name: ''));
      return mainTitle.name.isNotEmpty ? mainTitle.total : 0;
    } else if (key.startsWith('sub_')) {
      String keyWithoutPrefix = key.substring(4); // Enlever "sub_"
      List<String> parts = keyWithoutPrefix.split('_');
      if (parts.length >= 2) {
        String mainTitleName = parts[0];
        String subTitleName = parts.sublist(1).join('_'); // Rejoindre au cas où le sous-titre contient des "_"
        
        final mainTitle = _mainTitles.firstWhere((mt) => mt.name == mainTitleName, orElse: () => MainTitle(name: ''));
        if (mainTitle.name.isNotEmpty) {
          final subTitle = mainTitle.subTitles.firstWhere((st) => st.name == subTitleName, orElse: () => SubTitle(name: ''));
          return subTitle.name.isNotEmpty ? subTitle.total : 0;
        }
      }
    }
    return 0;
  }

  String _getDisplayNameFromKey(String key) {
    if (key.startsWith('main_')) {
      String titleName = key.substring(5);
      final mainTitle = _mainTitles.firstWhere((mt) => mt.name == titleName, orElse: () => MainTitle(name: ''));
      if (mainTitle.name.isNotEmpty) {
        int index = _mainTitles.indexOf(mainTitle);
        return '${index + 1}. ${titleName}';
      }
    } else if (key.startsWith('sub_')) {
      String keyWithoutPrefix = key.substring(4);
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
            return '${mainIndex + 1}.${subIndex + 1} ${subTitleName}';
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
          children: ['m2', 'm3', 'mL', 'U'].map((unit) {
            return InkWell(
              onTap: () {
                setState(() {
                  item.unite = unit;
                  if (unit != 'm3') item.hauteur = 0;
                  if (unit == 'U') {
                    item.longueur = 0;
                    item.largeur = 0;
                  }
                  if (unit == 'mL') {
                    item.largeur = 0;
                  }
                });
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: item.unite == unit
                    ? (_isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA)).withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.unite == unit
                      ? (_isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA))
                      : Colors.transparent,
                  ),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: item.unite == unit
                      ? (_isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA))
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title.toUpperCase(),
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Home pour retourner au dashboard
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
                    Icons.home_rounded,
                    color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFFE91E63),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainDashboard()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  tooltip: 'Retour au dashboard',
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isDarkMode 
                          ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                          : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calculate, color: Colors.white, size: 20),
                  ),
                  onPressed: _showCalculatorDialog,
                ),
              ),
              SettingsButton(
                isDarkMode: _isDarkMode,
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
            ],
          ),
        ],
      ),
      endDrawer: _buildSidebar(),
      body: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
        ),
        child: Column(
          children: [
            // Bouton d'ajout de titre principal
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addMainTitle,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Ajouter un titre',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
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
                  ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                  : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${mainIndex + 1}. ${mainTitle.name.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
                                    setState(() {
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
                    setState(() {
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
                color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
                      color: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
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
                                setState(() {
                                  mainTitle.directItems.add(TableItem());
                                });
                              },
                              icon: Icon(
                                Icons.add,
                                color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                                size: 16,
                              ),
                              label: Text(
                                'Ajouter ligne',
                                style: TextStyle(
                                  color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
                                            setState(() {
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
                              style: TextStyle(
                                color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
            gradient: LinearGradient(
              colors: _isDarkMode 
                ? [const Color(0xFFFF6B35), const Color(0xFFFF8E53)]
                : [const Color.fromARGB(255, 54, 108, 255), const Color.fromARGB(255, 86, 255, 255)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '${mainIndex + 1}.${subIndex + 1} ${subTitle.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getDisplayTotal('sub_${mainTitle.name}_${subTitle.name}'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_adjustments.containsKey('sub_${mainTitle.name}_${subTitle.name}'))
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
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
                            setState(() {
                              mainTitle.subTitles.removeAt(subIndex);
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
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                tooltip: 'Supprimer le sous-titre',
              ),
            ],
          ),
        ),
        
        // Tableau (séparé)
        Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.white,
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
                  color: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
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
                            setState(() {
                              subTitle.items.add(TableItem());
                            });
                          },
                          icon: Icon(
                            Icons.add,
                            color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                            size: 16,
                          ),
                          label: Text(
                            'Ajouter ligne',
                            style: TextStyle(
                              color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
                                        setState(() {
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
                          style: TextStyle(
                            color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // En-tête du tableau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
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
                  Expanded(
                    flex: 2,
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
                  Expanded(
                    flex: 2,
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
                  Expanded(
                    flex: 2,
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
                  Expanded(
                    flex: 2,
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
                  Expanded(
                    flex: 2,
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40), // Espace pour le bouton supprimer
                ],
              ),
            ),
          ),
          
          // Lignes du tableau
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            TableItem item = entry.value;
            return _buildTableRow(item, index, items);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableRow(TableItem item, int index, List<TableItem> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : const Color(0xFFE9ECEF),
            width: 0.5,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Descriptif
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                child: TextField(
                  onChanged: (value) => setState(() => item.descriptif = value),
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
                    border: InputBorder.none,
                    isDense: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    fillColor: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
                    filled: true,
                  ),
                ),
              ),
            ),
            
            // Quantité
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  onChanged: (value) => setState(() => item.quantite = double.tryParse(value) ?? 0),
                  keyboardType: TextInputType.number,
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
                    border: InputBorder.none,
                    isDense: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    fillColor: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
                    filled: true,
                  ),
                ),
              ),
            ),
            
            // Unité
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _showUniteDialog(item),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Longueur (toujours visible)
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: item.unite != 'U' 
                  ? TextField(
                      onChanged: (value) => setState(() => item.longueur = double.tryParse(value) ?? 0),
                      keyboardType: TextInputType.number,
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
                        border: InputBorder.none,
                        isDense: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        fillColor: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
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
            
            // Largeur (toujours visible)
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: item.unite != 'U' && item.unite != 'mL'
                  ? TextField(
                      onChanged: (value) => setState(() => item.largeur = double.tryParse(value) ?? 0),
                      keyboardType: TextInputType.number,
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
                        border: InputBorder.none,
                        isDense: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        fillColor: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
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
            
            // Hauteur (toujours visible)
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: item.unite == 'm3' 
                  ? TextField(
                      onChanged: (value) => setState(() => item.hauteur = double.tryParse(value) ?? 0),
                      keyboardType: TextInputType.number,
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
                        border: InputBorder.none,
                        isDense: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        fillColor: _isDarkMode ? Colors.grey[700] : const Color(0xFFF8F9FA),
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
            
            // Total
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  item.total.toStringAsFixed(2),
                  style: TextStyle(
                    color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Bouton supprimer
            SizedBox(
              width: 40,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    items.removeAt(index);
                  });
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[400],
                  size: 20,
                ),
                tooltip: 'Supprimer',
              ),
            ),
          ],
        ),
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
              setState(() {
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


  Widget _buildSidebar() {
    return Drawer(
      width: 280,
      child: Container(
        color: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode 
                    ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                    : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
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
                    onTap: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
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
                          backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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

                        if (filePath != null) {
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
                            const SnackBar(
                              content: Text('Erreur lors de l\'export Excel'),
                              backgroundColor: Colors.red,
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
                                setState(() {
                                  _adjustments.clear();
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
                        ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                        : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
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
} 