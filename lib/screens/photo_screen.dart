import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/theme_service.dart';
import '../widgets/settings_button.dart';
import 'entry_point.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({super.key});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  final ThemeService _themeService = ThemeService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _promptController = TextEditingController();
  
  File? _sourceImage;
  Uint8List? _generatedImageBytes;
  Color _selectedColor = Colors.blue;
  bool _isGenerating = false;
  String? _generationStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _promptController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _sourceImage = File(image.path);
          _generatedImageBytes = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sélection de l\'image: $e', Colors.red);
    }
  }

  void _showColorPicker() {
    final isDarkMode = _themeService.isDarkMode;
    Color tempColor = _selectedColor;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            const Color(0xFF2A2A2A).withOpacity(0.6),
                            const Color(0xFF1A1A1A).withOpacity(0.4),
                          ]
                        : [
                            const Color(0xFFFFFFFF).withOpacity(0.6),
                            const Color(0xFFF5F5F5).withOpacity(0.4),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    width: 1.5,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.15)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sélectionner une couleur',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColorPicker(
                          pickerColor: tempColor,
                          onColorChanged: (color) {
                            setDialogState(() {
                              tempColor = color;
                            });
                          },
                          displayThumbColor: true,
                          enableAlpha: false,
                          labelTypes: const [],
                          pickerAreaHeightPercent: 0.6,
                          pickerAreaBorderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
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
                              setState(() {
                                _selectedColor = tempColor;
                              });
                              
                              // Remplacer "/color" par le code hexa dans le texte
                              final currentText = _promptController.text;
                              final colorHex = _colorToHex(tempColor);
                              
                              if (currentText.toLowerCase().contains('/color')) {
                                final newText = currentText.replaceAll(RegExp(r'/color', caseSensitive: false), colorHex);
                                _promptController.value = TextEditingValue(
                                  text: newText,
                                  selection: TextSelection.collapsed(offset: newText.length),
                                );
                              } else {
                                // Si pas de /color, ajouter le code hexa à la fin
                                final newText = currentText.isEmpty 
                                    ? colorHex 
                                    : '$currentText $colorHex';
                                _promptController.value = TextEditingValue(
                                  text: newText,
                                  selection: TextSelection.collapsed(offset: newText.length),
                                );
                              }
                              
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFFE85D75),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Valider',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }

  String _colorToHex(Color color) {
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    return '#${r.toUpperCase()}${g.toUpperCase()}${b.toUpperCase()}';
  }

  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      _showSnackBar('Erreur lors de la conversion de l\'image: $e', Colors.red);
      return null;
    }
  }

  Future<void> _generateImage() async {
    if (_sourceImage == null) {
      _showSnackBar('Veuillez sélectionner une image', Colors.orange);
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      _showSnackBar('Veuillez entrer un prompt', Colors.orange);
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationStatus = 'Soumission de la requête...';
      _errorMessage = null;
      _generatedImageBytes = null;
    });

    try {
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['FIREWORK_APIKEY'];

      if (apiKey == null || apiKey.isEmpty) {
        _showSnackBar('Clé API Fireworks non configurée', Colors.red);
        setState(() {
          _isGenerating = false;
          _generationStatus = null;
        });
        return;
      }

      // Convertir l'image en base64
      final imageBase64 = await _convertImageToBase64(_sourceImage!);
      if (imageBase64 == null) {
        setState(() {
          _isGenerating = false;
          _generationStatus = null;
        });
        return;
      }

      // Construire le prompt avec la couleur si sélectionnée
      String prompt = _promptController.text.trim();
      final colorHex = _colorToHex(_selectedColor);
      prompt += ' (Couleur: $colorHex)';

      // Étape 1: Soumettre la requête
      setState(() {
        _generationStatus = 'Soumission de la requête...';
      });

      final submitResponse = await http.post(
        Uri.parse('https://api.fireworks.ai/inference/v1/workflows/accounts/fireworks/models/flux-kontext-pro'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'input_image': 'data:image/jpeg;base64,$imageBase64',
          'prompt': prompt,
        }),
      );

      if (submitResponse.statusCode != 200) {
        throw Exception('Erreur lors de la soumission: ${submitResponse.statusCode} - ${submitResponse.body}');
      }

      final submitData = jsonDecode(submitResponse.body);
      final requestId = submitData['request_id'] as String?;

      if (requestId == null) {
        throw Exception('Aucun request_id retourné');
      }

      setState(() {
        _generationStatus = 'Génération en cours...';
      });

      // Étape 2: Polling pour le résultat
      await _pollForResult(apiKey, requestId);
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _generationStatus = null;
        _errorMessage = 'Erreur: $e';
      });
      _showSnackBar('Erreur lors de la génération: $e', Colors.red);
    }
  }

  Future<void> _pollForResult(String apiKey, String requestId) async {
    const int maxAttempts = 120; // Augmenté à 120 tentatives (4 minutes max)
    const int delaySeconds = 2;

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(Duration(seconds: delaySeconds));

      if (!mounted) return;

      try {
        setState(() {
          _generationStatus = 'Génération en cours... (${i + 1}/$maxAttempts)';
        });

        final pollResponse = await http.post(
          Uri.parse('https://api.fireworks.ai/inference/v1/workflows/accounts/fireworks/models/flux-kontext-pro/get_result'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({'id': requestId}),
        );

        if (pollResponse.statusCode != 200) {
          if (i == maxAttempts - 1) {
            throw Exception('Erreur lors du polling: ${pollResponse.statusCode} - ${pollResponse.body}');
          }
          continue;
        }

        final pollData = jsonDecode(pollResponse.body);
        final status = pollData['status'] as String?;

        // Gérer le statut "Task not found" qui peut être temporaire
        if (status == 'Task not found') {
          if (i < 5) {
            // Attendre un peu plus si c'est au début
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          // Si ça persiste après plusieurs tentatives, c'est une erreur
          if (i > 10) {
            throw Exception('Tâche non trouvée après plusieurs tentatives');
          }
          continue;
        }

        if (status == 'Ready' || status == 'Complete' || status == 'Finished') {
          // La structure correcte est pollData['result']['sample']
          final result = pollData['result'];
          if (result != null && result is Map) {
            final sample = result['sample'];
            String? imageUrl;

            if (sample != null) {
              if (sample is String && sample.startsWith('http')) {
                imageUrl = sample;
              } else if (sample is Map && sample['url'] != null) {
                imageUrl = sample['url'] as String;
              }

              if (imageUrl != null) {
                // Télécharger l'image
                setState(() {
                  _generationStatus = 'Téléchargement de l\'image...';
                });

                final imageResponse = await http.get(Uri.parse(imageUrl));
                if (imageResponse.statusCode == 200) {
                  setState(() {
                    _generatedImageBytes = imageResponse.bodyBytes;
                    _isGenerating = false;
                    _generationStatus = null;
                  });
                  _showSnackBar('Image générée avec succès!', Colors.green);
                  return;
                } else {
                  throw Exception('Erreur lors du téléchargement de l\'image: ${imageResponse.statusCode}');
                }
              }
            }
          }

          // Vérifier aussi directement pollData['sample'] pour compatibilité
          if (pollData['sample'] != null) {
            final sample = pollData['sample'];
            String? imageUrl;

            if (sample is String && sample.startsWith('http')) {
              imageUrl = sample;
            } else if (sample is Map && sample['url'] != null) {
              imageUrl = sample['url'] as String;
            }

            if (imageUrl != null) {
              setState(() {
                _generationStatus = 'Téléchargement de l\'image...';
              });

              final imageResponse = await http.get(Uri.parse(imageUrl));
              if (imageResponse.statusCode == 200) {
                setState(() {
                  _generatedImageBytes = imageResponse.bodyBytes;
                  _isGenerating = false;
                  _generationStatus = null;
                });
                _showSnackBar('Image générée avec succès!', Colors.green);
                return;
              }
            }

            // Si c'est en base64
            if (sample is String && sample.startsWith('data:image')) {
              final base64Data = sample.split(',')[1];
              setState(() {
                _generatedImageBytes = base64Decode(base64Data);
                _isGenerating = false;
                _generationStatus = null;
              });
              _showSnackBar('Image générée avec succès!', Colors.green);
              return;
            }
          }

          throw Exception('Format de réponse non reconnu: ${pollData.toString()}');
        }

        if (status == 'Failed' || status == 'Error') {
          final errorMsg = pollData['error'] ?? pollData['details'] ?? 'Erreur inconnue';
          throw Exception('La génération a échoué: $errorMsg');
        }

        // Si le statut est "Pending", continuer le polling
        if (status == 'Pending') {
          continue;
        }
      } catch (e) {
        // Si c'est une erreur de parsing ou autre, continuer sauf si c'est la dernière tentative
        if (i == maxAttempts - 1) {
          setState(() {
            _isGenerating = false;
            _generationStatus = null;
            _errorMessage = 'Erreur: $e';
          });
          _showSnackBar('Erreur lors du polling: $e', Colors.red);
          return;
        }
        // Pour les autres erreurs, continuer le polling
        print('Erreur lors du polling (tentative ${i + 1}): $e');
      }
    }

    setState(() {
      _isGenerating = false;
      _generationStatus = null;
      _errorMessage = 'Timeout: La génération a pris trop de temps (${maxAttempts * delaySeconds} secondes)';
    });
    _showSnackBar('La génération a pris trop de temps', Colors.orange);
  }

  Future<void> _saveImage() async {
    if (_generatedImageBytes == null) {
      _showSnackBar('Aucune image à sauvegarder', Colors.orange);
      return;
    }

    try {
      final result = await ImageGallerySaver.saveImage(
        _generatedImageBytes!,
        quality: 100,
        name: 'ia_generated_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        _showSnackBar('Image sauvegardée dans la galerie!', Colors.green);
      } else {
        _showSnackBar('Erreur lors de la sauvegarde', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sauvegarde: $e', Colors.red);
    }
  }

  Future<void> _shareImage() async {
    if (_generatedImageBytes == null) {
      _showSnackBar('Aucune image à partager', Colors.orange);
      return;
    }

    try {
      final tempDir = await Directory.systemTemp.createTemp();
      final file = File('${tempDir.path}/ia_generated_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(_generatedImageBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Image générée par IA',
      );
    } catch (e) {
      _showSnackBar('Erreur lors du partage: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    required bool isDarkMode,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
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
              color: isDarkMode
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
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDarkMode
                                    ? [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ]
                                    : [
                                        Colors.black.withOpacity(0.05),
                                        Colors.black.withOpacity(0.02),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                width: 1.5,
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Icône IA Image avec Hero animation
                Center(
                  child: Hero(
                    tag: 'planning_hero',
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE85D75).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFFE85D75),
                        size: 45,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Section image source
                _buildGlassContainer(
                  isDarkMode: isDarkMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image source',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_sourceImage == null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildGlassButton(
                                isDarkMode: isDarkMode,
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: Icons.camera_alt,
                                label: 'Prendre une photo',
                                color: const Color(0xFFE85D75),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGlassButton(
                                isDarkMode: isDarkMode,
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: Icons.photo_library,
                                label: 'Galerie',
                                color: const Color(0xFFE85D75),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _sourceImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Changer'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDarkMode ? Colors.white70 : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _sourceImage = null;
                                      _generatedImageBytes = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Supprimer'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Section prompt
                _buildGlassContainer(
                  isDarkMode: isDarkMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions pour l\'IA',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _promptController,
                          maxLines: 4,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: Changer la couleur des murs en bleu, modifier la porte... (Tapez /color pour sélectionner une couleur)',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.white60 : Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            if (value.toLowerCase().endsWith('/color')) {
                              // Ouvrir le sélecteur de couleur sans retirer "/color"
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _showColorPicker();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bouton générer
                GestureDetector(
                  onTap: _isGenerating ? null : _generateImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE85D75),
                              const Color(0xFFE85D75).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE85D75).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _isGenerating
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _generationStatus ?? 'Génération...',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Générer',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                
                // Affichage des erreurs
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  _buildGlassContainer(
                    isDarkMode: isDarkMode,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Section résultat
                if (_generatedImageBytes != null) ...[
                  const SizedBox(height: 24),
                  _buildGlassContainer(
                    isDarkMode: isDarkMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résultat',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _generatedImageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGlassButton(
                                isDarkMode: isDarkMode,
                                onPressed: _saveImage,
                                icon: Icons.save,
                                label: 'Sauvegarder',
                                color: const Color(0xFFE85D75),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGlassButton(
                                isDarkMode: isDarkMode,
                                onPressed: _shareImage,
                                icon: Icons.share,
                                label: 'Partager',
                                color: const Color(0xFFE85D75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required bool isDarkMode,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final pinkColor = const Color(0xFFE85D75);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 2,
            color: pinkColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: pinkColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: pinkColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
