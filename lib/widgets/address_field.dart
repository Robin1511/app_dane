import 'package:flutter/material.dart';
import '../services/mapbox_service.dart';

class AddressField extends StatefulWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  const AddressField({
    super.key,
    required this.controller,
    required this.isDarkMode,
    this.hasError = false,
    this.onChanged,
  });

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  List<MapboxSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _createOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40, // Largeur moins padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // Décalage sous le champ
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDarkMode ? Colors.grey[600]! : const Color(0xFFE9ECEF),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _suggestions.length,
                                 itemBuilder: (context, index) {
                   final suggestion = _suggestions[index];
                   return Container(
                     margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Material(
                       color: Colors.transparent,
                       child: InkWell(
                         borderRadius: BorderRadius.circular(8),
                         hoverColor: widget.isDarkMode 
                           ? Colors.white.withOpacity(0.08)
                           : Colors.black.withOpacity(0.04),
                         splashColor: widget.isDarkMode 
                           ? const Color(0xFF9C27B0).withOpacity(0.2)
                           : const Color(0xFF00D4AA).withOpacity(0.2),
                         highlightColor: widget.isDarkMode 
                           ? const Color(0xFF9C27B0).withOpacity(0.1)
                           : const Color(0xFF00D4AA).withOpacity(0.1),
                         onTap: () {
                           widget.controller.text = suggestion.placeName;
                           _removeOverlay();
                           setState(() {
                             _showSuggestions = false;
                           });
                           if (widget.onChanged != null) {
                             widget.onChanged!(suggestion.placeName);
                           }
                         },
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                           child: Row(
                             children: [
                               Icon(
                                 Icons.location_on,
                                 color: widget.isDarkMode 
                                   ? const Color(0xFF9C27B0) 
                                   : const Color(0xFF00D4AA),
                                 size: 20,
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   suggestion.placeName,
                                   style: TextStyle(
                                     color: widget.isDarkMode ? Colors.white : Colors.black,
                                     fontSize: 14,
                                     fontWeight: FontWeight.w500,
                                   ),
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                     ),
                   );
                 },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await MapboxService.searchPlaces(query);
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
        _showSuggestions = suggestions.isNotEmpty;
      });

      if (_showSuggestions) {
        _createOverlay();
      } else {
        _removeOverlay();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showSuggestions = false;
      });
      _removeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Adresse',
                    style: TextStyle(
                      color: widget.hasError 
                        ? Colors.red[600]
                        : (widget.isDarkMode ? Colors.white70 : const Color(0xFF666666)),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.hasError 
                    ? [Colors.red[400]!, Colors.red[600]!]
                    : (widget.isDarkMode 
                      ? [const Color(0xFF9C27B0), const Color(0xFFE91E63)]
                      : [const Color(0xFF00D4AA), const Color(0xFF00C9FF)]),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 20),
            ),
            suffixIcon: _isLoading 
              ? Container(
                  margin: const EdgeInsets.all(12),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA),
                    ),
                  ),
                )
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: widget.hasError ? Colors.red : Colors.transparent,
                width: widget.hasError ? 2 : 0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: widget.hasError 
                  ? Colors.red 
                  : (widget.isDarkMode ? const Color(0xFF9C27B0) : const Color(0xFF00D4AA)), 
                width: 2
              ),
            ),
            filled: true,
            fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
          onChanged: (value) {
            _onSearchChanged(value);
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
          onTap: () {
            if (_suggestions.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
              _createOverlay();
            }
          },
        ),
      ),
    );
  }
} 