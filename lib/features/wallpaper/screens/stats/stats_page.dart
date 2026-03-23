import 'package:flutter/material.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/features/settings/screens/membership_paywall_page.dart';
import 'package:github_wallpaper/features/wallpaper/widgets/stats/stats_sections.dart';
import 'package:github_wallpaper/shared/services/membership_entitlements.dart';
import 'package:github_wallpaper/shared/widgets/app_components.dart';
import 'package:intl/intl.dart';

part 'stats_page_state.dart';
part 'stats_page_header.dart';

class StatsPage extends StatefulWidget {
  final CachedContributionData? data;
  final bool isLoading;
  final String? loadError;
  final Future<void> Function() onRefresh;

  const StatsPage({
    super.key,
    required this.data,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int? _selectedYear;

  Future<void> _pickYear(List<int> years, int activeYear) async {
    if (!MembershipEntitlements.canUseAdvancedStats) return;
    final scheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.brVertLarge),
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: years.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Theme.of(ctx).dividerColor),
            itemBuilder: (ctx, index) {
              final year = years[index];
              final selected = year == activeYear;
              return ListTile(
                title: Text(
                  '$year',
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: scheme.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(year),
              );
            },
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() => _selectedYear = picked);
  }

  @override
  Widget build(BuildContext context) => _buildStatsPage(context);
}
