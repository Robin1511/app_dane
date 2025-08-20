import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxService {
  static String get _accessToken => dotenv.env['MAPBOX_SECRET_KEY'] ?? '';
  static const String _baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';

  static Future<List<MapboxSuggestion>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl/$encodedQuery.json?access_token=$_accessToken&limit=5&types=address,poi';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        return features.map((feature) => MapboxSuggestion.fromJson(feature)).toList();
      } else {
        print('Erreur Mapbox: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la recherche d\'adresse: $e');
      return [];
    }
  }
}

class MapboxSuggestion {
  final String placeName;
  final String? address;
  final List<double> coordinates;

  MapboxSuggestion({
    required this.placeName,
    this.address,
    required this.coordinates,
  });

  factory MapboxSuggestion.fromJson(Map<String, dynamic> json) {
    return MapboxSuggestion(
      placeName: json['place_name'] ?? '',
      address: json['properties']?['address'],
      coordinates: List<double>.from(json['center'] ?? [0.0, 0.0]),
    );
  }
} 