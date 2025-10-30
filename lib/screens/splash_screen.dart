import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async';
import 'login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SMITrigger? _trigger;
  Artboard? _artboard;
  
  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() {
    // Charger le fichier Rive
    RiveFile.asset('assets/intro2.riv').then(
      (data) {
        final artboard = data.mainArtboard;
        var controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
        
        if (controller != null) {
          artboard.addController(controller);
          _trigger = controller.findSMI('Trigger 1');
        }
        
        setState(() => _artboard = artboard);
        
        // Démarrer l'animation automatiquement
        _trigger?.fire();
        
        // Naviguer vers le dashboard après 4 secondes
        Timer(const Duration(seconds: 4), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                transitionDuration: const Duration(milliseconds: 800),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
              ),
            );
          }
        });
      },
    ).catchError((error) {
      // Si le fichier Rive ne peut pas être chargé, afficher un splash simple
      print('Erreur lors du chargement du fichier Rive: $error');
      _showFallbackSplash();
    });
  }
  
  void _showFallbackSplash() {
    // Splash de secours si le fichier Rive ne fonctionne pas
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black,
        child: Center(
          child: _artboard == null 
            ? _buildFallbackContent()
            : SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Rive(
                  artboard: _artboard!,
                  fit: BoxFit.cover,
                ),
              ),
        ),
      ),
    );
  }
  
  Widget _buildFallbackContent() {
    return Container();
  }
} 