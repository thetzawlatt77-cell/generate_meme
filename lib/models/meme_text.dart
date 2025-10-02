import 'package:flutter/material.dart';

class MemeText {
  final String id;
  String text;
  Offset offset;
  double fontSize;
  Color color;
  bool bold;
  bool stroke;
  double strokeWidth;
  double maxWidth; // Maximum width before wrapping to new line

  MemeText({
    required this.id,
    required this.text,
    required this.offset,
    this.fontSize = 14.0,
    this.color = Colors.black,
    this.bold = true,
    this.stroke = true,
    this.strokeWidth = 6.0,
    this.maxWidth = 200.0, // Default max width
  });

  MemeText copyWith({
    String? id,
    String? text,
    Offset? offset,
    double? fontSize,
    Color? color,
    bool? bold,
    bool? stroke,
    double? strokeWidth,
    double? maxWidth,
  }) {
    return MemeText(
      id: id ?? this.id,
      text: text ?? this.text,
      offset: offset ?? this.offset,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      bold: bold ?? this.bold,
      stroke: stroke ?? this.stroke,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      maxWidth: maxWidth ?? this.maxWidth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'offset': {'dx': offset.dx, 'dy': offset.dy},
      'fontSize': fontSize,
      'color': color.toARGB32(),
      'bold': bold,
      'stroke': stroke,
      'strokeWidth': strokeWidth,
      'maxWidth': maxWidth,
    };
  }

  factory MemeText.fromJson(Map<String, dynamic> json) {
    return MemeText(
      id: json['id'] as String,
      text: json['text'] as String,
      offset: Offset(
        (json['offset'] as Map<String, dynamic>)['dx'] as double,
        (json['offset'] as Map<String, dynamic>)['dy'] as double,
      ),
      fontSize: (json['fontSize'] as num).toDouble(),
      color: Color(json['color'] as int),
      bold: json['bold'] as bool,
      stroke: json['stroke'] as bool,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      maxWidth: (json['maxWidth'] as num?)?.toDouble() ?? 200.0,
    );
  }

  @override
  String toString() {
    return 'MemeText(id: $id, text: $text, offset: $offset, fontSize: $fontSize, color: $color, bold: $bold, stroke: $stroke, strokeWidth: $strokeWidth, maxWidth: $maxWidth)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemeText &&
        other.id == id &&
        other.text == text &&
        other.offset == offset &&
        other.fontSize == fontSize &&
        other.color == color &&
        other.bold == bold &&
        other.stroke == stroke &&
        other.strokeWidth == strokeWidth &&
        other.maxWidth == maxWidth;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        offset.hashCode ^
        fontSize.hashCode ^
        color.hashCode ^
        bold.hashCode ^
        stroke.hashCode ^
        strokeWidth.hashCode ^
        maxWidth.hashCode;
  }
}
