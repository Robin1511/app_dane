import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_links/app_links.dart';

class OutlookService {
  // Configuration OAuth2 pour Microsoft Graph
  // ⚠️ POUR PRODUCTION : Remplacez par votre vrai Client ID d'Azure Portal
  static String get clientId {
    final envClientId = dotenv.env['AZURE_CLIENT_ID'];
    if (envClientId == null || envClientId.isEmpty) {
      print('⚠️ AZURE_CLIENT_ID non configuré dans .env - Mode démo activé');
      return '';
    }
    return envClientId;
  }
  static const String redirectUri = kIsWeb 
    ? 'http://localhost:3000' // Pour le web
    : 'appdane://oauth'; // Pour mobile
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
      // Vérifier la configuration
      if (clientId.isEmpty) {
        print('🔧 MODE DÉMO ACTIVÉ - AZURE_CLIENT_ID non configuré');
        print('📝 Pour une vraie connexion Outlook :');
        print('   1. Créez un fichier .env à la racine du projet');
        print('   2. Ajoutez : AZURE_CLIENT_ID=votre_client_id_ici');
        print('   3. Allez sur https://portal.azure.com');
        print('   4. Créez une "App Registration"');
        print('   5. Configurez les permissions Microsoft Graph');
        
        await _simulateAuthentication();
        return true;
      }

      print('🔐 Tentative d\'authentification OAuth2 avec Microsoft Graph...');
      
      // Vérifier s'il y a déjà un token sauvegardé
      await _loadStoredTokens();
      if (_accessToken != null) {
        print('🔄 Token existant détecté, validation en cours...');
        // Valider le token existant
        if (await _validateToken()) {
          print('✅ Token valide, authentification réussie !');
          _demoMode = false;
          return true;
        } else {
          print('❌ Token expiré, nouvelle authentification requise');
        }
      }

      // Nouvelle authentification
      print('🚀 Lancement de l\'authentification OAuth2...');
      _demoMode = false;
      final authUrl = Uri.parse(
        '$authorizeUrl?client_id=$clientId&response_type=code&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=${Uri.encodeComponent(scope)}&response_mode=query'
      );

