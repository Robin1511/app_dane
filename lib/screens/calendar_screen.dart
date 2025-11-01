import 'package:flutter/material.dart';
import '../widgets/settings_button.dart';
import '../services/theme_service.dart';
import 'entry_point.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ThemeService _themeService = ThemeService();
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  Map<DateTime, List<CalendarEvent>> _events = {};
  
  List<Calendar> _calendars = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
    _initializeCalendar();
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

  Future<void> _initializeCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Demander la permission d'accès au calendrier
      final permissionStatus = await Permission.calendar.request();
      
      if (permissionStatus.isGranted) {
        // Récupérer la liste des calendriers
        final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
        
        if (calendarsResult.isSuccess) {
          _calendars = calendarsResult.data!;
          
          // Charger les événements du calendrier principal (iPhone)
          await _loadCalendarEvents();
        } else {
          setState(() {
            _errorMessage = 'Erreur lors de la récupération des calendriers';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Permission d\'accès au calendrier refusée';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCalendarEvents() async {
    if (_calendars.isEmpty) return;

    try {
      // Utiliser le premier calendrier disponible (généralement le calendrier principal)
      final calendar = _calendars.first;
      
      // Récupérer les événements du mois en cours
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      
      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(
          startDate: startDate,
          endDate: endDate,
        ),
      );

      if (eventsResult.isSuccess) {
        final deviceEvents = eventsResult.data!;
        _events.clear();
        
        for (final event in deviceEvents) {
          final eventDate = event.start!;
          final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
          
          if (!_events.containsKey(dateKey)) {
            _events[dateKey] = [];
          }
          
          _events[dateKey]!.add(
            CalendarEvent(
              event.title ?? 'Sans titre',
              '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}',
              _getEventColor(event),
              description: event.description,
              location: event.location,
            ),
          );
        }
        
        setState(() {});
      }
    } catch (e) {
      print('Erreur lors du chargement des événements: $e');
    }
  }

  Color _getEventColor(Event event) {
    // Couleurs par défaut selon le type d'événement
    final title = event.title?.toLowerCase() ?? '';
    if (title.contains('réunion') || title.contains('meeting')) return Colors.blue;
    if (title.contains('formation') || title.contains('training')) return Colors.green;
    if (title.contains('deadline') || title.contains('urgent')) return Colors.red;
    if (title.contains('présentation') || title.contains('presentation')) return Colors.orange;
    if (title.contains('rdv') || title.contains('appointment')) return Colors.purple;
    if (title.contains('anniversaire') || title.contains('birthday')) return Colors.pink;
    
    return Colors.grey;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calendrier',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Bouton de synchronisation
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
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
                _isLoading ? Icons.refresh : Icons.sync,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: _isLoading ? null : _initializeCalendar,
            ),
          ),
          // Bouton Home pour retourner au dashboard
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
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
                color: isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFFE91E63),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const EntryPoint()),
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
              color: isDarkMode ? Colors.grey[800] : Colors.white,
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
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: isDarkMode 
                  ? const Color(0xFF9C27B0) 
                  : const Color(0xFFE91E63),
              ),
              onPressed: () {
                _themeService.toggleTheme();
              },
              tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
            ),
          ),
          SettingsButton(
            isDarkMode: isDarkMode,
            onPressed: () {
              // TODO: Ajouter sidebar si nécessaire
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Affichage des erreurs
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // En-tête du mois
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode 
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
                    _loadCalendarEvents(); // Recharger les événements
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
                    _loadCalendarEvents(); // Recharger les événements
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
                color: isDarkMode ? Colors.grey[850] : Colors.white,
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
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
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
                color: isDarkMode ? Colors.grey[850] : Colors.white,
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
                      color: isDarkMode ? Colors.white : Colors.black,
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
        backgroundColor: isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
                  ? (_themeService.isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA))
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
                      : (_themeService.isDarkMode ? Colors.white : Colors.black),
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
    final isDarkMode = _themeService.isDarkMode;
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
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  event.time,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
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
    final isDarkMode = _themeService.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Nouvel événement',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Titre',
                labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Heure (ex: 10:30)',
                labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[600]),
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
              backgroundColor: isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
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
  final String? description;
  final String? location;

  CalendarEvent(this.title, this.time, this.color, {this.description, this.location});
} 