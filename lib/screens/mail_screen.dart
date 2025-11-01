import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/theme_service.dart';
import '../services/outlook_service.dart';
import 'entry_point.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Types de dialogue email
enum EmailDialogType { compose, reply }

// Types d'onglets email
enum EmailTab { received, sent, spam }

// Composant de dialogue email style Outlook moderne
class _OutlookEmailDialog extends StatefulWidget {
  final ThemeService themeService;
  final EmailDialogType type;
  final EmailMessage? replyTo;
  final Function(String to, String subject, String body, List<PlatformFile> attachments) onSend;
  final OutlookService outlookService;

  const _OutlookEmailDialog({
    super.key,
    required this.themeService,
    required this.type,
    this.replyTo,
    required this.onSend,
    required this.outlookService,
  });

  @override
  State<_OutlookEmailDialog> createState() => _OutlookEmailDialogState();
}

class _OutlookEmailDialogState extends State<_OutlookEmailDialog> {
  late TextEditingController _toController;
  late TextEditingController _ccController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  final List<PlatformFile> _attachments = [];
  bool _isSending = false;
  
  // Autocomplétion des contacts
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  List<Contact> _filteredCcContacts = [];
  bool _showSuggestions = false;
  bool _showCcSuggestions = false;
  final FocusNode _toFieldFocusNode = FocusNode();
  final FocusNode _ccFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(
      text: widget.replyTo?.senderEmail ?? '',
    );
    _ccController = TextEditingController();
    _subjectController = TextEditingController(
      text: widget.type == EmailDialogType.reply 
        ? 'Re: ${widget.replyTo?.subject ?? ''}' 
        : '',
    );
    _bodyController = TextEditingController(
      text: widget.type == EmailDialogType.reply 
        ? '\n\n---\n${widget.replyTo?.subject ?? ''}\n---' 
        : '',
    );
    
    _toController.addListener(_onToFieldChanged);
    _ccController.addListener(_onCcFieldChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _toController.removeListener(_onToFieldChanged);
    _ccController.removeListener(_onCcFieldChanged);
    _toController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _toFieldFocusNode.dispose();
    _ccFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await widget.outlookService.getContacts();
    setState(() {
      _allContacts = contacts;
    });
  }

