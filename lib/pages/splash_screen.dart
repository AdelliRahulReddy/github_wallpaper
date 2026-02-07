import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app_theme.dart';
import '../app_utils.dart';

class SplashScreen extends StatelessWidget {
  final double progress;
  final String? error;
  final VoidCallback? onRetry;

  const SplashScreen(
      {super.key, required this.progress, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    // 100% System Theme Adaptation
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.primaryBrandAccent;

    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [AppTheme.darkBg, AppTheme.darkSurface]
          : [AppTheme.lightBg, AppTheme.lightSurface],
    );

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing24),
                      decoration: BoxDecoration(
                        color: (isDark ? scheme.surface : scheme.onSurface)
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: AppTheme.shadow(accent, opacity: 0.1),
                      ),
                      child: _ContributionGraph(isDark: isDark, accent: accent),
                    ).animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.85, 0.85),
                        curve: Curves.easeOutBack,
                        duration: 800.ms),

                    const SizedBox(height: 40),

                    // Title
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.7)])
                          .createShader(b),
                      child: const Text('GitHub Wallpaper',
                          style: TextStyle(
                              fontSize: AppTheme.fontDisplay,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.lightSurface,
                              letterSpacing: -1,
                              height: 1.1)),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 12),

                    Text(AppStrings.appTagline,
                            style: TextStyle(
                                color: (isDark
                                        ? AppTheme.darkText
                                        : AppTheme.lightText)
                                    .withValues(alpha: 0.7),
                                fontSize: AppTheme.fontMedium,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2))
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms),

                    const SizedBox(height: 60),

                    // Status
                    if (error == null)
                      Column(
                        children: [
                          SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor:
                                          AlwaysStoppedAnimation(accent)))
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn(duration: 800.ms)
                              .fadeOut(delay: 800.ms, duration: 800.ms),
                          const SizedBox(height: 20),
                          Text(_status(progress),
                                  style: TextStyle(
                                      color: (isDark
                                              ? AppTheme.darkText
                                              : AppTheme.lightText)
                                          .withValues(alpha: 0.7),
                                      fontSize: AppTheme.fontBody,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3))
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn(duration: 1.2.seconds)
                              .fadeOut(delay: 1.2.seconds, duration: 800.ms),
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
                        child:
                            _buildProgress(context, progress, accent, isDark))
                    .animate()
                    .fadeIn(delay: 700.ms),

              // Version
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text('v${AppStrings.appVersion}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: (isDark ? AppTheme.darkText : AppTheme.lightText)
                            .withValues(alpha: 0.3),
                        fontSize: AppTheme.fontCaption,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5)),
              ).animate().fadeIn(delay: 1.seconds),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error, Color accent,
      VoidCallback? onRetry, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppTheme.errorRed, size: 32),
                const SizedBox(height: 12),
                Text(error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: AppTheme.fontBase,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing32,
                vertical: AppTheme.spacing16,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              elevation: 2,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
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
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Stack(
            children: [
              Container(
                  height: 5,
                  decoration: BoxDecoration(
                      color: (isDark ? AppTheme.darkText : AppTheme.lightText)
                          .withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: 5,
                width: (MediaQuery.of(context).size.width - 96) * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.8)]),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1)
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _status(double p) => p < 0.25
      ? 'Initializing...'
      : p < 0.5
          ? 'Loading resources...'
          : p < 0.75
              ? 'Setting up workspace...'
              : p < 0.95
                  ? 'Almost ready...'
                  : 'Launching...';
}

class _ContributionGraph extends StatelessWidget {
  final bool isDark;
  final Color accent;
  const _ContributionGraph({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: isDark ? 0.9 : 1);
    final colors = [
      base,
      accent.withValues(alpha: 0.3),
      accent.withValues(alpha: 0.5),
      accent.withValues(alpha: 0.7),
      accent
    ];
    final pattern = [
      [0, 1, 2, 1, 0, 1, 2, 3, 2],
      [1, 2, 3, 4, 3, 2, 3, 4, 3],
      [0, 3, 4, 4, 4, 3, 4, 4, 4],
      [1, 2, 4, 4, 4, 4, 4, 4, 3],
      [0, 1, 3, 4, 4, 3, 4, 3, 2],
      [1, 2, 2, 3, 3, 2, 3, 2, 1],
      [0, 1, 0, 1, 2, 1, 1, 0, 0]
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        7,
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing8 / 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              9,
              (c) => Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacing8 / 2),
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                      color: colors[pattern[r][c]],
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSmall / 3)),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0, 0),
                        delay: Duration(milliseconds: (r * 9 + c) * 25),
                        duration: 450.ms,
                        curve: Curves.easeOutBack)
                    .fadeIn(
                        delay: Duration(milliseconds: (r * 9 + c) * 25),
                        duration: 300.ms),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
