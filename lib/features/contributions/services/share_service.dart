import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/features/contributions/models/contribution_models.dart';
import 'package:github_wallpaper/features/contributions/services/contribution_metrics.dart';
import 'package:github_wallpaper/features/contributions/widgets/share_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<String> savePngBytes(Uint8List bytes, {String? prefix}) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final p = '${dir.path}/${prefix ?? 'gitwall'}_$ts.png';
    final f = File(p);
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  static Future<Uint8List> capturePng(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    final renderObject = await _waitForReadyBoundary(repaintBoundaryKey);
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw Exception('capture: encoding failed');
    }
    return data.buffer.asUint8List();
  }

  static Future<RenderRepaintBoundary> _waitForReadyBoundary(
    GlobalKey repaintBoundaryKey,
  ) async {
    RenderRepaintBoundary? boundary;

    for (var attempt = 0; attempt < 6; attempt++) {
      WidgetsBinding.instance.ensureVisualUpdate();
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 120),
        onTimeout: () {},
      );
      final ctx = repaintBoundaryKey.currentContext;
      final renderObject = ctx?.findRenderObject();
      if (renderObject is RenderRepaintBoundary &&
          renderObject.hasSize &&
          renderObject.size.width > 0 &&
          renderObject.size.height > 0) {
        boundary = renderObject;
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    if (boundary == null) {
      final ctx = repaintBoundaryKey.currentContext;
      if (ctx == null) {
        throw Exception('capture: missing context');
      }
      final renderObject = ctx.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw Exception('capture: missing boundary');
      }
      boundary = renderObject;
    }

    return boundary;
  }

  static Future<void> sharePngFile(
    String path, {
    String? text,
    Rect? sharePositionOrigin,
  }) async {
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
    ShareCardFamily? initialFamily,
    ShareExportFormat? initialFormat,
  }) async {
    final recommendation = recommendShareCardFamily(data, trend7d, trend30d);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return _ShareChooserSheet(
          data: data,
          trend7d: trend7d,
          trend30d: trend30d,
          initialFamily: initialFamily ?? recommendation,
          initialFormat: initialFormat ?? ShareExportFormat.story,
          recommendation: recommendation,
        );
      },
    );
  }

  static Future<void> shareMonthlyReport({
    required BuildContext context,
    required CachedContributionData data,
    required TrendSummary trend7d,
    required TrendSummary trend30d,
  }) {
    return shareCard(
      context: context,
      data: data,
      trend7d: trend7d,
      trend30d: trend30d,
      initialFamily: ShareCardFamily.monthlySnapshot,
      initialFormat: ShareExportFormat.story,
    );
  }

  static Future<void> shareWrappedReport({
    required BuildContext context,
    required CachedContributionData data,
    required TrendSummary trend7d,
    required TrendSummary trend30d,
  }) {
    return shareCard(
      context: context,
      data: data,
      trend7d: trend7d,
      trend30d: trend30d,
      initialFamily: ShareCardFamily.wrapped,
      initialFormat: ShareExportFormat.story,
    );
  }

  static double _previewWidthFor(ShareExportFormat _) => 360;

  static String _captionFor(ShareCardFamily family) => switch (family) {
        ShareCardFamily.dailyFlex => 'My daily GitHub flex on GitWall',
        ShareCardFamily.streakMilestone =>
          'I just hit a streak milestone on GitWall',
        ShareCardFamily.monthlySnapshot => 'My GitWall monthly snapshot',
        ShareCardFamily.wrapped => 'My GitWall Wrapped',
        ShareCardFamily.repoFocus => 'My repo focus on GitWall',
      };
}

class _ShareChooserSheet extends StatefulWidget {
  final CachedContributionData data;
  final TrendSummary trend7d;
  final TrendSummary trend30d;
  final ShareCardFamily initialFamily;
  final ShareExportFormat initialFormat;
  final ShareCardFamily recommendation;

  const _ShareChooserSheet({
    required this.data,
    required this.trend7d,
    required this.trend30d,
    required this.initialFamily,
    required this.initialFormat,
    required this.recommendation,
  });

  @override
  State<_ShareChooserSheet> createState() => _ShareChooserSheetState();
}

