part of 'customize_screen.dart';

extension _CustomizePageStateThemeGallery on _CustomizePageState {
  Widget _buildThemeGallery({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required bool isAppDark,
  }) {
    final themes = ThemePresets.all;

    return Column(
      children: [
        SizedBox(
          height: 104,
          child: Stack(
            children: [
              PageView.builder(
                controller: _themeController,
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final themePreset = themes[index];
                  final isUnlocked =
                      MembershipEntitlements.isThemeUnlocked(themePreset.id);
                  final isSelected = _config.themeId == themePreset.id;
                  final levels = ThemePresets.levelsFor(
                    themePreset.id,
                    isDarkMode: _config.isDarkMode,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppTheme.brLarge,
                        onTap: () async {
                          if (!isUnlocked) {
                            final unlocked = await _promptForLockedAccess(
                              featureName: themePreset.label,
                              featureDescription:
                                  '${themePreset.label} is a Pro palette. Claim access to use the full color system.',
                            );
                            if (!unlocked || !mounted) return;
                          }
                          HapticFeedback.selectionClick();
                          _updateConfig(
                            _config.copyWith(themeId: themePreset.id),
                          );
                        },
                        child: AnimatedContainer(
                          duration: AppTheme.durationFast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.brLarge,
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outlineVariant.withValues(
                                      alpha: isAppDark ? 0.65 : 0.45,
                                    ),
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected
                                ? scheme.primary.withValues(
                                    alpha: isAppDark ? 0.18 : 0.08,
                                  )
                                : (isAppDark
                                    ? scheme.surface.withValues(alpha: 0.85)
                                    : scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.55)),
                            boxShadow: isAppDark
                                ? AppTheme.shadow(
                                    scheme.shadow,
                                    blur: 18,
                                    opacity: isSelected ? 0.18 : 0.12,
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${themePreset.emoji} ${themePreset.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: isSelected
                                            ? scheme.primary
                                            : scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: scheme.primary
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 12,
                                            color: scheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pro',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (themePreset.id == 'github')
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 72),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scheme.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: scheme.primary
                                                  .withValues(alpha: 0.20),
                                            ),
                                          ),
                                          child: Text(
                                            'Default',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: scheme.primary,
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: scheme.surface
                                            .withValues(alpha: 0.35),
                                        border: Border.all(
                                          color: scheme.outline
                                              .withValues(alpha: 0.20),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          for (int i = 0;
                                              i < levels.length;
                                              i++)
                                            Expanded(
                                              child: Container(
                                                margin: EdgeInsets.only(
                                                  right: i == levels.length - 1
                                                      ? 0
                                                      : 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: levels[i],
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: levels[4].withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            levels[4].withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Aa',
                                        style: textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: IgnorePointer(
                  child: Container(
                    width: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          scheme.surface.withValues(alpha: 0.92),
                          scheme.surface.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IgnorePointer(
                  child: Container(
                    width: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          scheme.surface.withValues(alpha: 0.92),
                          scheme.surface.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SmoothPageIndicator(
            controller: _themeController,
            count: themes.length,
            effect: ExpandingDotsEffect(
              activeDotColor: scheme.primary,
              dotColor: scheme.outline.withValues(alpha: 0.25),
              dotHeight: 7,
              dotWidth: 7,
              expansionFactor: 3.2,
              spacing: 6,
            ),
          ),
        ),
        if (!MembershipEntitlements.hasProAccess) ...[
          const SizedBox(height: 10),
          Text(
            'Free includes the essential palettes. Locked palettes stay visible so you can preview what Pro unlocks.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ],
      ],
    );
  }
}
