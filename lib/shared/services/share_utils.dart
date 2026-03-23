import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/shared/services/membership_entitlements.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/shared/widgets/share_card.dart';

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

  static Future<void> shareCard({
    required BuildContext context,
    required CachedContributionData data,
    required TrendSummary trend7d,
    required TrendSummary trend30d,
  }) async {
    final boundaryKey = GlobalKey();
    final scheme = Theme.of(context).colorScheme;
    Object? shareError;
    StackTrace? shareStack;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            if (!started) {
              started = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  final box = ctx.findRenderObject() as RenderBox?;
                  final origin = box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size;
                  final bytes = await capturePng(boundaryKey);
                  final path =
                      await savePngBytes(bytes, prefix: 'gitwall_share');
                  await sharePngFile(
                    path,
                    text: 'My GitHub active journey on GitWall',
                    sharePositionOrigin: origin,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e, s) {
                  shareError = e;
                  shareStack = s;
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Share Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: RepaintBoundary(
                        key: boundaryKey,
                        child: ShareCard(
                          data: data,
                          trend7d: trend7d,
                          trend30d: trend30d,
                          showBranding:
                              MembershipEntitlements.shouldWatermarkShares,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (shareError != null) {
      Error.throwWithStackTrace(
        shareError!,
        shareStack ?? StackTrace.current,
      );
    }
  }
}
