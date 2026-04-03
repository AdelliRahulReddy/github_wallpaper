import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/ui/app_components.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading home dashboard',
      child: SafeArea(
        child: SingleChildScrollView(
          key: const Key('home-page-skeleton'),
          physics: const NeverScrollableScrollPhysics(),
          padding: AppTheme.pagePadding(context).copyWith(
            top: AppTheme.spacing16,
            bottom: AppTheme.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  SkeletonBox(
                    height: 44,
                    width: 44,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 18, width: 140),
                        SizedBox(height: AppTheme.spacing8),
                        SkeletonBox(height: 12, width: 108),
                      ],
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing12),
                  SkeletonBox(
                    height: 36,
                    width: 36,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ],
              ),
              AppTheme.h20,
              const _SkeletonCard(
                height: 212,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 12, width: 52),
                    SizedBox(height: AppTheme.spacing12),
                    SkeletonBox(height: 56, width: 116),
                    SizedBox(height: AppTheme.spacing16),
                    SkeletonBox(
                      height: 36,
                      width: 188,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    SizedBox(height: AppTheme.spacing12),
                    Row(
                      children: [
                        SkeletonBox(
                          height: 32,
                          width: 126,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        SizedBox(width: AppTheme.spacing8),
                        SkeletonBox(
                          height: 32,
                          width: 126,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacing16),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 48)),
                        SizedBox(width: AppTheme.spacing12),
                        Expanded(child: SkeletonBox(height: 48)),
                      ],
                    ),
                  ],
                ),
              ),
              AppTheme.h16,
              const _SkeletonCard(
                height: 116,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(height: 14, width: 92),
                        Spacer(),
                        SkeletonBox(height: 14, width: 104),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacing12),
                    SkeletonBox(
                      height: 10,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    SizedBox(height: AppTheme.spacing12),
                    SkeletonBox(height: 14, width: 172),
                  ],
                ),
              ),
              AppTheme.h16,
              const _SkeletonCard(
                height: 168,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 12, width: 124),
                    SizedBox(height: AppTheme.spacing12),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 72)),
                        SizedBox(width: AppTheme.spacing12),
                        Expanded(child: SkeletonBox(height: 72)),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacing12),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 72)),
                        SizedBox(width: AppTheme.spacing12),
                        Expanded(child: SkeletonBox(height: 72)),
                      ],
                    ),
                  ],
                ),
              ),
              AppTheme.h16,
              const _SkeletonCard(
                height: 132,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(height: 14, width: 102),
                        Spacer(),
                        SkeletonBox(height: 14, width: 64),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacing12),
                    SkeletonBox(height: 44, width: 96),
                    SizedBox(height: AppTheme.spacing12),
                    SkeletonBox(
                      height: 10,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    SizedBox(height: AppTheme.spacing12),
                    SkeletonBox(height: 14, width: 196),
                  ],
                ),
              ),
              AppTheme.h24,
              const SkeletonBox(height: 12, width: 96),
              AppTheme.h12,
              const _SkeletonCard(height: 124),
              AppTheme.h16,
              const _SkeletonCard(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsPageSkeleton extends StatelessWidget {
  const StatsPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading stats dashboard',
      child: SafeArea(
        child: SingleChildScrollView(
          key: const Key('stats-page-skeleton'),
          physics: const NeverScrollableScrollPhysics(),
          padding: AppTheme.pagePadding(context).copyWith(
            top: AppTheme.spacing16,
            bottom: AppTheme.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Expanded(child: SkeletonBox(height: 24, width: 84)),
                  SizedBox(width: AppTheme.spacing12),
                  SkeletonBox(
                    height: 36,
                    width: 90,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ],
              ),
              AppTheme.h16,
              const _SkeletonCard(height: 86),
              AppTheme.h16,
              const _SkeletonCard(height: 272),
              AppTheme.h16,
              const _SkeletonCard(
                height: 212,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 12, width: 84),
                    SizedBox(height: AppTheme.spacing12),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 76)),
                        SizedBox(width: AppTheme.spacing12),
                        Expanded(child: SkeletonBox(height: 76)),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacing12),
                    Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 76)),
                        SizedBox(width: AppTheme.spacing12),
                        Expanded(child: SkeletonBox(height: 76)),
                      ],
                    ),
                  ],
                ),
              ),
              AppTheme.h16,
              const _SkeletonCard(height: 184),
              AppTheme.h16,
              const _SkeletonCard(height: 200),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  final Widget? child;

  const _SkeletonCard({
    required this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: child ??
          SizedBox(
            height: height,
            child: const SkeletonBox(
              height: double.infinity,
              width: double.infinity,
            ),
          ),
    );
  }
}
