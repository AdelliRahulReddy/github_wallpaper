import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';

class SplashScreen extends StatelessWidget {
  final double progress;
  final String appVersion;
  final String? error;
  final VoidCallback? onRetry;

  const SplashScreen(
      {super.key,
      required this.progress,
      required this.appVersion,
      this.error,
      this.onRetry});

  @override
  Widget build(BuildContext context) {
    // 100% System Theme Adaptation
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = scheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: AppTheme.pAll24,
                        child: _ContributionGraph(isDark: isDark, accent: accent),
                      ),
                    ),

                    AppTheme.h40,

                    // Title
                    Text(
                      'GitWall',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                    ),

                    AppTheme.h12,

                    Text(AppStrings.appTagline,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),

                    AppTheme.h60,

                    // Status
                    if (error == null)
                      Column(
                        children: [
                          Text(_status(progress),
                              style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: AppTheme.fontBody,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                        ],
                      )
                    else
                      _buildError(context, error!, accent, onRetry, isDark),
                  ],
                ),
              ),

              // Progress
              if (error == null)
                Positioned(
                    bottom: 60,
                    left: 48,
                    right: 48,
                    child: _buildProgress(context, progress, accent, isDark)),

              // Version
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text('v$appVersion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.3),
                        fontSize: AppTheme.fontCaption,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error, Color accent,
      VoidCallback? onRetry, bool isDark) {
    return Padding(
      padding: AppTheme.pSymH40,
      child: Column(
        children: [
          Container(
            padding: AppTheme.pAll20,
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: AppTheme.brLarge,
              border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.errorRed, size: 32),
                AppTheme.h12,
                Text(error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: AppTheme.fontBase,
                        fontWeight: FontWeight.w600,
                        height: AppTheme.heightRelaxed)),
              ],
            ),
          ),
          AppTheme.h24,
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Try Again',
                style: TextStyle(
                    fontSize: AppTheme.fontMedium,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: AppTheme.pSymH32V16,
              shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.brMedium),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(
      BuildContext context, double progress, Color accent, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Loading',
                style: TextStyle(
                    color: (isDark ? AppTheme.darkText : AppTheme.lightText)
                        .withValues(alpha: 0.5),
                    fontSize: AppTheme.fontCaption,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            Text('${(progress * 100).toInt()}%',
                style: TextStyle(
                    color: accent,
                    fontSize: AppTheme.fontSmall,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ],
        ),
        AppTheme.h8,
        ClipRRect(
          borderRadius: AppTheme.brSmall,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  String _status(double p) => p < 0.25
      ? AppStrings.statusInitializing
      : p < 0.5
          ? AppStrings.statusLoadingResources
          : p < 0.75
              ? AppStrings.statusSettingUp
              : p < 0.95
                  ? AppStrings.statusAlmostReady
                  : AppStrings.statusLaunching;
}

class _ContributionGraph extends StatelessWidget {
  final bool isDark;
  final Color accent;
  const _ContributionGraph({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final levels = AppThemeExt.of(context).heatmapLevels;
    final pattern = [
      [0, 0, 1, 1, 2, 3, 4, 4, 4],
      [0, 1, 1, 2, 3, 4, 4, 4, 3],
      [0, 0, 1, 2, 3, 3, 4, 3, 4],
      [1, 1, 2, 3, 4, 4, 3, 4, 4],
      [0, 1, 1, 2, 3, 4, 4, 3, 2],
      [0, 0, 1, 1, 2, 3, 3, 2, 1],
      [0, 1, 0, 1, 2, 2, 1, 1, 0],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        7,
        (r) => Padding(
          padding: AppTheme.pOnlyB4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              9,
              (c) => Padding(
                padding: AppTheme.pOnlyR4,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                      color: levels[pattern[r][c]],
                      borderRadius: AppTheme.brXS),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
