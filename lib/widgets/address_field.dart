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
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final containerWidth = renderBox.size.width + 82; // TextField + icône(68) + padding right(14)
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: containerWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-68, 58), // Décalage: -68px (icône), +58px (hauteur)
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: widget.isDarkMode
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return GestureDetector(
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ECDC4).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF4ECDC4),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion.placeName,
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
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
      if (_suggestions.isNotEmpty || _showSuggestions) {
        setState(() {
          _suggestions.clear();
          _showSuggestions = false;
        });
      }
      _removeOverlay();
      return;
    }

    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final suggestions = await MapboxService.searchPlaces(query);
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuggestions = false;
        });
        _removeOverlay();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextField(
          controller: widget.controller,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Adresse',
            hintStyle: TextStyle(
              color: widget.isDarkMode ? Colors.white60 : Colors.black45,
              fontWeight: FontWeight.w500,
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            isDense: true,
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