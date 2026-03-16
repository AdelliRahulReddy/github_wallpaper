import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static Future<String> savePngBytes(Uint8List bytes, {String? prefix}) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final p = '${dir.path}/${prefix ?? 'gitwall'}_$ts.png';
    final f = File(p);
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  static Future<Uint8List> capturePng(GlobalKey repaintBoundaryKey,
      {double pixelRatio = 3.0}) async {
    final ctx = repaintBoundaryKey.currentContext;
    if (ctx == null) {
      throw Exception('capture: missing context');
    }
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('capture: missing boundary');
    }
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw Exception('capture: encoding failed');
    }
    return data.buffer.asUint8List();
  }

  static Future<void> sharePngFile(String path,
      {String? text, Rect? sharePositionOrigin}) async {
    await Share.shareXFiles(
      [XFile(path)],
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