  void _onToFieldChanged() {
    final query = _toController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filteredContacts = [];
      });
      return;
    }
    
    final filtered = _allContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(query) ||
             contact.emailAddress.toLowerCase().contains(query);
    }).toList();
    
    setState(() {
      _filteredContacts = filtered;
      _showSuggestions = filtered.isNotEmpty;
    });
  }

  void _onCcFieldChanged() {
    final query = _ccController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _showCcSuggestions = false;
        _filteredCcContacts = [];
      });
      return;
    }
    
    final filtered = _allContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(query) ||
             contact.emailAddress.toLowerCase().contains(query);
    }).toList();
    
    setState(() {
      _filteredCcContacts = filtered;
      _showCcSuggestions = filtered.isNotEmpty;
    });
  }

  void _selectContact(Contact contact) {
    _toController.text = contact.emailAddress;
    setState(() {
      _showSuggestions = false;
    });
  }

  void _selectCcContact(Contact contact) {
    _ccController.text = contact.emailAddress;
    setState(() {
      _showCcSuggestions = false;
    });
  }

  Future<void> _addAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowCompression: false,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _sendEmail() async {
    if (_toController.text.trim().isEmpty || 
        _subjectController.text.trim().isEmpty || 
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      await widget.onSend(
        _toController.text.trim(),
        _subjectController.text.trim(),
        _bodyController.text.trim(),
        _attachments,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showAIGenerateDialog() {
    final TextEditingController specificationsController = TextEditingController();
    bool isGenerating = false;
    bool useExistingContent = _bodyController.text.trim().isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: widget.themeService.surfaceColor,
            title: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.purple.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Générer avec IA',
                    style: TextStyle(
                      color: widget.themeService.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useExistingContent) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'L\'IA utilisera le contenu actuel comme base',
                            style: TextStyle(
                              color: widget.themeService.textColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Instructions pour l\'IA',
                  style: TextStyle(
                    color: widget.themeService.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.themeService.isDarkMode 
                        ? Colors.grey[600]! 
                        : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: specificationsController,
                    maxLines: null,
                    enabled: !isGenerating,
                    decoration: InputDecoration(
                      hintText: useExistingContent 
                        ? 'Ex: Rendre plus formel, ajouter des détails techniques...'
                        : 'Ex: Rédiger un email de demande de rendez-vous professionnel...',
                      hintStyle: TextStyle(
                        color: widget.themeService.subtitleColor,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(
                      color: widget.themeService.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isGenerating) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Génération en cours...',
                        style: TextStyle(
                          color: widget.themeService.subtitleColor,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isGenerating ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: isGenerating 
                      ? widget.themeService.subtitleColor.withOpacity(0.5)
                      : widget.themeService.subtitleColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isGenerating ? null : () async {
                  if (specificationsController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer des instructions'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  setDialogState(() => isGenerating = true);

                  try {
                    final generatedText = await _generateEmailContent(
                      specificationsController.text.trim(),
                      useExistingContent ? _bodyController.text : null,
                      _subjectController.text,
                    );

                    Navigator.of(context).pop();

                    if (generatedText != null) {
                      setState(() {
                        _bodyController.text = generatedText;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contenu généré avec succès !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur lors de la génération'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGenerating 
                    ? Colors.grey 
                    : Colors.purple.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 8),
                    Text(isGenerating ? 'Génération...' : 'Générer'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _generateEmailContent(String instructions, String? existingContent, String subject) async {
    try {
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['FIREWORK_APIKEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clé API Fireworks non configurée'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      String prompt;
      if (existingContent != null && existingContent.isNotEmpty) {
        prompt = '''Améliore/Modifie ce contenu d'email selon ces instructions :

Sujet de l'email: $subject

Contenu actuel:
$existingContent

Instructions:
$instructions

Génère le nouveau contenu en gardant un ton professionnel. Ne mets pas de formule de politesse de début (Cher/Chère) ni de signature.''';
      } else {
        prompt = '''Rédige le contenu d'un email professionnel selon ces instructions :

Sujet: $subject

Instructions:
$instructions

Génère uniquement le contenu du message, sans formule de début (pas de "Cher/Chère") ni de signature. Sois professionnel et concis.''';
      }

      final response = await http.post(
        Uri.parse('https://api.fireworks.ai/inference/v1/chat/completions'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'accounts/fireworks/models/deepseek-v3p1-terminus',
          'max_tokens': 20480,
          'top_p': 1,
          'top_k': 40,
          'presence_penalty': 0,
          'frequency_penalty': 0,
          'temperature': 0.6,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        print('Erreur API Fireworks: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de l\'appel à l\'IA: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: widget.themeService.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header style Outlook
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: widget.themeService.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.type == EmailDialogType.compose ? Icons.edit : Icons.reply,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.type == EmailDialogType.compose ? 'Nouveau message' : 'Répondre',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Contenu du dialogue
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Champ À avec autocomplétion
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _toController,
                          label: 'À',
                          icon: Icons.person,
                          focusNode: _toFieldFocusNode,
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              setState(() => _showSuggestions = false);
                            } else {
                              _onToFieldChanged();
                            }
                          },
                        ),
                        
                        // Suggestions de contacts
                        if (_showSuggestions && _filteredContacts.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: widget.themeService.isDarkMode 
                                ? Colors.grey[800] 
                                : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.themeService.isDarkMode 
                                  ? Colors.grey[600]! 
                                  : Colors.grey[300]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredContacts.length > 5 ? 5 : _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _selectContact(contact),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: widget.themeService.isDarkMode 
                                              ? Colors.grey[700]! 
                                              : Colors.grey[200]!,
                                            width: index < _filteredContacts.length - 1 && index < 4 ? 1 : 0,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              gradient: widget.themeService.primaryGradient,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                contact.displayName.isNotEmpty 
                                                  ? contact.displayName[0].toUpperCase()
                                                  : 'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          
                                          // Infos contact
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.displayName,
                                                  style: TextStyle(
                                                    color: widget.themeService.textColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  contact.emailAddress,
                                                  style: TextStyle(
                                                    color: widget.themeService.subtitleColor,
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (contact.jobTitle != null)
                                                  Text(
                                                    contact.jobTitle!,
                                                    style: TextStyle(
                                                      color: widget.themeService.subtitleColor,
                                                      fontSize: 11,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
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
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ CC (Copie) avec autocomplétion
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _ccController,
                          label: 'Cc (Copie)',
                          icon: Icons.person_add_alt,
                          focusNode: _ccFieldFocusNode,
                          onFocusChange: (hasFocus) {
                            if (!hasFocus) {
                              setState(() => _showCcSuggestions = false);
                            } else {
                              _onCcFieldChanged();
                            }
                          },
                        ),
                        
                        // Suggestions de contacts pour CC
                        if (_showCcSuggestions && _filteredCcContacts.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: widget.themeService.isDarkMode 
                                ? Colors.grey[800] 
                                : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.themeService.isDarkMode 
                                  ? Colors.grey[600]! 
                                  : Colors.grey[300]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredCcContacts.length > 5 ? 5 : _filteredCcContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredCcContacts[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _selectCcContact(contact),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: widget.themeService.isDarkMode 
                                              ? Colors.grey[700]! 
                                              : Colors.grey[200]!,
                                            width: index < _filteredCcContacts.length - 1 && index < 4 ? 1 : 0,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              gradient: widget.themeService.primaryGradient,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                contact.displayName.isNotEmpty 
                                                  ? contact.displayName[0].toUpperCase()
                                                  : 'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          
                                          // Infos contact
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.displayName,
                                                  style: TextStyle(
                                                    color: widget.themeService.textColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  contact.emailAddress,
                                                  style: TextStyle(
                                                    color: widget.themeService.subtitleColor,
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (contact.jobTitle != null)
                                                  Text(
                                                    contact.jobTitle!,
                                                    style: TextStyle(
                                                      color: widget.themeService.subtitleColor,
                                                      fontSize: 11,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
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
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ Objet
                    _buildInputField(
                      controller: _subjectController,
                      label: 'Objet',
                      icon: Icons.subject,
                    ),
                    const SizedBox(height: 16),
                    
                    // Pièces jointes
                    if (_attachments.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                                  color: widget.themeService.isDarkMode 
          ? Colors.grey[800]! 
          : Colors.grey[100]!,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 16,
                                  color: widget.themeService.subtitleColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pièces jointes (${_attachments.length})',
                                  style: TextStyle(
                                    color: widget.themeService.subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Défilement horizontal des pièces jointes
                            SizedBox(
                              height: 95,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _attachments.length,
                                itemBuilder: (context, index) {
                                  final attachment = _attachments[index];
                                  return Container(
                                    width: 180,
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: widget.themeService.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _getFileIcon(attachment.extension ?? ''),
                                              size: 22,
                                              color: widget.themeService.primaryColor,
                                            ),
                                            const Spacer(),
                                            InkWell(
                                              onTap: () => _removeAttachment(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Flexible(
                                          child: Text(
                                            attachment.name,
                                            style: TextStyle(
                                              color: widget.themeService.textColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                            color: widget.themeService.subtitleColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Boutons pièce jointe et IA
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addAttachment,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Ajouter une pièce jointe'),
                                  style: ElevatedButton.styleFrom(
          backgroundColor: widget.themeService.isDarkMode 
            ? Colors.grey[700]! 
            : Colors.grey[200]!,
          foregroundColor: widget.themeService.textColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _showAIGenerateDialog,
                          icon: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: Colors.purple.shade400,
                          ),
                          label: Text(
                            'Générer avec IA',
                            style: TextStyle(color: Colors.purple.shade400),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.purple.shade400),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ Message
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.themeService.isDarkMode 
                              ? Colors.grey[600]! 
                              : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _bodyController,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            hintText: 'Tapez votre message ici...',
                            hintStyle: TextStyle(
                              color: widget.themeService.subtitleColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            color: widget.themeService.textColor,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer avec boutons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                        color: widget.themeService.isDarkMode 
          ? Colors.grey[850]! 
          : Colors.grey[100]!,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: widget.themeService.subtitleColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeService.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.type == EmailDialogType.compose ? 'Envoyer' : 'Répondre',
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
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    Function(bool)? onFocusChange,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.themeService.isDarkMode 
            ? Colors.grey[600]! 
            : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Focus(
        onFocusChange: onFocusChange,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: widget.themeService.subtitleColor,
            ),
            prefixIcon: Icon(
              icon,
              color: widget.themeService.subtitleColor,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            color: widget.themeService.textColor,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// Dialogue d'email avec contenu IA pré-rempli
class _OutlookEmailDialogWithAI extends StatefulWidget {
  final ThemeService themeService;
  final EmailMessage replyTo;
  final String aiGeneratedBody;
  final Function(String to, String subject, String body, List<PlatformFile> attachments) onSend;
  final OutlookService outlookService;

  const _OutlookEmailDialogWithAI({
    super.key,
    required this.themeService,
    required this.replyTo,
    required this.aiGeneratedBody,
    required this.onSend,
    required this.outlookService,
  });

  @override
  State<_OutlookEmailDialogWithAI> createState() => _OutlookEmailDialogWithAIState();
}

class _OutlookEmailDialogWithAIState extends State<_OutlookEmailDialogWithAI> {
  late TextEditingController _toController;
  late TextEditingController _ccController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  final List<PlatformFile> _attachments = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.replyTo.senderEmail);
    _ccController = TextEditingController();
    _subjectController = TextEditingController(text: 'Re: ${widget.replyTo.subject}');
    _bodyController = TextEditingController(text: widget.aiGeneratedBody);
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _addAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowCompression: false,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _sendEmail() async {
    if (_toController.text.trim().isEmpty || 
        _subjectController.text.trim().isEmpty || 
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      await widget.onSend(
        _toController.text.trim(),
        _subjectController.text.trim(),
        _bodyController.text.trim(),
        _attachments,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: widget.themeService.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header style Outlook avec badge IA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Réponse générée par IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Contenu du dialogue
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Info badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.purple.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vous pouvez modifier le contenu avant d\'envoyer',
                              style: TextStyle(
                                color: widget.themeService.textColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ À
                    _buildInputField(
                      controller: _toController,
                      label: 'À',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ CC (Copie)
                    _buildInputField(
                      controller: _ccController,
                      label: 'Cc (Copie)',
                      icon: Icons.person_add_alt,
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ Objet
                    _buildInputField(
                      controller: _subjectController,
                      label: 'Objet',
                      icon: Icons.subject,
                    ),
                    const SizedBox(height: 16),
                    
                    // Pièces jointes
                    if (_attachments.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.themeService.isDarkMode 
                            ? Colors.grey[800]! 
                            : Colors.grey[100]!,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 16,
                                  color: widget.themeService.subtitleColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pièces jointes (${_attachments.length})',
                                  style: TextStyle(
                                    color: widget.themeService.subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _attachments.length,
                                itemBuilder: (context, index) {
                                  final attachment = _attachments[index];
                                  return Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.themeService.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _getFileIcon(attachment.extension ?? ''),
                                              size: 20,
                                              color: widget.themeService.primaryColor,
                                            ),
                                            const Spacer(),
                                            InkWell(
                                              onTap: () => _removeAttachment(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Expanded(
                                          child: Text(
                                            attachment.name,
                                            style: TextStyle(
                                              color: widget.themeService.textColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                            color: widget.themeService.subtitleColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Bouton ajouter pièce jointe
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addAttachment,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Ajouter une pièce jointe'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.themeService.isDarkMode 
                              ? Colors.grey[700]! 
                              : Colors.grey[200]!,
                            foregroundColor: widget.themeService.textColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Champ Message
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.purple.shade200,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _bodyController,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            hintText: 'Modifiez la réponse si nécessaire...',
                            hintStyle: TextStyle(
                              color: widget.themeService.subtitleColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            color: widget.themeService.textColor,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer avec boutons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.themeService.isDarkMode 
                  ? Colors.grey[850]! 
                  : Colors.grey[100]!,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: widget.themeService.subtitleColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.send, size: 18),
                            SizedBox(width: 8),
                            Text('Envoyer'),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.themeService.isDarkMode 
            ? Colors.grey[600]! 
            : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: widget.themeService.subtitleColor,
          ),
          prefixIcon: Icon(
            icon,
            color: widget.themeService.subtitleColor,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: widget.themeService.textColor,
          fontSize: 15,
        ),
      ),
    );
  }
}

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  final ThemeService _themeService = ThemeService();
  final OutlookService _outlookService = OutlookService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  UserInfo? _userInfo;
  List<EmailMessage> _emails = [];
  EmailMessage? _selectedEmail;
  bool _showEmailDetail = false;
  EmailTab _currentTab = EmailTab.received; // Ajout de l'onglet pour les emails reçus
  List<EmailMessage> _sentEmails = []; // Liste des emails envoyés
  List<EmailMessage> _spamEmails = []; // Liste des emails spam
  
  // Pagination
  bool _isLoadingMore = false;
  bool _hasMoreEmails = true;
  bool _hasMoreSentEmails = true;
  bool _hasMoreSpamEmails = true;
  final ScrollController _emailListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
    // Écouter le scroll pour charger plus d'emails
    _emailListScrollController.addListener(_onScroll);
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _emailListScrollController.removeListener(_onScroll);
    _emailListScrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    // Charger plus d'emails quand on arrive à 80% du scroll
    if (_emailListScrollController.position.pixels >= 
        _emailListScrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore) {
        if (_currentTab == EmailTab.received && _hasMoreEmails) {
          _loadMoreEmails();
        } else if (_currentTab == EmailTab.sent && _hasMoreSentEmails) {
          _loadMoreSentEmails();
        } else if (_currentTab == EmailTab.spam && _hasMoreSpamEmails) {
          _loadMoreSpamEmails();
        }
      }
    }
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);
    
    _isLoggedIn = _outlookService.isLoggedIn;
    if (_isLoggedIn) {
      await _loadUserInfo();
      await _loadEmails();
      await _loadSentEmails(); // Charger les emails envoyés
      await _loadSpamEmails(); // Charger les emails spam
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserInfo() async {
    _userInfo = await _outlookService.getUserInfo();
  }

  Future<void> _loadEmails() async {
    final emails = await _outlookService.getEmails(top: 20);
    setState(() {
      _emails = emails;
      _hasMoreEmails = emails.length >= 20;
    });
  }

  Future<void> _loadSentEmails() async {
    final sentEmails = await _outlookService.getSentEmails(top: 20);
    setState(() {
      _sentEmails = sentEmails;
      _hasMoreSentEmails = sentEmails.length >= 20;
    });
  }

  Future<void> _loadSpamEmails() async {
    final spamEmails = await _outlookService.getSpamEmails(top: 20);
    setState(() {
      _spamEmails = spamEmails;
      _hasMoreSpamEmails = spamEmails.length >= 20;
    });
  }
  
  Future<void> _loadMoreEmails() async {
    if (_isLoadingMore || !_hasMoreEmails) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      // Utiliser le dernier email comme point de départ (skip simulation)
      final moreEmails = await _outlookService.getEmails(top: 20, skip: _emails.length);
      
      setState(() {
        if (moreEmails.isEmpty || moreEmails.length < 20) {
          _hasMoreEmails = false;
        }
        _emails.addAll(moreEmails);
      });
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }
  
  Future<void> _loadMoreSentEmails() async {
    if (_isLoadingMore || !_hasMoreSentEmails) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final moreSentEmails = await _outlookService.getSentEmails(top: 20, skip: _sentEmails.length);
      
      setState(() {
        if (moreSentEmails.isEmpty || moreSentEmails.length < 20) {
          _hasMoreSentEmails = false;
        }
        _sentEmails.addAll(moreSentEmails);
      });
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadMoreSpamEmails() async {
    if (_isLoadingMore || !_hasMoreSpamEmails) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final moreSpamEmails = await _outlookService.getSpamEmails(top: 20, skip: _spamEmails.length);
      
      setState(() {
        if (moreSpamEmails.isEmpty || moreSpamEmails.length < 20) {
          _hasMoreSpamEmails = false;
        }
        _spamEmails.addAll(moreSpamEmails);
      });
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final success = await _outlookService.authenticate();
    if (success) {
      await _loadUserInfo();
      await _loadEmails();
      await _loadSentEmails(); // Charger les emails envoyés après connexion
      setState(() => _isLoggedIn = true);
    } else {
      _showSnackBar('Erreur de connexion à Outlook', Colors.red);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await _outlookService.logout();
    setState(() {
      _isLoggedIn = false;
      _userInfo = null;
      _emails.clear();
      _sentEmails.clear(); // Clear sent emails on logout
      _spamEmails.clear(); // Clear spam emails on logout
      _selectedEmail = null;
      _showEmailDetail = false;
      _currentTab = EmailTab.received; // Reset tab
    });
  }

  void _selectEmail(EmailMessage email) {
    setState(() {
      _selectedEmail = email;
      _showEmailDetail = true;
    });
  }

  void _closeEmailDetail() {
    setState(() {
      _showEmailDetail = false;
      _selectedEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _themeService.backgroundColor,
          appBar: _buildAppBar(),
          endDrawer: _buildSidebar(),
          body: _isLoading ? _buildLoadingState() : _buildMainContent(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const EntryPoint()),
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
          Icon(
            Icons.mail,
            color: _themeService.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Mails Outlook',
            style: TextStyle(
              color: _themeService.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        if (_isLoggedIn && _outlookService.isDemo) 
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'DÉMO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_isLoggedIn)
          Container(
            margin: const EdgeInsets.only(right: 8),
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
            child: IconButton(
              icon: Icon(
                Icons.add,
                color: _themeService.primaryColor,
                size: 20,
              ),
              onPressed: _showNewEmailDialog,
              tooltip: 'Nouveau mail',
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 8),
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
          child: IconButton(
            icon: Icon(
              Icons.menu,
              color: _themeService.primaryColor,
              size: 20,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_themeService.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: TextStyle(
              color: _themeService.textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (!_isLoggedIn) {
      return _buildLoginScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 800;
        
        if (isWideScreen) {
          // Desktop/Tablet layout avec sidebar
          return Row(
            children: [
              // Liste des emails
              SizedBox(
                width: 350,
                child: _buildEmailListWithTabs(),
              ),
              // Détail de l'email
              Expanded(
                child: _selectedEmail != null 
                  ? _buildEmailDetail()
                  : _buildEmptyState(),
              ),
            ],
          );
        } else {
          // Mobile layout
          return _showEmailDetail && _selectedEmail != null
            ? _buildEmailDetail()
            : _buildEmailListWithTabs();
        }
      },
    );
  }

  Widget _buildEmailListWithTabs() {
    return Column(
      children: [
        // Onglets pour séparer reçus/envoyés/spam
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _themeService.isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentTab = EmailTab.received),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentTab == EmailTab.received
                        ? _themeService.primaryColor
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Reçus (${_emails.length})',
                        style: TextStyle(
                          color: _currentTab == EmailTab.received
                            ? Colors.white
                            : _themeService.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentTab = EmailTab.sent),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentTab == EmailTab.sent
                        ? _themeService.primaryColor
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Envoyés (${_sentEmails.length})',
                        style: TextStyle(
                          color: _currentTab == EmailTab.sent
                            ? Colors.white
                            : _themeService.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentTab = EmailTab.spam),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _currentTab == EmailTab.spam
                        ? _themeService.primaryColor
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Spam (${_spamEmails.length})',
                        style: TextStyle(
                          color: _currentTab == EmailTab.spam
                            ? Colors.white
                            : _themeService.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Liste des emails selon l'onglet
                       Expanded(
                 child: _buildEmailList(),
               ),
      ],
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo et titre
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _themeService.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mail,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Outlook Mail',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _themeService.textColor,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Connectez-vous pour accéder à vos emails',
              style: TextStyle(
                fontSize: 16,
                color: _themeService.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Bouton de connexion
            Container(
              width: double.infinity,
              height: 50,
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
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Se connecter à Outlook',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_outlookService.isDemo) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'MODE DÉMO ACTIVÉ',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cette application utilise des données de démonstration. Pour une vraie intégration Outlook, configurez votre client_id Microsoft Graph dans outlook_service.dart',
                      style: TextStyle(
                        color: _themeService.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailList() {
    return Container(
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
        border: Border(
          right: BorderSide(
            color: _themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header de la liste
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _themeService.isDarkMode ? Colors.grey[850] : Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: _themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _currentTab == EmailTab.received 
                    ? 'Boîte de réception' 
                    : _currentTab == EmailTab.sent 
                      ? 'Emails envoyés' 
                      : 'Courrier indésirable',
                  style: TextStyle(
                    color: _themeService.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _themeService.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentTab == EmailTab.received 
                      ? '${_emails.length}' 
                      : _currentTab == EmailTab.sent 
                        ? '${_sentEmails.length}' 
                        : '${_spamEmails.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des emails
          Expanded(
            child: _currentTab == EmailTab.received
              ? (_emails.isEmpty
                  ? _buildEmptyEmailList()
                  : ListView.builder(
                      controller: _emailListScrollController,
                      itemCount: _emails.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _emails.length) {
                          // Indicateur de chargement en bas
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(_themeService.primaryColor),
                              ),
                            ),
                          );
                        }
                        
                        final email = _emails[index];
                        final isSelected = _selectedEmail?.id == email.id;
                        
                        return _buildEmailItem(email, isSelected);
                      },
                    ))
              : _currentTab == EmailTab.sent
                ? (_sentEmails.isEmpty
                    ? _buildEmptySentEmailList()
                    : ListView.builder(
                        controller: _emailListScrollController,
                        itemCount: _sentEmails.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _sentEmails.length) {
                            // Indicateur de chargement en bas
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(_themeService.primaryColor),
                                ),
                              ),
                            );
                          }
                          
                          final email = _sentEmails[index];
                          final isSelected = _selectedEmail?.id == email.id;
                          
                          return _buildEmailItem(email, isSelected);
                        },
                      ))
                : (_spamEmails.isEmpty
                    ? _buildEmptySpamEmailList()
                    : ListView.builder(
                        controller: _emailListScrollController,
                        itemCount: _spamEmails.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _spamEmails.length) {
                            // Indicateur de chargement en bas
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(_themeService.primaryColor),
                                ),
                              ),
                            );
                          }
                          
                          final email = _spamEmails[index];
                          final isSelected = _selectedEmail?.id == email.id;
                          
                          return _buildEmailItem(email, isSelected);
                        },
                      )),
          ),
        ],
      ),
    );
  }

  // Cette méthode n'est plus utilisée - intégrée dans _buildEmailList

  Widget _buildEmailItem(EmailMessage email, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
          ? _themeService.primaryColor.withOpacity(0.1)
          : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectEmail(email),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: _themeService.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          email.senderName.isNotEmpty 
                            ? email.senderName[0].toUpperCase()
                            : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Nom et heure
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _cleanStringForDisplay(email.senderName),
                            style: TextStyle(
                              color: _themeService.textColor,
                              fontWeight: email.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _themeService.isDarkMode 
                                ? Colors.grey[700] 
                                : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDate(email.receivedDateTime),
                              style: TextStyle(
                                color: _themeService.subtitleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Indicateurs
                    Column(
                      children: [
                        if (email.hasAttachments)
                          GestureDetector(
                            onTap: () => _showAttachments(email),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _themeService.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.attach_file,
                                size: 14,
                                color: _themeService.primaryColor,
                              ),
                            ),
                          ),
                        if (email.importance == 'high')
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              size: 14,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Sujet avec indicateur de conversation
                Row(
                  children: [
                    // Indicateur de conversation (RE:/FWD:)
                    if (email.subject.toUpperCase().startsWith('RE:') || 
                        email.subject.toUpperCase().startsWith('FWD:'))
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: _themeService.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          email.subject.toUpperCase().startsWith('RE:')
                            ? Icons.reply
                            : Icons.forward,
                          size: 12,
                          color: _themeService.primaryColor,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _cleanStringForDisplay(email.subject),
                        style: TextStyle(
                          color: _themeService.textColor,
                          fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Aperçu du contenu
                Text(
                  _cleanStringForDisplay(email.bodyPreview),
                  style: TextStyle(
                    color: _themeService.subtitleColor,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEmailList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: _themeService.subtitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun email',
            style: TextStyle(
              color: _themeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre boîte de réception est vide',
            style: TextStyle(
              color: _themeService.subtitleColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySentEmailList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.send,
            size: 64,
            color: _themeService.subtitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun email envoyé',
            style: TextStyle(
              color: _themeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore d\'email envoyé',
            style: TextStyle(
              color: _themeService.subtitleColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySpamEmailList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_gmailerrorred,
            size: 64,
            color: _themeService.subtitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun spam',
            style: TextStyle(
              color: _themeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre dossier spam est vide',
            style: TextStyle(
              color: _themeService.subtitleColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDetail() {
    if (_selectedEmail == null) return _buildEmptyState();
    
    return Container(
      color: _themeService.isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          // Header du détail
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _themeService.isDarkMode ? Colors.grey[850] : Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: _themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                if (MediaQuery.of(context).size.width <= 800)
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: _themeService.textColor),
                    onPressed: _closeEmailDetail,
                  ),
                Expanded(
                  child: Text(
                    _selectedEmail!.subject,
                    style: TextStyle(
                      color: _themeService.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.reply, color: _themeService.primaryColor),
                  onPressed: () => _replyToEmail(_selectedEmail!),
                  tooltip: 'Répondre',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEmail(_selectedEmail!),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
          
          // Contenu de l'email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de l'email
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: _themeService.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmail!.senderName.isNotEmpty 
                              ? _selectedEmail!.senderName[0].toUpperCase()
                              : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cleanStringForDisplay(_selectedEmail!.senderName),
                              style: TextStyle(
                                color: _themeService.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _selectedEmail!.senderEmail,
                              style: TextStyle(
                                color: _themeService.subtitleColor,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatFullDate(_selectedEmail!.receivedDateTime),
                              style: TextStyle(
                                color: _themeService.subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bouton IA
                      IconButton(
                        onPressed: () => _showAIReplyDialog(_selectedEmail!),
                        icon: Icon(
                          Icons.auto_awesome,
                          color: Colors.purple.shade400,
                          size: 24,
                        ),
                        tooltip: 'Répondre avec IA',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Pièces jointes en haut
                if (_selectedEmail!.hasAttachments)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _themeService.isDarkMode ? Colors.grey[850] : Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(
                          color: _themeService.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: _buildAttachmentsSection(_selectedEmail!.id),
                  ),
                
                // Contenu de l'email avec WebView
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildEmailBody(_selectedEmail!.body),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: _themeService.subtitleColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez un email',
            style: TextStyle(
              color: _themeService.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez un email dans la liste pour le lire',
            style: TextStyle(
              color: _themeService.subtitleColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
                      Navigator.of(context).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const EntryPoint()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                  if (_isLoggedIn) ...[
                    _buildSidebarItem(
                      icon: Icons.refresh,
                      title: 'Actualiser',
                      onTap: () {
                        Navigator.of(context).pop();
                        _loadEmails();
                        _loadSentEmails(); // Actualiser les emails envoyés
                        _showSnackBar('Emails actualisés', Colors.green);
                      },
                    ),
                    _buildSidebarItem(
                      icon: Icons.logout,
                      title: 'Se déconnecter',
                      onTap: () {
                        Navigator.of(context).pop();
                        _logout();
                        _showSnackBar('Déconnecté avec succès', Colors.blue);
                      },
                    ),
                  ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(date.year, date.month, date.day);
    
    if (emailDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmailBody(String body) {
    if (body.trim().isEmpty) {
      return Center(
        child: Text(
          'Aucun contenu',
          style: TextStyle(
            color: _themeService.subtitleColor,
            fontSize: 16,
          ),
        ),
      );
    }

    // Créer un HTML enrichi avec des styles adaptés au thème
    final String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
        * {
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            font-size: 14px;
            line-height: 1.6;
            color: ${_themeService.isDarkMode ? '#FFFFFF' : '#000000'};
            background-color: ${_themeService.isDarkMode ? '#1E1E1E' : '#FFFFFF'};
            padding: 0 !important;
            margin: 0 !important;
            overflow-x: hidden;
            width: 100%;
        }
        /* Centrer le contenu des emails */
        body > table,
        body > div,
        body > center {
            margin: 0 auto !important;
        }
        a {
            color: #0078D4 !important;
            text-decoration: underline;
        }
        img {
            max-width: 100% !important;
            height: auto !important;
            display: block;
            border: 0;
        }
        table {
            max-width: 100% !important;
            border-collapse: collapse;
            border-spacing: 0;
        }
        td, th {
            padding: 8px;
            word-wrap: break-word;
            vertical-align: top;
        }
        /* Supprimer TOUTES les bordures des tableaux */
        table, td, th, tr {
            border: none !important;
        }
        /* Forcer le contenu à ne pas dépasser */
        div, p, span, h1, h2, h3, h4, h5, h6 {
            max-width: 100%;
            word-wrap: break-word;
            overflow-wrap: break-word;
        }
        /* Cacher les éléments vides ou invisibles */
        [style*="display:none"],
        [style*="display: none"],
        [hidden] {
            display: none !important;
        }
        /* Gérer les icônes manquantes - remplacer par du texte */
        i, .icon, .fa, [class*="icon-"] {
            font-style: normal;
        }
        /* Supprimer les espacements excessifs en haut */
        body > *:first-child {
            margin-top: 0 !important;
            padding-top: 0 !important;
        }
    </style>
</head>
<body>
    $body
</body>
</html>
    ''';

    // Créer le contrôleur WebView
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Ouvrir les liens externes dans le navigateur
            if (request.url.startsWith('http://') || request.url.startsWith('https://')) {
              launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    return WebViewWidget(controller: controller);
  }

  // Afficher la section des pièces jointes
  Widget _buildAttachmentsSection(String messageId) {
    return FutureBuilder<List<EmailAttachment>>(
      future: _outlookService.getAttachments(messageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_themeService.primaryColor),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final attachments = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: _themeService.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pièces jointes (${attachments.length})',
                  style: TextStyle(
                    color: _themeService.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                itemBuilder: (context, index) {
                  return _buildAttachmentItem(messageId, attachments[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Afficher un élément de pièce jointe
  Widget _buildAttachmentItem(String messageId, EmailAttachment attachment) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _downloadAttachment(messageId, attachment),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      attachment.fileIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.download,
                      color: _themeService.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    attachment.name,
                    style: TextStyle(
                      color: _themeService.textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  attachment.formattedSize,
                  style: TextStyle(
                    color: _themeService.subtitleColor,
                    fontSize: 11,
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

  // Télécharger une pièce jointe
  Future<void> _downloadAttachment(String messageId, EmailAttachment attachment) async {
    try {
      _showSnackBar('Téléchargement de ${attachment.name}...', _themeService.primaryColor);
      
      final bytes = await _outlookService.downloadAttachment(messageId, attachment.id);
      
      if (bytes != null) {
        if (kIsWeb) {
          // En mode web, télécharger directement dans le navigateur
          // TODO: Implémenter le téléchargement web avec html package
          _showSnackBar('Téléchargement terminé : ${attachment.name}', Colors.green);
        } else {
          // Sur mobile/desktop, sauvegarder dans le dossier Documents
          try {
            final directory = await getApplicationDocumentsDirectory();
            final filePath = '${directory.path}/${attachment.name}';
            final file = File(filePath);
            
            await file.writeAsBytes(bytes);
            
            _showSnackBar(
              'Fichier sauvegardé : ${attachment.name}',
              Colors.green,
            );
            
            // Optionnel : Ouvrir le fichier avec l'application par défaut
            // await launchUrl(Uri.file(filePath));
          } catch (e) {
            _showSnackBar('Erreur lors de la sauvegarde: $e', Colors.red);
          }
        }
      } else {
        _showSnackBar('Erreur lors du téléchargement', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', Colors.red);
    }
  }

  // Nettoyer les caractères UTF-16 invalides d'une chaîne
  String _cleanStringForDisplay(String text) {
    if (text.isEmpty) return text;
    
    // Supprimer les caractères UTF-16 invalides (surrogates non appariés)
    return String.fromCharCodes(
      text.runes.where((rune) {
        // Garder seulement les caractères valides
        return rune >= 0x20 && rune != 0xFFFD;
      }),
    );
  }

  // Afficher le dialogue de nouveau mail
  void _showNewEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OutlookEmailDialog(
        themeService: _themeService,
        type: EmailDialogType.compose,
        outlookService: _outlookService,
        onSend: (to, subject, body, attachments) async {
          await _sendEmail(to, subject, body, attachments);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Répondre à un email
  void _replyToEmail(EmailMessage email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OutlookEmailDialog(
        themeService: _themeService,
        type: EmailDialogType.reply,
        replyTo: email,
        outlookService: _outlookService,
        onSend: (to, subject, body, attachments) async {
          await _sendEmail(to, subject, body, attachments);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Envoyer un email (vraie fonctionnalité)
  Future<void> _sendEmail(String to, String subject, String body, List<PlatformFile> attachments) async {
    try {
      setState(() => _isLoading = true);
      
      // Envoi via Microsoft Graph API
      final success = await _outlookService.sendEmail(to, subject, body, attachments);
      
      if (success) {
        _showSnackBar('Email envoyé avec succès !', Colors.green);
        // Actualiser la liste des emails
        await _loadEmails();
        await _loadSentEmails(); // Actualiser la liste des emails envoyés
      } else {
        _showSnackBar('Erreur lors de l\'envoi', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'envoi: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Supprimer un email (vraie suppression)
  void _deleteEmail(EmailMessage email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.surfaceColor,
        title: Text(
          'Supprimer l\'email',
          style: TextStyle(color: _themeService.textColor),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cet email ? Cette action est irréversible.',
          style: TextStyle(color: _themeService.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler', style: TextStyle(color: _themeService.subtitleColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteEmailFromServer(email);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Supprimer l'email du serveur (vraie suppression)
  Future<void> _deleteEmailFromServer(EmailMessage email) async {
    try {
      setState(() => _isLoading = true);
      
      // Suppression via Microsoft Graph API
      final success = await _outlookService.deleteEmail(email.id);
      
      if (success) {
        // Supprimer de la liste locale
        setState(() {
          if (_currentTab == EmailTab.received) {
            _emails.remove(email);
            if (_selectedEmail == email) {
              _selectedEmail = null;
              _showEmailDetail = false;
            }
          } else if (_currentTab == EmailTab.sent) {
            _sentEmails.remove(email);
            if (_selectedEmail == email) {
              _selectedEmail = null;
              _showEmailDetail = false;
            }
          } else { // _currentTab == EmailTab.spam
            _spamEmails.remove(email);
            if (_selectedEmail == email) {
              _selectedEmail = null;
              _showEmailDetail = false;
            }
          }
        });
        
        _showSnackBar('Email supprimé définitivement', Colors.green);
      } else {
        _showSnackBar('Erreur lors de la suppression', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la suppression: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Afficher les pièces jointes
  void _showAttachments(EmailMessage email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.surfaceColor,
        title: Row(
          children: [
            Icon(
              Icons.attach_file,
              color: _themeService.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Pièces jointes',
              style: TextStyle(
                color: _themeService.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email : ${email.subject}',
              style: TextStyle(
                color: _themeService.subtitleColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            if (email.hasAttachments) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _themeService.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      color: _themeService.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pièce jointe détectée',
                        style: TextStyle(
                          color: _themeService.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Aucune pièce jointe',
                style: TextStyle(
                  color: _themeService.subtitleColor,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(color: _themeService.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Afficher un SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Afficher le dialogue IA pour générer une réponse
  void _showAIReplyDialog(EmailMessage email) {
    final TextEditingController specificationsController = TextEditingController();
    bool isGenerating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _themeService.surfaceColor,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade400,
                        Colors.blue.shade400,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Répondre avec IA',
                    style: TextStyle(
                      color: _themeService.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email de: ${email.senderName}',
                  style: TextStyle(
                    color: _themeService.subtitleColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sujet: ${email.subject}',
                  style: TextStyle(
                    color: _themeService.subtitleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Spécifications pour la réponse',
                  style: TextStyle(
                    color: _themeService.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _themeService.isDarkMode 
                        ? Colors.grey[600]! 
                        : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: specificationsController,
                    maxLines: null,
                    enabled: !isGenerating,
                    decoration: InputDecoration(
                      hintText: 'Ex: Répondre poliment que je suis intéressé et proposer un rendez-vous...',
                      hintStyle: TextStyle(
                        color: _themeService.subtitleColor,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(
                      color: _themeService.textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isGenerating) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.purple.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Génération en cours...',
                        style: TextStyle(
                          color: _themeService.subtitleColor,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isGenerating ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: isGenerating 
                      ? _themeService.subtitleColor.withOpacity(0.5)
                      : _themeService.subtitleColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isGenerating ? null : () async {
                  if (specificationsController.text.trim().isEmpty) {
                    _showSnackBar(
                      'Veuillez entrer des spécifications',
                      Colors.orange,
                    );
                    return;
                  }

                  setDialogState(() => isGenerating = true);

                  try {
                    final aiResponse = await _generateAIReply(
                      email,
                      specificationsController.text.trim(),
                    );

                    Navigator.of(context).pop();

                    if (aiResponse != null) {
                      // Ouvrir le dialogue de réponse avec le contenu généré par l'IA
                      _replyToEmailWithAI(email, aiResponse);
                    } else {
                      _showSnackBar(
                        'Erreur lors de la génération de la réponse',
                        Colors.red,
                      );
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                    _showSnackBar('Erreur: $e', Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGenerating 
                    ? Colors.grey 
                    : Colors.purple.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 8),
                    Text(isGenerating ? 'Génération...' : 'Générer'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Générer une réponse avec l'IA Fireworks
  Future<String?> _generateAIReply(EmailMessage email, String specifications) async {
    try {
      // Charger la clé API depuis .env
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['FIREWORK_APIKEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        _showSnackBar('Clé API Fireworks non configurée', Colors.red);
        return null;
      }

      // Construire le prompt
      final prompt = '''Réponds à cet email :

De: ${email.senderName} <${email.senderEmail}>
Sujet: ${email.subject}
Date: ${_formatFullDate(email.receivedDateTime)}

Contenu de l'email:
${_stripHtmlTags(email.body)}

Spécifications pour la réponse:
$specifications

Génère uniquement le contenu de la réponse, sans formule de début ni de fin (pas de "Cher/Chère", pas de signature). Sois professionnel et concis.''';

      // Appel API Fireworks
      final response = await http.post(
        Uri.parse('https://api.fireworks.ai/inference/v1/chat/completions'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'accounts/fireworks/models/deepseek-v3p1-terminus',
          'max_tokens': 20480,
          'top_p': 1,
          'top_k': 40,
          'presence_penalty': 0,
          'frequency_penalty': 0,
          'temperature': 0.6,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        print('Erreur API Fireworks: ${response.statusCode} - ${response.body}');
        _showSnackBar(
          'Erreur API: ${response.statusCode}',
          Colors.red,
        );
        return null;
      }
    } catch (e) {
      print('Erreur lors de l\'appel à l\'IA: $e');
      return null;
    }
  }

  // Nettoyer les balises HTML d'un texte
  String _stripHtmlTags(String htmlString) {
    final exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  // Répondre à un email avec le contenu généré par l'IA
  void _replyToEmailWithAI(EmailMessage email, String aiGeneratedBody) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OutlookEmailDialogWithAI(
        themeService: _themeService,
        replyTo: email,
        aiGeneratedBody: aiGeneratedBody,
        outlookService: _outlookService,
        onSend: (to, subject, body, attachments) async {
          await _sendEmail(to, subject, body, attachments);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}