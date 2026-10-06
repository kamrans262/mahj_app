import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../../app/app_assets.dart';
import '../../app/theme/app_colors.dart';

abstract final class MahjGoogleMarker {
  static const double defaultGoogleMarkerHue = 23.5;

  static final Map<String, Future<gm.BitmapDescriptor>> _cache =
      <String, Future<gm.BitmapDescriptor>>{};

  static ui.Image? _markerImage;

  static Future<gm.BitmapDescriptor> load({
    double width = 54,
    double height = 61,
  }) {
    final key = 'asset-${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)}';
    return _cache.putIfAbsent(
      key,
      () => gm.BitmapDescriptor.asset(
        ImageConfiguration(size: Size(width, height)),
        AppAssets.mapMatchMarkerPng,
        width: width,
        height: height,
      ),
    );
  }

  static Future<gm.BitmapDescriptor> loadSelected({
    required String title,
    required String subtitle,
  }) {
    final safeTitle = title.trim();
    final safeSubtitle = subtitle.trim();
    final key = 'selected|$safeTitle|$safeSubtitle';

    return _cache.putIfAbsent(
      key,
      () => _buildSelectedMarker(
        title: safeTitle,
        subtitle: safeSubtitle,
      ),
    );
  }

  static Future<gm.BitmapDescriptor> _buildSelectedMarker({
    required String title,
    required String subtitle,
  }) async {
    const logicalWidth = 126.0;
    const markerWidth = 50.0;
    const markerHeight = 57.0;
    const gap = 4.0;
    const cardHeight = 52.0;
    const logicalHeight = markerHeight + gap + cardHeight;
    const pixelRatio = 3.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);

    final markerImage = await _loadMarkerImage();
    const markerLeft = (logicalWidth - markerWidth) / 2;
    canvas.drawImageRect(
      markerImage,
      Rect.fromLTWH(
        0,
        0,
        markerImage.width.toDouble(),
        markerImage.height.toDouble(),
      ),
      const Rect.fromLTWH(
        markerLeft,
        0,
        markerWidth,
        markerHeight,
      ),
      Paint()..filterQuality = FilterQuality.high,
    );

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(
        0,
        markerHeight + gap,
        logicalWidth,
        cardHeight,
      ),
      const Radius.circular(10),
    );

    canvas.drawShadow(
      Path()..addRRect(cardRect),
      AppColors.controlShadow,
      4,
      true,
    );
    canvas.drawRRect(cardRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.controlBorder,
    );

    _paintCenteredText(
      canvas,
      text: title,
      top: markerHeight + gap + 8,
      maxWidth: logicalWidth - 16,
      style: const TextStyle(
        color: AppColors.heading,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.1,
      ),
    );
    _paintCenteredText(
      canvas,
      text: subtitle,
      top: markerHeight + gap + 29,
      maxWidth: logicalWidth - 16,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.1,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (logicalWidth * pixelRatio).round(),
      (logicalHeight * pixelRatio).round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (bytes == null) {
      return load(width: markerWidth, height: markerHeight);
    }

    return gm.BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      width: logicalWidth,
      height: logicalHeight,
    );
  }

  static Future<ui.Image> _loadMarkerImage() async {
    final cached = _markerImage;
    if (cached != null) return cached;

    final data = await rootBundle.load(AppAssets.mapMatchMarkerPng);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    _markerImage = frame.image;
    return frame.image;
  }

  static void _paintCenteredText(
    Canvas canvas, {
    required String text,
    required double top,
    required double maxWidth,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      ellipsis: '…',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    painter.paint(
      canvas,
      Offset((126 - painter.width) / 2, top),
    );
  }
}
