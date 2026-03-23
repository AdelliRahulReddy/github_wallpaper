part of 'wrapped_screen.dart';

class _BigNumber extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _BigNumber(
      {required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.72),
          ),
        ),
        AppTheme.h12,
        Text(
          value,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MINI STAT CARD
// ─────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _MiniStatCard(
      {required this.label,
      required this.value,
      required this.accent,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: AppTheme.brLarge,
        color: scheme.surface.withValues(alpha: 0.60),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          AppTheme.h12,
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontCaption,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          AppTheme.h4,
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REPO CARD
// ─────────────────────────────────────────────────────────────
class _RepoCard extends StatelessWidget {
  final RepoContribution repo;
  const _RepoCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          repo.nameWithOwner,
          style: TextStyle(
            fontSize: AppTheme.fontLarge,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        AppTheme.h12,
        Text(
          '${PresentationFormatter.formatCompactNumber(repo.commitCount)} commits',
          style: TextStyle(
            fontSize: AppTheme.fontTitle,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.80),
          ),
        ),
        if (repo.primaryLanguageName != null) ...[
          AppTheme.h8,
          Text(
            repo.primaryLanguageName!,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LANGUAGE CARD  (uses real language color)
// ─────────────────────────────────────────────────────────────
class _LanguageCard extends StatelessWidget {
  final LanguageUsage lang;
  const _LanguageCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = '${(lang.percent * 100).toStringAsFixed(0)}%';

    final langColor = AppColorUtils.parseHexColor(lang.color) ?? scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language color dot
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: langColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: langColor.withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
            AppTheme.w8,
            Text(
              lang.name,
              style: TextStyle(
                fontSize: AppTheme.fontBase,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
        AppTheme.h16,
        // Large name in language color
        Text(
          lang.name,
          style: TextStyle(
            fontSize: AppTheme.fontDisplay + AppTheme.spacing8,
            fontWeight: FontWeight.w900,
            color: langColor,
            height: 1.0,
            letterSpacing: -1.5,
          ),
        ),
        AppTheme.h8,
        Text(
          '$pct of your codebase',
          style: TextStyle(
            fontSize: AppTheme.fontTitle,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            color: scheme.onSurface.withValues(alpha: 0.55)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
