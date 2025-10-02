import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meme_text.dart';

class DraggableMemeText extends StatefulWidget {
  final MemeText memeText;
  final Size canvasSize;
  final Function(MemeText) onChanged;
  final Function(String) onDelete;
  final bool isSelected;
  final Function(String) onSelect;

  const DraggableMemeText({
    super.key,
    required this.memeText,
    required this.canvasSize,
    required this.onChanged,
    required this.onDelete,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggableMemeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
    }
  }

  void _updateOffset(Offset newOffset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.memeText.text,
        style: GoogleFonts.anton(
          fontSize: widget.memeText.fontSize,
          fontWeight: widget.memeText.bold ? FontWeight.bold : FontWeight.normal,
          color: widget.memeText.color,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    textPainter.layout(maxWidth: widget.memeText.maxWidth);

    final clampedOffset = Offset(
      newOffset.dx.clamp(0, widget.canvasSize.width - textPainter.width),
      newOffset.dy.clamp(0, widget.canvasSize.height - textPainter.height),
    );

    widget.onChanged(widget.memeText.copyWith(offset: clampedOffset));
  }

  List<Color> _getQuickColorOptions() {
    return [
      Colors.white,
      Colors.yellow,
      Colors.red,
      Colors.black,
      Colors.cyan,
      Colors.green,
      Colors.blue,
      Colors.orange,
    ];
  }

  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditBottomSheet(
        memeText: widget.memeText,
        onChanged: widget.onChanged,
        onDelete: widget.onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.memeText.offset.dx,
      top: widget.memeText.offset.dy,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _scaleAnimation.value : 1.0,
            child: GestureDetector(
              onTap: () => widget.onSelect(widget.memeText.id),
              onLongPress: _showEditDialog,
              onPanUpdate: (details) {
                final newOffset = widget.memeText.offset + details.delta;
                _updateOffset(newOffset);
              },
              child: Stack(
                children: [
                  Container(
                    decoration: widget.isSelected
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : null,
                    child: SizedBox(
                      width: widget.memeText.maxWidth,
                      child: Stack(
                        children: [
                          // Stroke layer
                          if (widget.memeText.stroke)
                            Text(
                              widget.memeText.text,
                              style: GoogleFonts.anton(
                                fontSize: widget.memeText.fontSize,
                                fontWeight: widget.memeText.bold
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.black,
                                letterSpacing: 1.5,
                                shadows: [],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: null,
                              overflow: TextOverflow.visible,
                            ),
                          // Fill layer
                          Text(
                            widget.memeText.text,
                            style: GoogleFonts.anton(
                              fontSize: widget.memeText.fontSize,
                              fontWeight: widget.memeText.bold
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: widget.memeText.color,
                              letterSpacing: 1.5,
                              shadows: [],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Quick color picker (only when selected)
                  if (widget.isSelected)
                    Positioned(
                      top: -60,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Color:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ..._getQuickColorOptions().map((color) {
                              return GestureDetector(
                                onTap: () {
                                  widget.onChanged(widget.memeText.copyWith(color: color));
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.memeText.color == color ? Colors.black : Colors.grey[300]!,
                                      width: widget.memeText.color == color ? 2 : 1,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditBottomSheet extends StatefulWidget {
  final MemeText memeText;
  final Function(MemeText) onChanged;
  final Function(String) onDelete;

  const _EditBottomSheet({
    required this.memeText,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  late TextEditingController _textController;
  late double _fontSize;
  late Color _color;
  late bool _bold;
  late bool _stroke;
  late double _strokeWidth;
  late double _maxWidth;

  final List<Color> _colorOptions = [
    Colors.white,
    Colors.yellow,
    Colors.red,
    Colors.black,
    Colors.cyan,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.lime,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.memeText.text);
    _fontSize = widget.memeText.fontSize;
    _color = widget.memeText.color;
    _bold = widget.memeText.bold;
    _stroke = widget.memeText.stroke;
    _strokeWidth = widget.memeText.strokeWidth;
    _maxWidth = widget.memeText.maxWidth;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateText() {
    widget.onChanged(widget.memeText.copyWith(
      text: _textController.text,
      fontSize: _fontSize,
      color: _color,
      bold: _bold,
      stroke: _stroke,
      strokeWidth: _strokeWidth,
      maxWidth: _maxWidth,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Edit Text',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Text input
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _updateText(),
          ),
          const SizedBox(height: 20),

          // Font size slider
          Text('Font Size: ${_fontSize.round()}'),
          Slider(
            value: _fontSize,
            min: 14,
            max: 64,
            divisions: 50,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
              _updateText();
            },
          ),
          const SizedBox(height: 20),

          // Max width slider
          Text('Max Width: ${_maxWidth.round()}px'),
          Slider(
            value: _maxWidth,
            min: 100,
            max: 400,
            divisions: 30,
            onChanged: (value) {
              setState(() {
                _maxWidth = value;
              });
              _updateText();
            },
          ),
          const SizedBox(height: 20),

          // Color selection
          const Text(
            'Text Color:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _color = color;
                  });
                  _updateText();
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _color == color ? Colors.black : Colors.grey[400]!,
                      width: _color == color ? 4 : 2,
                    ),
                    boxShadow: _color == color
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: _color == color
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Style options
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Bold'),
                  value: _bold,
                  onChanged: (value) {
                    setState(() {
                      _bold = value ?? false;
                    });
                    _updateText();
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Stroke'),
                  value: _stroke,
                  onChanged: (value) {
                    setState(() {
                      _stroke = value ?? false;
                    });
                    _updateText();
                  },
                ),
              ),
            ],
          ),

          // Stroke width slider (only if stroke is enabled)
          if (_stroke) ...[
            Text('Stroke Width: ${_strokeWidth.round()}'),
            Slider(
              value: _strokeWidth,
              min: 2,
              max: 8,
              divisions: 6,
              onChanged: (value) {
                setState(() {
                  _strokeWidth = value;
                });
                _updateText();
              },
            ),
          ],

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onDelete(widget.memeText.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