      if (await canLaunchUrl(authUrl)) {
        print('🌐 Ouverture du navigateur pour l\'authentification...');
        
        // Capturer la redirection OAuth2
        final appLinks = AppLinks();
        String? authCode;
        
        // Écouter la redirection
        final subscription = appLinks.uriLinkStream.listen((Uri? uri) {
          if (uri != null && uri.scheme == 'appdane' && uri.host == 'oauth') {
            authCode = uri.queryParameters['code'];
            print('🔗 Code d\'autorisation reçu: $authCode');
          }
        });
        
        // Ouvrir le navigateur
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        
        // Attendre le code d'autorisation (timeout de 60 secondes)
        int attempts = 0;
        while (authCode == null && attempts < 60) {
          await Future.delayed(const Duration(seconds: 1));
          attempts++;
        }
        
        // Arrêter l'écoute
        subscription.cancel();
        
        if (authCode != null) {
          print('✅ Code d\'autorisation capturé, échange contre un token...');
          // Échanger le code contre un token
          final success = await _exchangeCodeForToken(authCode!);
          if (success) {
            print('🎉 Authentification OAuth2 réussie !');
            _demoMode = false;
            return true;
          }
        }
        
        print('⚠️ Redirection non capturée, basculement en mode démo');
        await _simulateAuthentication();
        return true;
      } else {
        print('❌ Impossible d\'ouvrir l\'URL d\'authentification');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'authentification: $e');
      print('🔄 Basculement automatique en mode démo');
      // En cas d'erreur, basculer en mode démo
      await _simulateAuthentication();
      return true;
    }
  }

  // Simulation d'authentification pour la démo
  Future<void> _simulateAuthentication() async {
    print('🎭 Simulation de l\'authentification en cours...');
    _demoMode = true;
    _accessToken = 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}';
    _refreshToken = 'demo_refresh_token';
    await _saveTokens();
    print('✅ Mode démo activé avec succès !');
    print('📧 Vous pouvez maintenant utiliser toutes les fonctionnalités avec des données simulées');
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

  // Échanger le code d'autorisation contre un token
  Future<bool> _exchangeCodeForToken(String authCode) async {
    try {
      print('🔄 Échange du code d\'autorisation contre un token...');
      
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': clientId,
          'code': authCode,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        
        if (_accessToken != null) {
          await _saveTokens();
          print('✅ Token d\'accès obtenu avec succès !');
          return true;
        }
      }
      
      print('❌ Échec de l\'échange du code: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('❌ Erreur lors de l\'échange du code: $e');
      return false;
    }
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

  // Obtenir les emails envoyés
  Future<List<EmailMessage>> getSentEmails({int top = 20}) async {
    if (!isLoggedIn) return [];

    try {
      // En mode démo, retourner des emails simulés
      if (_demoMode) {
        return _getDemoSentEmails();
      }

      final response = await http.get(
        Uri.parse('$graphApiUrl/me/mailFolders/SentItems/messages?\$top=$top&\$orderby=sentDateTime desc'),
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
          sender: msg['from']?['emailAddress']?['name'] ?? 'Moi',
          senderEmail: msg['from']?['emailAddress']?['address'] ?? '',
          body: msg['body']?['content'] ?? '',
          bodyPreview: msg['bodyPreview'] ?? '',
          receivedDateTime: DateTime.tryParse(msg['sentDateTime'] ?? msg['receivedDateTime'] ?? '') ?? DateTime.now(),
          isRead: true,
          hasAttachments: msg['hasAttachments'] ?? false,
          importance: msg['importance'] ?? 'normal',
        )).toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération des emails envoyés: $e');
    }
    return [];
  }



  // Déconnexion
  Future<void> logout() async {
    print('🚪 Déconnexion en cours...');
    _accessToken = null;
    _refreshToken = null;
    _demoMode = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('outlook_access_token');
    await prefs.remove('outlook_refresh_token');
    await prefs.remove('outlook_demo_mode');
    
    print('✅ Déconnexion réussie !');
    print('🔄 Retour au mode démo');
  }

  // Envoyer un email via Microsoft Graph API
  Future<bool> sendEmail(String to, String subject, String body, List<dynamic> attachments) async {
    if (_demoMode) {
      print('🎭 Mode démo : Simulation d\'envoi d\'email');
      await Future.delayed(const Duration(seconds: 2));
      return true;
    }

    try {
      print('📧 Envoi d\'email via Microsoft Graph API...');
      
      // Préparer le message
      final message = {
        'subject': subject,
        'body': {
          'contentType': 'HTML',
          'content': body,
        },
        'toRecipients': [
          {
            'emailAddress': {
              'address': to,
            },
          },
        ],
      };

      // Ajouter les pièces jointes si présentes
      if (attachments.isNotEmpty) {
        final attachmentList = <Map<String, dynamic>>[];
        
        for (final attachment in attachments) {
          if (attachment is PlatformFile) {
            // TODO: Implémenter l'upload des pièces jointes
            // Pour l'instant, on ajoute juste les métadonnées
            attachmentList.add({
              '@odata.type': '#microsoft.graph.fileAttachment',
              'name': attachment.name,
              'contentType': 'application/octet-stream',
              'contentBytes': '', // TODO: Encoder le contenu du fichier
            });
          }
        }
        
        if (attachmentList.isNotEmpty) {
          message['attachments'] = attachmentList;
        }
      }

      final response = await http.post(
        Uri.parse('$graphApiUrl/me/sendMail'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message,
          'saveToSentItems': true,
        }),
      );

      if (response.statusCode == 202) {
        print('✅ Email envoyé avec succès !');
        return true;
      } else {
        print('❌ Erreur lors de l\'envoi: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi: $e');
      return false;
    }
  }

  // Supprimer un email via Microsoft Graph API
  Future<bool> deleteEmail(String emailId) async {
    if (_demoMode) {
      print('🎭 Mode démo : Simulation de suppression d\'email');
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      print('🗑️ Suppression d\'email via Microsoft Graph API...');
      
      final response = await http.delete(
        Uri.parse('$graphApiUrl/me/messages/$emailId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        print('✅ Email supprimé avec succès !');
        return true;
      } else {
        print('❌ Erreur lors de la suppression: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
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

  // Emails envoyés de démonstration
  List<EmailMessage> _getDemoSentEmails() {
    final now = DateTime.now();
    return [
      EmailMessage(
        id: 'sent1',
        subject: 'Réponse : Confirmation réunion demain',
        sender: 'Moi',
        senderEmail: 'moi@example.com',
        body: '<p>Bonjour Marie,<br><br>Parfait, je confirme ma présence à la réunion de demain à 14h.<br><br>J\'ai bien noté l\'ordre du jour et je viens avec mes questions.<br><br>Cordialement,<br>Moi</p>',
        bodyPreview: 'Bonjour Marie, Parfait, je confirme ma présence à la réunion de demain à 14h. J\'ai bien noté l\'ordre du jour et je viens avec mes questions.',
        receivedDateTime: now.subtract(const Duration(hours: 1)),
        isRead: true,
        hasAttachments: false,
        importance: 'normal',
      ),
      EmailMessage(
        id: 'sent2',
        subject: 'Demande d\'information projet',
        sender: 'Moi',
        senderEmail: 'moi@example.com',
        body: '<p>Bonjour,<br><br>Je souhaiterais obtenir plus d\'informations sur votre projet.<br><br>Pourriez-vous me faire parvenir la documentation technique ?<br><br>Merci d\'avance,<br>Moi</p>',
        bodyPreview: 'Bonjour, Je souhaiterais obtenir plus d\'informations sur votre projet. Pourriez-vous me faire parvenir la documentation technique ?',
        receivedDateTime: now.subtract(const Duration(days: 1)),
        isRead: true,
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