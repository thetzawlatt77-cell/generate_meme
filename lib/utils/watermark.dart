import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WatermarkUtils {
  /// Adds a watermark/trademark to the captured image
  static Future<Uint8List> addWatermark(
    Uint8List imageBytes, {
    String watermarkPath = 'assets/images/logo512.png',
    double opacity = 0.7,
    double size = 0.15, // 15% of image size
    Alignment alignment = Alignment.bottomRight,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) async {
    try {
      // Load the original image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      // Load the watermark image
      final watermarkBytes = await rootBundle.load(watermarkPath);
      final watermarkCodec = await ui.instantiateImageCodec(
        watermarkBytes.buffer.asUint8List(),
      );
      final watermarkFrame = await watermarkCodec.getNextFrame();
      final watermarkImage = watermarkFrame.image;

      // Calculate watermark size
      final watermarkSize = (originalImage.width * size).round();
      final scaledWatermark = await _scaleImage(watermarkImage, watermarkSize);

      // Create a new image with watermark
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Calculate watermark position
      final watermarkOffset = _calculateWatermarkPosition(
        originalImage.width,
        originalImage.height,
        scaledWatermark.width,
        scaledWatermark.height,
        alignment,
        padding,
      );

      // Draw watermark with opacity
      final watermarkPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: opacity),
          BlendMode.modulate,
        );

      canvas.drawImage(scaledWatermark, watermarkOffset, watermarkPaint);

      // Convert to image
      final picture = recorder.endRecording();
      final watermarkedImage = await picture.toImage(
        originalImage.width,
        originalImage.height,
      );

      // Convert to bytes
      final byteData = await watermarkedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Dispose resources
      originalImage.dispose();
      watermarkImage.dispose();
      scaledWatermark.dispose();
      watermarkedImage.dispose();
      picture.dispose();

      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error adding watermark: $e');
      // Return original image if watermark fails
      return imageBytes;
    }
  }

  /// Scales an image to the specified size
  static Future<ui.Image> _scaleImage(ui.Image image, int targetSize) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Calculate scale to maintain aspect ratio
    final scale = targetSize / image.width;
    final scaledHeight = (image.height * scale).round();

    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    final scaledImage = await picture.toImage(targetSize, scaledHeight);

    picture.dispose();
    return scaledImage;
  }

  /// Calculates the watermark position based on alignment
  static Offset _calculateWatermarkPosition(
    int imageWidth,
    int imageHeight,
    int watermarkWidth,
    int watermarkHeight,
    Alignment alignment,
    EdgeInsets padding,
  ) {
    double x, y;

    // Calculate X position
    switch (alignment.x) {
      case -1.0: // Left
        x = padding.left;
        break;
      case 0.0: // Center
        x = (imageWidth - watermarkWidth) / 2;
        break;
      case 1.0: // Right
        x = imageWidth - watermarkWidth - padding.right;
        break;
      default:
        x = imageWidth - watermarkWidth - padding.right;
    }

    // Calculate Y position
    switch (alignment.y) {
      case -1.0: // Top
        y = padding.top;
        break;
      case 0.0: // Center
        y = (imageHeight - watermarkHeight) / 2;
        break;
      case 1.0: // Bottom
        y = imageHeight - watermarkHeight - padding.bottom;
        break;
      default:
        y = imageHeight - watermarkHeight - padding.bottom;
    }

    return Offset(x, y);
  }
}
