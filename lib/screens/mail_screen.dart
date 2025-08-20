import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/outlook_service.dart';
import 'main_dashboard.dart';

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

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isLoading = true);
    
    _isLoggedIn = _outlookService.isLoggedIn;
    if (_isLoggedIn) {
      await _loadUserInfo();
      await _loadEmails();
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

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final success = await _outlookService.authenticate();
    if (success) {
      await _loadUserInfo();
      await _loadEmails();
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
      _selectedEmail = null;
      _showEmailDetail = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
                child: _buildEmailList(),
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
            : _buildEmailList();
        }
      },
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
                  'Boîte de réception',
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
                    '${_emails.length}',
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
            child: _emails.isEmpty
              ? _buildEmptyEmailList()
              : ListView.builder(
                  itemCount: _emails.length,
                  itemBuilder: (context, index) {
                    final email = _emails[index];
                    final isSelected = _selectedEmail?.id == email.id;
                    
                    return _buildEmailItem(email, isSelected);
                  },
                ),
          ),
        ],
      ),
    );
  }

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
                          Text(
                            _formatDate(email.receivedDateTime),
                            style: TextStyle(
                              color: _themeService.subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Indicateurs
                    Column(
                      children: [
                        if (email.hasAttachments)
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: _themeService.subtitleColor,
                          ),
                        if (email.importance == 'high')
                          const Icon(
                            Icons.priority_high,
                            size: 16,
                            color: Colors.red,
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
                  onPressed: () {
                    _showSnackBar('Fonctionnalité de réponse en développement', Colors.blue);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showSnackBar('Email supprimé', Colors.green);
                    _closeEmailDetail();
                  },
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
                    child: Text(
                      _selectedEmail!.body,
                      style: TextStyle(
                        color: _themeService.textColor,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
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
} 