class _ShareChooserSheetState extends State<_ShareChooserSheet> {
  final GlobalKey _previewKey = GlobalKey();
  late ShareCardFamily _selectedFamily;
  late ShareExportFormat _selectedFormat;
  bool _sharing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _selectedFamily = widget.initialFamily;
    _selectedFormat = widget.initialFormat;
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _error = null;
    });

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      final previewContext = _previewKey.currentContext;
      final previewRender = previewContext?.findRenderObject();
      final previewWidth = previewRender is RenderBox && previewRender.hasSize
          ? previewRender.size.width
          : ShareService._previewWidthFor(_selectedFormat);
      final bytes = await ShareService.capturePng(
        _previewKey,
        pixelRatio: (1440 / previewWidth).clamp(2.4, 4.0),
      );
      final path = await ShareService.savePngBytes(
        bytes,
        prefix: 'gitwall_${_selectedFamily.name}',
      );
      await ShareService.sharePngFile(
        path,
        text: ShareService._captionFor(_selectedFamily),
        sharePositionOrigin: origin,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _sharing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recommendation = widget.recommendation;
    final selectedDefinition = _selectedFamily.definition;
    final recommendationSelected = recommendation == _selectedFamily;
    final recommendationLabel = recommendationSelected
        ? 'Best fit selected'
        : 'Recommended right now: ${recommendation.label}';

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sheetHeight = math.min(constraints.maxHeight, 920.0);
          return SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Share your progress',
                          style: TextStyle(
                            fontSize: AppTheme.fontTitle,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _sharing ? null : () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                  Text(
                    'Choose a story card, review the preview, then export it.',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: AppTheme.brLarge,
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selectedDefinition.icon,
                            color: scheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedDefinition.label,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: AppTheme.fontBase + 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedDefinition.bestFor,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.68),
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.07),
                      borderRadius: AppTheme.brLarge,
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          recommendation.icon,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recommendationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFamilySelector(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      key: const Key('share-preview-stage'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest.withValues(alpha: 0.35),
                        borderRadius: AppTheme.brLarge,
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                          child: RepaintBoundary(
                            key: _previewKey,
                            child: SizedBox(
                              width: ShareService._previewWidthFor(_selectedFormat),
                              child: buildShareCardPreview(
                                family: _selectedFamily,
                                data: widget.data,
                                trend7d: widget.trend7d,
                                trend30d: widget.trend30d,
                                showBranding: false,
                                format: _selectedFormat,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Sharing failed. Try again.',
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _error.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                        fontSize: AppTheme.fontCaption,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, actionConstraints) {
                      final actionButton = FilledButton.icon(
                        key: const Key('share-primary-cta'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: _sharing ? null : _share,
                        icon: _sharing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.ios_share_rounded, size: 18),
                        label: Text(
                          _sharing ? 'Sharing...' : 'Share this moment',
                        ),
                      );

                      if (actionConstraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: _sharing
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedFamily =
                                              widget.recommendation;
                                          _selectedFormat = widget
                                              .recommendation.defaultFormat;
                                        });
                                      },
                                child: const Text('Use best fit'),
                              ),
                            ),
                            SizedBox(width: double.infinity, child: actionButton),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          TextButton(
                            onPressed: _sharing
                                ? null
                                : () {
                                    setState(() {
                                      _selectedFamily = widget.recommendation;
                                      _selectedFormat =
                                          widget.recommendation.defaultFormat;
                                    });
                                  },
                            child: const Text('Use best fit'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: actionButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFamilySelector() {
    final orderedFamilies = ShareTemplateCatalog.orderedCoreFamilies(
      recommendation: widget.recommendation,
      selected: _selectedFamily,
    );

    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      key: const Key('share-family-rail'),
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: orderedFamilies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final family = orderedFamilies[index];
          final selected = _selectedFamily == family;
          return Material(
            color: selected
                ? scheme.primary.withValues(alpha: 0.12)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _sharing
                  ? null
                  : () {
                      setState(() {
                        _selectedFamily = family;
                        _selectedFormat = family.defaultFormat;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? scheme.primary.withValues(alpha: 0.18)
                        : scheme.outline.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      family.icon,
                      size: 18,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.72),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      family.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
