import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:github_wallpaper/core/theme/app_theme.dart';

const _contributionPattern = <List<int>>[
  [0, 1, 0, 1, 2, 1, 0, 0],
  [0, 1, 1, 2, 3, 2, 1, 0],
  [0, 1, 2, 3, 4, 3, 2, 1],
  [0, 1, 2, 4, 4, 3, 2, 2],
  [0, 0, 1, 2, 3, 3, 2, 3],
  [0, 0, 1, 1, 2, 2, 3, 4],
  [0, 0, 0, 1, 1, 2, 2, 3],
];

class GitHubConnectContent extends StatefulWidget {
  const GitHubConnectContent({
    super.key,
    required this.accent,
  });

  final Color accent;

  @override
  State<GitHubConnectContent> createState() => _GitHubConnectContentState();
}

class _GitHubConnectContentState extends State<GitHubConnectContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loopController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference();
  }

  void _syncMotionPreference() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion == _reduceMotion &&
        (reduceMotion || _loopController.isAnimating)) {
      return;
    }

    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _loopController
        ..stop()
        ..value = 0.34;
      return;
    }

    if (!_loopController.isAnimating) {
      _loopController.repeat();
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 620 || constraints.maxWidth < 360;

        return Padding(
          padding: EdgeInsets.only(
            top: compact ? 2 : 6,
            bottom: compact ? 2 : 4,
          ),
          child: AnimatedBuilder(
            animation: _loopController,
            builder: (context, child) {
              return _HeroIllustrationPanel(
                accent: widget.accent,
                compact: compact,
                progress: _loopController.value,
              );
            },
          ),
        );
      },
    );
  }
}

class _HeroIllustrationPanel extends StatelessWidget {
  const _HeroIllustrationPanel({
    required this.accent,
    required this.compact,
    required this.progress,
  });

  final Color accent;
  final bool compact;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heatmapLevels = AppThemeExt.of(context).heatmapLevels;
    final heroBlue = Color.lerp(AppTheme.primaryBlue, accent, 0.45)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final loop = progress * math.pi * 2;
        final railHeight = compact ? 56.0 : 62.0;
        final panelPadding = compact ? 18.0 : 24.0;
        final drift = math.sin(loop) * (compact ? 12.0 : 18.0);
        final sway = math.cos(loop * 0.92) * (compact ? 8.0 : 12.0);
        final repoFloat = math.sin(loop + 0.9) * (compact ? 9.0 : 14.0);
        final phoneFloat = math.cos(loop + 1.2) * (compact ? 10.0 : 16.0);
        final hubPulse = 0.95 + (0.08 * math.sin(loop).abs());
        final repoWidth = math.min(width * 0.43, compact ? 142.0 : 178.0);
        final phoneHeight = math.min(height * 0.60, compact ? 176.0 : 244.0);
        final phoneWidth = phoneHeight * 0.53;
        final phoneBottom = railHeight + panelPadding - 2 - drift * 0.22;
        final hubSize = compact ? 74.0 : 88.0;
        final hubTop = height * 0.36 + drift * 0.22;
        final copyBottom = railHeight + panelPadding + (compact ? 14.0 : 18.0);
        final copyRightInset =
            phoneWidth + panelPadding + (compact ? 10.0 : 18.0);

