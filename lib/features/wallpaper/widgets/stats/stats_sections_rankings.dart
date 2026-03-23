part of 'stats_sections.dart';

class StatsTopLanguagesCard extends StatelessWidget {
  final List<LanguageUsage> langs;

  const StatsTopLanguagesCard({super.key, required this.langs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = langs.take(7).toList();
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT TOP LANGUAGES',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: AppTheme.pAll16,
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                _LangRow(lang: list[i]),
                if (i != list.length - 1)
                  Divider(height: 20, color: scheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LangRow extends StatelessWidget {
  final LanguageUsage lang;

  const _LangRow({required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = AppColorUtils.parseHexColor(lang.color) ?? scheme.primary;
    final pct = (lang.percent * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            AppTheme.w12,
            Expanded(
              child: Text(lang.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text('$pct%',
                style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
        AppTheme.h10,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: lang.percent.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: scheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}

class StatsTopReposCard extends StatelessWidget {
  final List<RepoContribution> repos;

  const StatsTopReposCard({super.key, required this.repos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final list = repos.where((r) => r.commitCount > 0).toList()
      ..sort((a, b) => b.commitCount.compareTo(a.commitCount));
    final top = list.take(6).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT TOP REPOS',
          style: tt.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        AppTheme.h12,
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < top.length; i++) ...[
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColorUtils.parseHexColor(
                              top[i].primaryLanguageColor) ??
                          scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  title: Row(
                    children: [
                      if (top[i].isPrivate) ...[
                        Icon(Icons.lock_outline_rounded,
                            size: AppTheme.iconSM,
                            color: scheme.onSurfaceVariant),
                        AppTheme.w6,
                      ],
                      Expanded(
                        child: Text(
                          top[i].nameWithOwner,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: top[i].primaryLanguageName == null
                      ? null
                      : Text(top[i].primaryLanguageName!,
                          style: tt.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                  trailing: Text(
                    '${top[i].commitCount}',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (i != top.length - 1)
                  Divider(height: 1, color: scheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
