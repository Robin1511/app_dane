import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/outlook_service.dart';
import 'main_dashboard.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:flutter_html/flutter_html.dart'; // Désactivé temporairement
import 'package:url_launcher/url_launcher.dart';

// Types de dialogue email
enum EmailDialogType { compose, reply }

// Types d'onglets email
enum EmailTab { received, sent }

// Composant de dialogue email style Outlook moderne
class _OutlookEmailDialog extends StatefulWidget {
  final ThemeService themeService;
  final EmailDialogType type;
  final EmailMessage? replyTo;
  final Function(String to, String subject, String body, List<PlatformFile> attachments) onSend;

  const _OutlookEmailDialog({
    super.key,
    required this.themeService,
    required this.type,
    this.replyTo,
    required this.onSend,
  });

  @override
  State<_OutlookEmailDialog> createState() => _OutlookEmailDialogState();
}

class _OutlookEmailDialogState extends State<_OutlookEmailDialog> {
  late TextEditingController _toController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  final List<PlatformFile> _attachments = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(
      text: widget.replyTo?.senderEmail ?? '',
    );
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
  }

  @override
  void dispose() {
    _toController.dispose();
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
                    // Champ À
                    _buildInputField(
                      controller: _toController,
                      label: 'À',
                      icon: Icons.person,
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
                                                         ...(_attachments.asMap().entries.map((entry) {
                               final index = entry.key;
                               final attachment = entry.value;
                               return Container(
                                 margin: const EdgeInsets.only(bottom: 4),
                                 padding: const EdgeInsets.symmetric(
                                   horizontal: 8,
                                   vertical: 4,
                                 ),
                                 decoration: BoxDecoration(
                                   color: widget.themeService.backgroundColor,
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 child: Row(
                                   children: [
                                     Icon(
                                       _getFileIcon(attachment.extension ?? ''),
                                       size: 16,
                                       color: widget.themeService.primaryColor,
                                     ),
                                     const SizedBox(width: 8),
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Text(
                                             attachment.name,
                                             style: TextStyle(
                                               color: widget.themeService.textColor,
                                               fontWeight: FontWeight.w500,
                                             ),
                                           ),
                                           Text(
                                             '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                                             style: TextStyle(
                                               color: widget.themeService.subtitleColor,
                                               fontSize: 12,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                     IconButton(
                                       onPressed: () => _removeAttachment(index),
                                       icon: const Icon(Icons.close, size: 16),
                                       padding: EdgeInsets.zero,
                                       constraints: const BoxConstraints(
                                         minWidth: 24,
                                         minHeight: 24,
                                       ),
                                     ),
                                   ],
                                 ),
                               );
                             })),
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

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
    _checkLoginStatus();
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

  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);
    
    _isLoggedIn = _outlookService.isLoggedIn;
    if (_isLoggedIn) {
      await _loadUserInfo();
      await _loadEmails();
      await _loadSentEmails(); // Charger les emails envoyés
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserInfo() async {
    _userInfo = await _outlookService.getUserInfo();
  }

  Future<void> _loadEmails() async {
    final emails = await _outlookService.getEmails();
    setState(() => _emails = emails);
  }

  Future<void> _loadSentEmails() async {
    final sentEmails = await _outlookService.getSentEmails();
    setState(() => _sentEmails = sentEmails);
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
        // Onglets pour séparer reçus/envoyés
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
                  _currentTab == EmailTab.received ? 'Boîte de réception' : 'Emails envoyés',
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
                    _currentTab == EmailTab.received ? '${_emails.length}' : '${_sentEmails.length}',
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
                      itemCount: _emails.length,
                      itemBuilder: (context, index) {
                        final email = _emails[index];
                        final isSelected = _selectedEmail?.id == email.id;
                        
                        return _buildEmailItem(email, isSelected);
                      },
                    ))
              : (_sentEmails.isEmpty
                  ? _buildEmptySentEmailList()
                  : ListView.builder(
                      itemCount: _sentEmails.length,
                      itemBuilder: (context, index) {
                        final email = _sentEmails[index];
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
                            email.senderName,
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
                
                // Sujet
                Text(
                  email.subject,
                  style: TextStyle(
                    color: _themeService.textColor,
                    fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Aperçu du contenu
                Text(
                  email.bodyPreview,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de l'email
                  Row(
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
                              _selectedEmail!.senderName,
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Contenu de l'email
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _themeService.isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildEmailBody(_selectedEmail!.body),
                  ),
                ],
              ),
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
                        MaterialPageRoute(builder: (context) => const MainDashboard()),
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

    // Debug: afficher la longueur du body
    print('🔍 DEBUG: Body length: ${body.length}');
    print('🔍 DEBUG: Body preview: ${body.substring(0, body.length > 100 ? 100 : body.length)}');

        // Rendu HTML intelligent et stable
    return _buildSmartHtmlBody(body);
  }

  // Méthode de rendu HTML intelligent et stable
  Widget _buildSmartHtmlBody(String body) {
    // Nettoyer le HTML pour un affichage propre
    final cleanBody = _cleanHtmlForDisplay(body);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeService.isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _themeService.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: SelectableText(
        cleanBody,
        style: TextStyle(
          color: _themeService.textColor,
          fontSize: 14,
          height: 1.6,
          fontFamily: 'Calibri, Helvetica, sans-serif',
        ),
      ),
    );
  }

  // Nettoyer le HTML pour un affichage lisible
  String _cleanHtmlForDisplay(String html) {
    if (html.isEmpty) return 'Aucun contenu';
    
    // Supprimer les balises HTML tout en préservant le contenu
    String clean = html
        .replaceAll(RegExp(r'<head[^>]*>.*?</head>', dotAll: true), '') // Supprimer <head>
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '') // Supprimer <style>
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '') // Supprimer <script>
        .replaceAll(RegExp(r'<[^>]+>'), '') // Supprimer toutes les autres balises
        .replaceAll('&nbsp;', ' ') // Remplacer &nbsp; par espace
        .replaceAll('&amp;', '&') // Remplacer &amp; par &
        .replaceAll('&lt;', '<') // Remplacer &lt; par <
        .replaceAll('&gt;', '>') // Remplacer &gt; par >
        .replaceAll('&quot;', '"') // Remplacer &quot; par "
        .replaceAll('&#39;', "'") // Remplacer &#39; par '
        .trim();
    
    // Supprimer les lignes vides multiples
    clean = clean.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    
    return clean.isEmpty ? 'Aucun contenu textuel' : clean;
  }

  // Afficher le dialogue de nouveau mail
  void _showNewEmailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OutlookEmailDialog(
        themeService: _themeService,
        type: EmailDialogType.compose,
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
          } else { // _currentTab == EmailTab.sent
            _sentEmails.remove(email);
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
}