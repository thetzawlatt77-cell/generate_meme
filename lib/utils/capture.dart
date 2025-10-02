import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CaptureUtils {
  /// Captures a RepaintBoundary as PNG bytes
  static Future<Uint8List> capturePng(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    try {
      final RenderRepaintBoundary boundary = repaintBoundaryKey
          .currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      if (!boundary.debugNeedsPaint) {
        // Wait for the first frame to be painted
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Captures a widget as PNG bytes by wrapping it in a RepaintBoundary
  static Future<Uint8List> captureWidgetAsPng(
    Widget widget, {
    double pixelRatio = 2.0,
    Size? size,
  }) async {
    // This is a simplified approach - in practice, you'd need to
    // properly render the widget in a widget tree context
    throw UnimplementedError(
      'captureWidgetAsPng requires proper widget rendering context. '
      'Use capturePng with a RepaintBoundary in your widget tree instead.',
    );
  }
}