        return Semantics(
          container: true,
          label:
              'Illustration of GitHub activity syncing into a wallpaper preview.',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 30 : 34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF050914),
                      const Color(0xFF0B1324),
                      Color.lerp(const Color(0xFF101A31), heroBlue, 0.16)!,
                      const Color(0xFF131B2B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(compact ? 30 : 34),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: heroBlue.withValues(alpha: 0.16),
                      blurRadius: 40,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: -48,
                      top: -44 + drift * 0.45,
                      child: _AmbientGlow(
                        size: compact ? 150 : 200,
                        color: heroBlue.withValues(alpha: 0.24),
                      ),
                    ),
                    Positioned(
                      right: -50,
                      bottom: -54 - drift * 0.25,
                      child: _AmbientGlow(
                        size: compact ? 180 : 230,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned(
                      right: width * 0.20,
                      top: height * 0.20 + drift * 0.12,
                      child: _AmbientGlow(
                        size: compact ? 120 : 160,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _IllustrationBackdropPainter(
                          accent: accent,
                          outline: scheme.outline,
                          progress: progress,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ConnectionPainter(
                          accent: accent,
                          progress: progress,
                        ),
                      ),
                    ),
                    Positioned(
                      left: panelPadding + sway * 0.15,
                      top: panelPadding + repoFloat,
                      width: repoWidth,
                      child: Transform.translate(
                        offset: Offset(sway * 0.28, repoFloat * 0.55),
                        child: Transform.rotate(
                          angle: -0.085 + (repoFloat * 0.0022),
                          child: _GitHubSnapshotCard(
                            accent: accent,
                            compact: compact,
                            progress: progress,
                            heatmapLevels: heatmapLevels,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: panelPadding,
                      right: panelPadding,
                      child: _HeroCornerChip(
                        accent: accent,
                        compact: compact,
                      ),
                    ),
                    Positioned(
                      left: (width - hubSize) / 2,
                      top: hubTop,
                      width: hubSize,
                      height: hubSize + (compact ? 18.0 : 20.0),
                      child: Transform.scale(
                        scale: hubPulse,
                        child: _SyncStatusChip(
                          accent: accent,
                          compact: compact,
                          progress: progress,
                        ),
                      ),
                    ),
                    Positioned(
                      right: panelPadding - sway * 0.18,
                      bottom: phoneBottom + phoneFloat * 0.45,
                      width: phoneWidth,
                      child: Transform.translate(
                        offset: Offset(-sway * 0.22, phoneFloat * 0.4),
                        child: Transform.rotate(
                          angle: 0.03 - (phoneFloat * 0.0015),
                          child: _WallpaperPreviewDevice(
                            accent: accent,
                            compact: compact,
                            progress: progress,
                            heatmapLevels: heatmapLevels,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: panelPadding,
                      right: copyRightInset,
                      bottom: copyBottom,
                      child: _HeroCopyBlock(
                        accent: accent,
                        compact: compact,
                      ),
                    ),
                    Positioned(
                      left: panelPadding,
                      right: panelPadding,
                      bottom: panelPadding,
                      child: _FlowRail(
                        accent: accent,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _HeroCornerChip extends StatelessWidget {
  const _HeroCornerChip({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.10),
            AppTheme.primaryBlue.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'GitWall',
            style: textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopyBlock extends StatelessWidget {
  const _HeroCopyBlock({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 2 : 4,
          compact ? 4 : 6,
          compact ? 8 : 12,
          compact ? 2 : 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 38 : 46,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.24),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              'GitHub activity,\non your screen.',
              style: TextStyle(
                fontSize: compact ? 27 : 36,
                height: compact ? 1.06 : 1.04,
                letterSpacing: compact ? -0.8 : -1.05,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.98),
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              'Connect once. Preview fast. Apply when it feels right.',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.74),
                height: 1.50,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.08,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GitHubSnapshotCard extends StatelessWidget {
  const _GitHubSnapshotCard({
    required this.accent,
    required this.compact,
    required this.progress,
    required this.heatmapLevels,
  });

  final Color accent;
  final bool compact;
  final double progress;
  final List<Color> heatmapLevels;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2).abs();
    const surface = Color(0xFFF8FAFF);

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 14 : 16,
        compact ? 13 : 15,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface,
            Color(0xFFECF2FB),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(-2, -4),
          ),
          BoxShadow(
            color:
                AppTheme.primaryBlue.withValues(alpha: 0.06 + (pulse * 0.03)),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.24),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'GitHub',
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'LIVE',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 14),
          _HeatmapBoard(
            heatmapLevels: heatmapLevels,
            progress: progress,
            cellSize: compact ? 10.5 : 12.0,
            gap: compact ? 3.0 : 3.5,
            accent: accent,
            rounded: 3.5,
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(
            'Contribution map',
            style: textTheme.titleSmall?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Row(
            children: [
              Icon(
                Icons.sync_rounded,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Live sync.',
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF4B5565),
                    height: 1.20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WallpaperPreviewDevice extends StatelessWidget {
  const _WallpaperPreviewDevice({
    required this.accent,
    required this.compact,
    required this.progress,
    required this.heatmapLevels,
  });

  final Color accent;
  final bool compact;
  final double progress;
  final List<Color> heatmapLevels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pulse = 0.35 + 0.65 * math.sin(progress * math.pi * 2).abs();
    final boardScale = compact ? 1.0 + (pulse * 0.02) : 1.08 + (pulse * 0.05);

    return Container(
      padding: EdgeInsets.all(compact ? 7 : 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF02050B),
            Color(0xFF0D1320),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 30 : 34),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.primaryBlue.withValues(alpha: 0.12 + (pulse * 0.08)),
            blurRadius: 38,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 0.50,
        child: LayoutBuilder(
          builder: (context, phoneConstraints) {
            final cramped = phoneConstraints.maxWidth < 120 ||
                phoneConstraints.maxHeight < 180;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 23 : 26),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF07101D),
                    const Color(0xFF0D1729),
                    Color.lerp(
                        const Color(0xFF101827), AppTheme.primaryBlue, 0.16)!,
                  ],
                ),
              ),
              child: cramped
                  ? _MiniWallpaperPreview(
                      accent: accent,
                      progress: progress,
                      heatmapLevels: heatmapLevels,
                      pulse: pulse,
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0.08, -0.12),
                                radius: 0.95,
                                colors: [
                                  AppTheme.primaryBlue.withValues(
                                    alpha: 0.18 + (pulse * 0.06),
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: compact ? 44 : 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: compact ? 42 : 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 14 : 16,
                            compact ? 16 : 20,
                            compact ? 14 : 16,
                            compact ? 16 : 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.08),
                                        AppTheme.primaryBlue.withValues(
                                          alpha: 0.08,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.10),
                                    ),
                                  ),
                                  child: Text(
                                    'Auto sync',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.80),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'GITWALL',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: compact ? 6 : 8),
                              Text(
                                'Your graph,\non screen.',
                                style: TextStyle(
                                  fontSize: compact ? 20 : 25,
                                  height: 1.02,
                                  letterSpacing: compact ? -0.8 : -0.95,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                              SizedBox(height: compact ? 14 : 18),
                              Align(
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _AmbientGlow(
                                      size: compact ? 118 : 146,
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.18 + (pulse * 0.08),
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        math.sin(progress * math.pi * 2) * 2,
                                      ),
                                      child: Transform.scale(
                                        scale: boardScale,
                                        child: _HeatmapBoard(
                                          heatmapLevels: heatmapLevels,
                                          progress: progress,
                                          cellSize: compact ? 11.8 : 13.2,
                                          gap: compact ? 3.2 : 3.6,
                                          accent: accent,
                                          rounded: 4.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: compact ? 12 : 14),
                              _PhoneNotificationCard(
                                accent: accent,
                                icon: Icons.notifications_active_rounded,
                                title: 'GitHub synced',
                                subtitle:
                                    'Wallpaper refreshed from your latest graph.',
                              ),
                              SizedBox(height: compact ? 8 : 10),
                              const _PhoneStatusRow(),
                              const Spacer(),
                              Text(
                                'Updates after commits.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.74),
                                  height: 1.30,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniWallpaperPreview extends StatelessWidget {
  const _MiniWallpaperPreview({
    required this.accent,
    required this.progress,
    required this.heatmapLevels,
    required this.pulse,
  });

  final Color accent;
  final double progress;
  final List<Color> heatmapLevels;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraCompact =
            constraints.maxHeight < 150 || constraints.maxWidth < 72;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(ultraCompact ? 6 : 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: ultraCompact ? 58 : 74,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: ultraCompact ? 20 : 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: ultraCompact ? 5 : 8),
                    if (!ultraCompact)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Text(
                            'Live',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: ultraCompact ? 5 : 8),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _AmbientGlow(
                            size: ultraCompact ? 54 : 72,
                            color: AppTheme.primaryBlue.withValues(
                              alpha: 0.16 + (pulse * 0.08),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(
                                0, math.sin(progress * math.pi * 2) * 1.5),
                            child: _HeatmapBoard(
                              heatmapLevels: heatmapLevels,
                              progress: progress,
                              cellSize: ultraCompact ? 4.8 : 6.2,
                              gap: ultraCompact ? 1.4 : 2.0,
                              accent: accent,
                              rounded: ultraCompact ? 2.1 : 2.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!ultraCompact) const SizedBox(height: 6),
                    if (!ultraCompact)
                      Text(
                        'Graph live',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.12,
                        ),
                      ),
                    SizedBox(height: ultraCompact ? 5 : 8),
                    _PhoneNotificationCard(
                      compact: true,
                      icon: Icons.notifications_active_rounded,
                      title: ultraCompact ? 'Synced' : 'Sync done',
                      subtitle: ultraCompact ? '' : 'Wallpaper ready',
                    ),
                    SizedBox(height: ultraCompact ? 5 : 8),
                    Center(
                      child: Container(
                        width: ultraCompact ? 24 : 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhoneNotificationCard extends StatelessWidget {
  const _PhoneNotificationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent,
    this.compact = false,
  });

  final Color? accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = accent ?? AppTheme.primaryBlue;
    final hasSubtitle = subtitle.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.11),
            tint.withValues(alpha: compact ? 0.08 : 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: compact ? 10 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 22 : 28,
            height: compact ? 22 : 28,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(compact ? 9 : 11),
            ),
            child: Icon(
              icon,
              size: compact ? 11 : 15,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(width: compact ? 7 : 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 9.5 : null,
                    letterSpacing: 0.08,
                  ),
                ),
                if (hasSubtitle) SizedBox(height: compact ? 1 : 2),
                if (hasSubtitle)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: compact ? 9.0 : null,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneStatusRow extends StatelessWidget {
  const _PhoneStatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PhoneStatusPill(
            icon: Icons.flash_on_rounded,
            label: 'Live graph',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PhoneStatusPill(
            icon: Icons.lock_outline_rounded,
            label: 'Private sync',
          ),
        ),
      ],
    );
  }
}

class _PhoneStatusPill extends StatelessWidget {
  const _PhoneStatusPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white.withValues(alpha: 0.78),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapBoard extends StatelessWidget {
  const _HeatmapBoard({
    required this.heatmapLevels,
    required this.progress,
    required this.cellSize,
    required this.gap,
    required this.accent,
    required this.rounded,
  });

  final List<Color> heatmapLevels;
  final double progress;
  final double cellSize;
  final double gap;
  final Color accent;
  final double rounded;

  @override
  Widget build(BuildContext context) {
    final activeColumn =
        (progress * _contributionPattern.first.length).floor() %
            _contributionPattern.first.length;
    final shimmer = 0.45 + 0.55 * math.sin(progress * math.pi * 2).abs();

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_contributionPattern.length, (row) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: row == _contributionPattern.length - 1 ? 0 : gap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  List.generate(_contributionPattern[row].length, (column) {
                final level = _contributionPattern[row][column]
                    .clamp(0, heatmapLevels.length - 1)
                    .toInt();
                final highlighted = column == activeColumn && level > 0;
                final fill = highlighted
                    ? Color.lerp(heatmapLevels[level], accent, 0.18)!
                    : heatmapLevels[level];

                return Container(
                  width: cellSize,
                  height: cellSize,
                  margin: EdgeInsets.only(
                    right: column == _contributionPattern[row].length - 1
                        ? 0
                        : gap,
                  ),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(rounded),
                    boxShadow: highlighted
                        ? [
                            BoxShadow(
                              color: fill.withValues(
                                alpha: 0.12 + (shimmer * 0.18),
                              ),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({
    required this.accent,
    required this.compact,
    required this.progress,
  });

  final Color accent;
  final bool compact;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2).abs();
    final orbSize = compact ? 60.0 : 72.0;
    final orbitRadius = compact ? 19.0 : 23.0;
    final orbitAngle = (progress * math.pi * 2) - (math.pi / 2);
    final orbitDotSize = compact ? 9.0 : 10.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: orbSize,
            height: orbSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: orbSize,
                  height: orbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.34),
                        accent.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryBlue
                          .withValues(alpha: 0.22 + (pulse * 0.14)),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(
                          alpha: 0.14 + (pulse * 0.14),
                        ),
                        blurRadius: 24,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: compact ? 36 : 42,
                      height: compact ? 36 : 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF7FAFF),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: progress * math.pi * 2,
                        child: Icon(
                          Icons.sync_rounded,
                          size: compact ? 17 : 19,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (orbSize / 2) +
                      (math.cos(orbitAngle) * orbitRadius) -
                      (orbitDotSize / 2),
                  top: (orbSize / 2) +
                      (math.sin(orbitAngle) * orbitRadius) -
                      (orbitDotSize / 2),
                  child: Container(
                    width: orbitDotSize,
                    height: orbitDotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.92),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(
                            alpha: 0.28 + (pulse * 0.18),
                          ),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            compact ? 'Sync' : 'Sync live',
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowRail extends StatelessWidget {
  const _FlowRail({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.surface.withValues(alpha: 0.70),
                scheme.surfaceContainerHigh.withValues(alpha: 0.62),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Flexible(
                flex: 4,
                child: _FlowStepTile(
                  icon: Icons.login_rounded,
                  label: 'Sign in',
                ),
              ),
              Flexible(
                child: _FlowDivider(accent: accent),
              ),
              const Flexible(
                flex: 3,
                child: _FlowStepTile(
                  icon: Icons.sync_rounded,
                  label: 'Sync',
                ),
              ),
              Flexible(
                child: _FlowDivider(accent: accent),
              ),
              const Flexible(
                flex: 4,
                child: _FlowStepTile(
                  icon: Icons.wallpaper_rounded,
                  label: 'Wallpaper',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowStepTile extends StatelessWidget {
  const _FlowStepTile({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerHighest.withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 15,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowDivider extends StatelessWidget {
  const _FlowDivider({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 1,
        color: accent.withValues(alpha: 0.18),
      ),
    );
  }
}

class _IllustrationBackdropPainter extends CustomPainter {
  const _IllustrationBackdropPainter({
    required this.accent,
    required this.outline,
    required this.progress,
  });

  final Color accent;
  final Color outline;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final dotPaint = Paint()..color = outline.withValues(alpha: 0.09);
    for (double x = 24; x < size.width; x += 28) {
      for (double y = 24; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    final shimmer = 0.06 + (0.06 * math.sin(progress * math.pi * 2).abs());
    final wavePaint = Paint()
      ..color = accent.withValues(alpha: shimmer)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.60,
        size.width * 0.42,
        size.height * 0.84,
        size.width * 0.65,
        size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.56,
        size.width * 0.90,
        size.height * 0.38,
        size.width * 0.96,
        size.height * 0.18,
      );
    canvas.drawPath(path, wavePaint);

    final iterator = path.computeMetrics().iterator;
    if (!iterator.moveNext()) return;
    final metric = iterator.current;
    final distance = metric.length * ((progress * 0.82) % 1.0);
    final tangent = metric.getTangentForOffset(distance);
    if (tangent == null) return;

    final glowPaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(tangent.position, 14, glowPaint);

    final dotPaintGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(tangent.position, 4.5, dotPaintGlow);
  }

  @override
  bool shouldRepaint(covariant _IllustrationBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.outline != outline ||
        oldDelegate.progress != progress;
  }
}

class _ConnectionPainter extends CustomPainter {
  const _ConnectionPainter({
    required this.accent,
    required this.progress,
  });

  final Color accent;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final start = Offset(size.width * 0.30, size.height * 0.34);
    final hub = Offset(size.width * 0.50, size.height * 0.49);
    final end = Offset(size.width * 0.72, size.height * 0.60);

    final pathA = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.28,
        size.width * 0.42,
        size.height * 0.48,
        hub.dx,
        hub.dy,
      );
    final pathB = Path()
      ..moveTo(hub.dx, hub.dy)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.58,
        size.width * 0.64,
        size.height * 0.66,
        end.dx,
        end.dy,
      );

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9;
    canvas.drawPath(pathA, basePaint);
    canvas.drawPath(pathB, basePaint);

    final accentPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.02),
          accent.withValues(alpha: 0.34),
          AppTheme.primaryBlue.withValues(alpha: 0.24),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawPath(pathA, accentPaint);
    canvas.drawPath(pathB, accentPaint);

    void paintParticle(Path path, List<double> shifts) {
      final iterator = path.computeMetrics().iterator;
      if (!iterator.moveNext()) return;
      final metric = iterator.current;

      for (final shift in shifts) {
        final distance = metric.length * ((progress + shift) % 1.0);
        final tangent = metric.getTangentForOffset(distance);
        if (tangent == null) continue;

        final glow = Paint()
          ..color = AppTheme.primaryBlue.withValues(
            alpha: shift == shifts.first ? 0.34 : 0.20,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(
            tangent.position, shift == shifts.first ? 7 : 5, glow);

        final dot = Paint()..color = Colors.white.withValues(alpha: 0.94);
        canvas.drawCircle(
            tangent.position, shift == shifts.first ? 3.6 : 2.6, dot);
      }
    }

    paintParticle(pathA, const [0.02, 0.18, 0.34]);
    paintParticle(pathB, const [0.10, 0.26, 0.42]);

    final nodePaint = Paint()
      ..color = AppTheme.primaryBlue.withValues(
        alpha: 0.18 + (0.08 * math.sin(progress * math.pi * 2).abs()),
      );
    canvas.drawCircle(start, 6, nodePaint);
    canvas.drawCircle(hub, 7, nodePaint);
    canvas.drawCircle(end, 6, nodePaint);

    final nodeCorePaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    canvas.drawCircle(start, 2.2, nodeCorePaint);
    canvas.drawCircle(hub, 2.8, nodeCorePaint);
    canvas.drawCircle(end, 2.2, nodeCorePaint);
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.progress != progress;
  }
}

class OnboardingPreparingState extends StatelessWidget {
  const OnboardingPreparingState({
    super.key,
    required this.accent,
    this.title = 'Preparing your GitWall',
    this.subtitle =
        'Syncing your activity and getting the first wallpaper ready.',
  });

  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface.withValues(alpha: 0.92),
            scheme.surfaceContainerHigh.withValues(alpha: 0.84),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.sync_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          AppTheme.h16,
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppTheme.h8,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.70),
              height: 1.42,
            ),
          ),
          AppTheme.h16,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Securing sync',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
