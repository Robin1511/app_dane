import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import 'main_dashboard.dart';

class CalendarScreen extends StatefulWidget {
  final bool isDarkMode;

  const CalendarScreen({super.key, this.isDarkMode = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isDarkMode = false;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _initializeEvents();
  }

  void _initializeEvents() {
    // Quelques événements d'exemple
    final today = DateTime.now();
    _events = {
      DateTime(today.year, today.month, today.day): [
        CalendarEvent("Réunion équipe", "10:00", Colors.blue),
        CalendarEvent("Présentation projet", "15:30", Colors.orange),
      ],
      DateTime(today.year, today.month, today.day + 1): [
        CalendarEvent("Formation", "09:00", Colors.green),
      ],
      DateTime(today.year, today.month, today.day + 3): [
        CalendarEvent("Deadline projet", "17:00", Colors.red),
      ],
    };
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calendrier',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Bouton Home pour retourner au dashboard
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.home_rounded,
                color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFFE91E63),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainDashboard()),
                  (Route<dynamic> route) => false,
                );
              },
              tooltip: 'Retour au dashboard',
            ),
          ),
          // Bouton toggle dark mode
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: _isDarkMode 
                  ? const Color(0xFF9C27B0) 
                  : const Color(0xFFE91E63),
              ),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
              tooltip: _isDarkMode ? 'Mode clair' : 'Mode sombre',
            ),
          ),
          SettingsButton(
            isDarkMode: _isDarkMode,
            onPressed: () {
              // TODO: Ajouter sidebar si nécessaire
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête du mois
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDarkMode 
                  ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                  : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                    });
                  },
                ),
                Text(
                  _getMonthYear(_focusedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() {
                      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Calendrier
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // En-têtes des jours
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di']
                          .map((day) => Text(
                                day,
                                style: TextStyle(
                                  color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  // Grille du calendrier
                  Expanded(
                    child: _buildCalendarGrid(),
                  ),
                ],
              ),
            ),
          ),
          
          // Liste des événements du jour sélectionné
          if (_getEventsForDay(_selectedDate).isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Événements du ${_selectedDate.day}/${_selectedDate.month}',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._getEventsForDay(_selectedDate).map((event) => _buildEventCard(event)),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + firstDayWeekday - 1,
      itemBuilder: (context, index) {
        if (index < firstDayWeekday - 1) {
          return Container(); // Espaces vides avant le premier jour
        }
        
        final day = index - firstDayWeekday + 2;
        final date = DateTime(_focusedDate.year, _focusedDate.month, day);
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final hasEvents = _getEventsForDay(date).isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? (_isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA))
                  : (isToday ? Colors.orange.withOpacity(0.3) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: hasEvents ? Border.all(color: Colors.orange, width: 2) : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (_isDarkMode ? Colors.white : Colors.black),
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: event.color, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: event.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  event.time,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Nouvel événement',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Titre',
                labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Heure (ex: 10:30)',
                labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                setState(() {
                  if (_events[dateKey] == null) {
                    _events[dateKey] = [];
                  }
                  _events[dateKey]!.add(CalendarEvent(
                    titleController.text,
                    timeController.text.isNotEmpty ? timeController.text : '00:00',
                    Colors.blue,
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
            ),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class CalendarEvent {
  final String title;
  final String time;
  final Color color;

  CalendarEvent(this.title, this.time, this.color);
} 