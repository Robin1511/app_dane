import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'isDarkMode';

  // Singleton
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool get isDarkMode => _isDarkMode;

  // Initialiser le thème depuis SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  // Toggle dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  // Couleurs du thème
  Color get primaryColor => _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA);
  Color get secondaryColor => _isDarkMode ? const Color(0xFFE91E63) : const Color(0xFF00C9FF);
  Color get backgroundColor => _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
  Color get surfaceColor => _isDarkMode ? Colors.grey[850]! : Colors.white;
  Color get textColor => _isDarkMode ? Colors.white : Colors.black;
  Color get subtitleColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;

  // Gradient du thème
  LinearGradient get primaryGradient => LinearGradient(
    colors: _isDarkMode 
      ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
      : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
  );
} 