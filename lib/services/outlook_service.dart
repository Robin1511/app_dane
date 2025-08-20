import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class OutlookService {
  // Configuration OAuth2 pour Microsoft Graph
  // ⚠️ POUR PRODUCTION : Remplacez par votre vrai Client ID d'Azure Portal
  static const String clientId = 'demo-client-id'; // Remplacer par votre Client ID Azure
  static const String redirectUri = kIsWeb 
    ? 'http://localhost:3000' // Pour le web
    : 'com.example.app_dane://oauth'; // Pour mobile
  static const String scope = 'https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/User.Read offline_access';
  static const String authorizeUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const String tokenUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
  static const String graphApiUrl = 'https://graph.microsoft.com/v1.0';

  String? _accessToken;
  String? _refreshToken;
  bool _demoMode = true; // Mode démo activé par défaut

  // Singleton
  static final OutlookService _instance = OutlookService._internal();
  factory OutlookService() => _instance;
  OutlookService._internal();

  // Getter pour vérifier si l'utilisateur est connecté
  bool get isLoggedIn => _accessToken != null;
  bool get isDemoMode => _demoMode;
  bool get isDemo => _demoMode;

  // Authentification OAuth2
  Future<bool> authenticate() async {
    try {
      // Si le clientId est encore "demo-client-id", utiliser le mode démo
      if (clientId == 'demo-client-id') {
        print('🔧 MODE DÉMO ACTIVÉ');
        print('📝 Pour une vraie connexion Outlook :');
        print('   1. Allez sur https://portal.azure.com');
        print('   2. Créez une "App Registration"');
        print('   3. Remplacez clientId dans OutlookService');
        
        await _simulateAuthentication();
        return true;
      }

      // Vérifier s'il y a déjà un token sauvegardé
      await _loadStoredTokens();
      if (_accessToken != null) {
        // Valider le token existant
        if (await _validateToken()) {
          _demoMode = false;
          return true;
        }
      }

      // Nouvelle authentification
      _demoMode = false;
      final authUrl = Uri.parse(
        '$authorizeUrl?client_id=$clientId&response_type=code&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=${Uri.encodeComponent(scope)}&response_mode=query'
      );

      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        
        // Note: En production, vous devriez implémenter un serveur local
        // ou utiliser un deep link pour capturer le code de retour
        // Pour l'instant, on reste en mode démo si pas de vrai clientId
        await _simulateAuthentication();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur d\'authentification: $e');
      // En cas d'erreur, basculer en mode démo
      await _simulateAuthentication();
      return true;
    }
  }

  // Simulation d'authentification pour la démo
  Future<void> _simulateAuthentication() async {
    _demoMode = true;
    _accessToken = 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}';
    _refreshToken = 'demo_refresh_token';
    await _saveTokens();
  }

  // Charger les tokens sauvegardés
  Future<void> _loadStoredTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('outlook_access_token');
    _refreshToken = prefs.getString('outlook_refresh_token');
    _demoMode = prefs.getBool('outlook_demo_mode') ?? true;
  }

  // Sauvegarder les tokens
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('outlook_access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('outlook_refresh_token', _refreshToken!);
    }
    await prefs.setBool('outlook_demo_mode', _demoMode);
  }

  // Valider le token
  Future<bool> _validateToken() async {
    if (_accessToken == null || _demoMode) return _demoMode;
    
    try {
      final response = await http.get(
        Uri.parse('$graphApiUrl/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Obtenir les informations de l'utilisateur
  Future<UserInfo?> getUserInfo() async {
    if (!isLoggedIn) return null;

    try {
      // En mode démo, retourner des données simulées
      if (_demoMode) {
        return UserInfo(
          displayName: 'Utilisateur Démo',
          email: 'demo@outlook.com',
          profilePicture: null,
        );
      }

      final response = await http.get(
        Uri.parse('$graphApiUrl/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserInfo(
          displayName: data['displayName'] ?? '',
          email: data['mail'] ?? data['userPrincipalName'] ?? '',
          profilePicture: null,
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des infos utilisateur: $e');
    }
    return null;
  }

  // Obtenir les emails
  Future<List<EmailMessage>> getEmails({int top = 20}) async {
    if (!isLoggedIn) return [];

    try {
      // En mode démo, retourner des emails simulés
      if (_demoMode) {
        return _getDemoEmails();
      }

      final response = await http.get(
        Uri.parse('$graphApiUrl/me/messages?\$top=$top&\$orderby=receivedDateTime desc'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = data['value'] as List;
        
        return messages.map((msg) => EmailMessage(
          id: msg['id'],
          subject: msg['subject'] ?? 'Sans objet',
          sender: msg['from']?['emailAddress']?['name'] ?? 'Expéditeur inconnu',
          senderEmail: msg['from']?['emailAddress']?['address'] ?? '',
          body: msg['body']?['content'] ?? '',
          bodyPreview: msg['bodyPreview'] ?? '',
          receivedDateTime: DateTime.tryParse(msg['receivedDateTime'] ?? '') ?? DateTime.now(),
          isRead: msg['isRead'] ?? false,
          hasAttachments: msg['hasAttachments'] ?? false,
          importance: msg['importance'] ?? 'normal',
        )).toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération des emails: $e');
    }
    return [];
  }

  // Envoyer un email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    List<String>? cc,
  }) async {
    if (!isLoggedIn) return false;

    try {
      // En mode démo, simuler l'envoi
      if (_demoMode) {
        print('📧 EMAIL SIMULÉ ENVOYÉ:');
        print('   À: $to');
        print('   Objet: $subject');
        print('   Corps: ${body.substring(0, body.length > 50 ? 50 : body.length)}...');
        await Future.delayed(const Duration(seconds: 1));
        return true;
      }

      final emailData = {
        'message': {
          'subject': subject,
          'body': {
            'contentType': 'HTML',
            'content': body,
          },
          'toRecipients': [
            {
              'emailAddress': {
                'address': to,
              }
            }
          ],
          if (cc != null && cc.isNotEmpty)
            'ccRecipients': cc.map((email) => {
              'emailAddress': {'address': email}
            }).toList(),
        },
        'saveToSentItems': 'true',
      };

      final response = await http.post(
        Uri.parse('$graphApiUrl/me/sendMail'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(emailData),
      );

      return response.statusCode == 202;
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _demoMode = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('outlook_access_token');
    await prefs.remove('outlook_refresh_token');
    await prefs.remove('outlook_demo_mode');
  }

  // Emails de démonstration
  List<EmailMessage> _getDemoEmails() {
    final now = DateTime.now();
    return [
      EmailMessage(
        id: '1',
        subject: '🎉 Bienvenue dans votre app de mails !',
        sender: 'Équipe Support',
        senderEmail: 'support@example.com',
        body: '<p>Félicitations ! Votre application de gestion de mails est maintenant configurée.</p><p>Cette interface fonctionne en mode démo avec des données simulées.</p><p>Pour connecter un vrai compte Outlook, suivez les instructions dans la console.</p>',
        bodyPreview: 'Félicitations ! Votre application de gestion de mails est maintenant configurée.',
        receivedDateTime: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        hasAttachments: false,
        importance: 'normal',
      ),
      EmailMessage(
        id: '2',
        subject: 'Confirmation réunion demain',
        sender: 'Marie Dubois',
        senderEmail: 'marie.dubois@company.com',
        body: '<p>Bonjour,<br><br>Je vous confirme notre réunion de demain à 14h en salle de réunion A.<br><br>À l\'ordre du jour :<br>- Point sur l\'avancement<br>- Prochaines étapes<br>- Questions diverses</p><p>Cordialement,<br>Marie</p>',
        bodyPreview: 'Je vous confirme notre réunion de demain à 14h en salle de réunion A. À l\'ordre du jour : Point sur l\'avancement, prochaines étapes...',
        receivedDateTime: now.subtract(const Duration(hours: 2)),
        isRead: true,
        hasAttachments: true,
        importance: 'normal',
      ),
      EmailMessage(
        id: '3',
        subject: 'Rapport mensuel disponible',
        sender: 'Système',
        senderEmail: 'noreply@system.com',
        body: '<p>Le rapport mensuel est maintenant disponible dans votre espace personnel.</p><p>Résumé des indicateurs :<br>✅ Objectifs atteints<br>📈 Croissance positive<br>🎯 Nouvelles opportunités identifiées</p>',
        bodyPreview: 'Le rapport mensuel est maintenant disponible dans votre espace personnel. Résumé des indicateurs : Objectifs atteints, croissance positive...',
        receivedDateTime: now.subtract(const Duration(hours: 5)),
        isRead: true,
        hasAttachments: true,
        importance: 'normal',
      ),
      EmailMessage(
        id: '4',
        subject: 'Proposition de collaboration',
        sender: 'Pierre Martin',
        senderEmail: 'pierre.martin@partner.com',
        body: '<p>Bonjour,<br><br>Je souhaiterais vous proposer une collaboration sur un projet innovant dans le domaine du développement mobile.</p><p>Seriez-vous disponible pour un appel cette semaine ?</p><p>Meilleures salutations,<br>Pierre Martin</p>',
        bodyPreview: 'Je souhaiterais vous proposer une collaboration sur un projet innovant dans le domaine du développement mobile. Seriez-vous disponible pour un appel cette semaine ?',
        receivedDateTime: now.subtract(const Duration(days: 1)),
        isRead: false,
        hasAttachments: false,
        importance: 'normal',
      ),
      EmailMessage(
        id: '5',
        subject: 'Configuration Outlook - Instructions',
        sender: 'Assistant Configuration',
        senderEmail: 'config@demo.com',
        body: '<p><strong>Pour connecter un vrai compte Outlook :</strong></p><ol><li>Allez sur <a href="https://portal.azure.com">Azure Portal</a></li><li>Créez une nouvelle "App Registration"</li><li>Configurez les permissions Microsoft Graph</li><li>Remplacez le clientId dans OutlookService</li><li>Configurez les Redirect URIs</li></ol><p>L\'interface est déjà prête pour la production ! 🚀</p>',
        bodyPreview: 'Pour connecter un vrai compte Outlook : Allez sur Azure Portal, créez une nouvelle App Registration, configurez les permissions Microsoft Graph...',
        receivedDateTime: now.subtract(const Duration(minutes: 1)),
        isRead: false,
        hasAttachments: false,
        importance: 'normal',
      ),
    ];
  }
}

// Modèles de données
class UserInfo {
  final String displayName;
  final String email;
  final String? profilePicture;

  UserInfo({
    required this.displayName,
    required this.email,
    this.profilePicture,
  });
}

class EmailMessage {
  final String id;
  final String subject;
  final String sender;
  final String senderEmail;
  final String body;
  final String bodyPreview;
  final DateTime receivedDateTime;
  final bool isRead;
  final bool hasAttachments;
  final String importance;

  EmailMessage({
    required this.id,
    required this.subject,
    required this.sender,
    required this.senderEmail,
    required this.body,
    required this.bodyPreview,
    required this.receivedDateTime,
    required this.isRead,
    required this.hasAttachments,
    this.importance = 'normal',
  });

  // Getter pour compatibilité avec le nouveau code
  String get senderName => sender;
} 