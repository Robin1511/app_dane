import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/theme_service.dart';
import 'entry_point.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ThemeService _themeService = ThemeService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;

  // Lieux d'intérêt à afficher
  final List<Map<String, dynamic>> _locations = [
    {
      'name': "Tour Eiffel",
      'description': "Monument emblématique de Paris",
      'lat': 48.8584,
      'lng': 2.2945,
      'type': 'monument',
    },
    {
      'name': "Louvre",
      'description': "Musée d'art et ancien palais royal",
      'lat': 48.8606,
      'lng': 2.3376,
      'type': 'museum',
    },
    {
      'name': "Notre-Dame",
      'description': "Cathédrale gothique historique",
      'lat': 48.8530,
      'lng': 2.3499,
      'type': 'monument',
    },
    {
      'name': "Sacré-Cœur",
      'description': "Basilique sur la butte Montmartre",
      'lat': 48.8867,
      'lng': 2.3431,
      'type': 'monument',
    },
    {
      'name': "Arc de Triomphe",
      'description': "Monument commémoratif",
      'lat': 48.8738,
      'lng': 2.2950,
      'type': 'monument',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
    _initializeMap();
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

  void _initializeMap() {
    // Simulation du chargement
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sur web, afficher un message d'information
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: _themeService.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const EntryPoint()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _themeService.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: _themeService.textColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Carte',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _themeService.textColor,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 80,
                color: _themeService.textColor.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Carte non disponible sur le web',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _themeService.textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cette fonctionnalité est disponible uniquement\nsur les appareils mobiles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _themeService.textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const EntryPoint()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeService.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Retour au tableau de bord',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _themeService.backgroundColor,
      appBar: AppBar(
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
            Text(
              'Carte',
              style: TextStyle(
                color: _themeService.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                _themeService.toggleTheme();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _themeService.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (kIsWeb) {
      return _buildWebMapPlaceholder();
    } else {
      return _buildMapContent();
    }
  }

  Widget _buildWebMapPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _themeService.isDarkMode 
            ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
            : [const Color(0xFFF8F9FA), Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _themeService.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.map,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Carte Interactive',
              style: TextStyle(
                color: _themeService.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Testez sur un émulateur mobile pour voir la carte complète',
                style: TextStyle(
                  color: _themeService.subtitleColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMapContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        MapWidget(
          key: ValueKey("mapWidget"),
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(2.3522, 48.8566)), // Paris
            zoom: 10.0,
          ),
          styleUri: "mapbox://styles/robin-debastos/cm2t13lti00es01pmcjhf7a93",
          onMapCreated: (MapboxMap mapboxMap) {
            print("Carte Mapbox chargée avec le style personnalisé !");
          },
        ),
        _buildFloatingButtons(),
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
            'Chargement de la carte...',
            style: TextStyle(
              color: _themeService.textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapGridLine(int index) {
    return Positioned(
      left: (index % 10) * 60.0,
      top: (index ~/ 10) * 80.0,
      child: Container(
        width: 1,
        height: 400,
        color: _themeService.isDarkMode 
          ? Colors.white.withOpacity(0.1)
          : Colors.green.withOpacity(0.2),
      ),
    );
  }

  Widget _buildMapMarker(Map<String, dynamic> location) {
    // Position simulée sur l'écran
    double screenX = 100.0 + (location['lng'] - 2.2) * 200.0;
    double screenY = 200.0 + (48.9 - location['lat']) * 300.0;
    
    return Positioned(
      left: screenX,
      top: screenY,
      child: GestureDetector(
        onTap: () {
          _showLocationInfo(location);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _themeService.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            location['type'] == 'museum' ? Icons.museum : Icons.location_city,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  void _showLocationInfo(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themeService.isDarkMode ? const Color(0xFF2D2D44) : Colors.white,
        title: Text(
          location['name'],
          style: TextStyle(color: _themeService.textColor),
        ),
        content: Text(
          location['description'],
          style: TextStyle(color: _themeService.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: _themeService.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "zoom_in",
            mini: true,
            backgroundColor: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
            onPressed: () {
              // Zoom in functionality
            },
            child: Icon(
              Icons.add,
              color: _themeService.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            backgroundColor: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
            onPressed: () {
              // Zoom out functionality
            },
            child: Icon(
              Icons.remove,
              color: _themeService.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "my_location",
            mini: true,
            backgroundColor: _themeService.isDarkMode ? Colors.grey[800] : Colors.white,
            onPressed: () {
              // My location functionality
            },
            child: Icon(
              Icons.my_location,
              color: _themeService.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 