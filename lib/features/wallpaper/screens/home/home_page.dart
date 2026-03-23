import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/features/settings/screens/membership_paywall_page.dart';
import 'package:github_wallpaper/features/settings/screens/settings_screen.dart';
import 'package:github_wallpaper/shared/services/daily_quotes.dart';
import 'package:github_wallpaper/shared/services/achievement_service.dart';
import 'package:github_wallpaper/shared/services/membership_entitlements.dart';
import 'package:github_wallpaper/shared/services/share_utils.dart';
import 'package:github_wallpaper/data/datasources/local/storage_service.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/shared/widgets/app_components.dart';
import 'package:intl/intl.dart';

part 'home_page_view.dart';
part 'home_page_feed.dart';
part 'home_page_streaks.dart';
part 'home_page_heatmap.dart';
part 'home_page_insights.dart';
part 'home_page_achievements.dart';

class HomePage extends StatefulWidget {
  final CachedContributionData? data;
  final bool isLoading;
  final String? loadError;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenStats;

  const HomePage({
    super.key,
    required this.data,
    required this.isLoading,
    required this.loadError,
    required this.onRefresh,
    required this.onOpenStats,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  TrendSummary _trend7d = const TrendSummary(current: 0, previous: 0);
  TrendSummary _trend30d = const TrendSummary(current: 0, previous: 0);
  bool _isSharing = false;
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderCompact = false;

  @override
  void initState() {
    super.initState();
    _setTrends(widget.data);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _setTrends(widget.data);
    }
  }

  void _setTrends(CachedContributionData? data) {
    if (data == null) {
      _trend7d = const TrendSummary(current: 0, previous: 0);
      _trend30d = const TrendSummary(current: 0, previous: 0);
      return;
    }
    _trend7d = ContributionAnalyzer.computeTrend(
      data.days,
      window: 7,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
    _trend30d = ContributionAnalyzer.computeTrend(
      data.days,
      window: 30,
      dateOf: (day) => day.date,
      countOf: (day) => day.contributionCount,
    );
  }

  void _handleScroll() {
    final shouldCompact = _scrollController.hasClients &&
        _scrollController.offset > AppTheme.spacing12;
    if (shouldCompact == _isHeaderCompact || !mounted) return;
    setState(() => _isHeaderCompact = shouldCompact);
  }

  void _showDayDetail(ContributionDay day) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.brVertLarge),
      builder: (ctx) {
        final label = DateFormat('EEEE, d MMMM yyyy').format(day.date);
        return Padding(
          padding: AppTheme.pAll24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
              ),
              Text(
                label,
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  fontSize: AppTheme.fontBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppTheme.h8,
              Text(
                '${day.contributionCount} contribution${day.contributionCount == 1 ? '' : 's'}',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppTheme.fontHeadline,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              AppTheme.h20,
            ],
          ),
        );
      },
    );
  }

  String _headerDisplayName() {
    final preferredName = StorageService.getDisplayName()?.trim();
    if (preferredName != null && preferredName.isNotEmpty) {
      return preferredName;
    }

    var username = StorageService.getUsername()?.trim() ?? '';
    if (username.isEmpty) return 'there';
    username = username[0].toUpperCase() + username.substring(1);
    return username;
  }

  String _compactHeaderName() {
    final fullName = _headerDisplayName().trim();
    if (fullName.isEmpty) return 'there';

    final segments = fullName
        .split(RegExp(r'(?<=[a-z])(?=[A-Z])|[\s_.-]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (segments.isNotEmpty) {
      final first = segments.first.trim();
      if (first.length <= 12) return first;
    }

    if (fullName.length <= 14) return fullName;
    return fullName.substring(0, 14).trim();
  }

  String _headerAvatarSeed() {
    final preferredName = StorageService.getDisplayName()?.trim();
    if (preferredName != null && preferredName.isNotEmpty) {
      return preferredName;
    }
    return StorageService.getUsername()?.trim() ?? '';
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openShareSheet(
    CachedContributionData data,
    TrendSummary trend7d,
    TrendSummary trend30d,
  ) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await ShareUtils.shareCard(
        context: context,
        data: data,
        trend7d: trend7d,
        trend30d: trend30d,
      );
    } catch (e, s) {
      AppLog.error(e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.shareError,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildErrorState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppTheme.pAll32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: scheme.onSurface.withValues(alpha: 0.35)),
            AppTheme.h16,
            Text(
              AppStrings.loadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: AppTheme.fontTitle,
                fontWeight: FontWeight.w900,
              ),
            ),
            AppTheme.h8,
            Text(
              widget.loadError ?? AppStrings.unknownError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.65),
                fontSize: AppTheme.fontBody,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            AppTheme.h24,
            FilledButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String username, ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: AppTheme.fontTitle,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildHomePage(context);
}
