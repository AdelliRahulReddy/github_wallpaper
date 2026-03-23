part of 'wrapped_screen.dart';

class _WrappedSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;
  final Widget child;

  const _WrappedSlide({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.h8,
        Text(
          title,
          style: (textTheme.displaySmall ?? const TextStyle(fontSize: 26))
              .copyWith(
            color: scheme.onSurface,
            height: 1.08,
            letterSpacing: -1.2,
          ),
        ),
        AppTheme.h6,
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTheme.fontBase,
            color: scheme.onSurface.withValues(alpha: 0.60),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppTheme.h24,
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: AppTheme.pAll24,
            child: child,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RECAP SLIDE  (slide 7 — final screen with share)
// ─────────────────────────────────────────────────────────────
