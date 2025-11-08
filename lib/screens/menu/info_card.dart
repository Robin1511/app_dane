import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/theme_service.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.name,
    required this.bio,
  });

  final String name, bio;

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = ThemeService();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeService.isDarkMode
                ? [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ]
                : [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeService.isDarkMode
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeService.isDarkMode
                      ? [
                          const Color(0xFF4ECDC4).withOpacity(0.3),
                          const Color(0xFF44A8F0).withOpacity(0.3),
                        ]
                      : [
                          const Color(0xFF4ECDC4).withOpacity(0.2),
                          const Color(0xFF44A8F0).withOpacity(0.2),
                        ],
                ),
              ),
              child: Icon(
                CupertinoIcons.person,
                color: themeService.isDarkMode ? Colors.white : Colors.black87,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: themeService.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bio,
                    style: TextStyle(
                      color: themeService.isDarkMode 
                          ? Colors.white70 
                          : Colors.black54,
                      fontSize: 13,
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
}
