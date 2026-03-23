import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:github_wallpaper/data/models/app_models.dart';
import 'package:github_wallpaper/shared/state/app_state.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';
import 'package:github_wallpaper/core/utils/app_utils.dart';
import 'package:github_wallpaper/shared/services/membership_entitlements.dart';
import 'package:github_wallpaper/shared/services/share_utils.dart';
import 'package:github_wallpaper/shared/widgets/share_card.dart';

// ─────────────────────────────────────────────────────────────
// WRAPPED PAGE
// ─────────────────────────────────────────────────────────────

part 'wrapped_screen_view.dart';
part 'wrapped_screen_slide_shell.dart';
part 'wrapped_screen_recap.dart';
part 'wrapped_screen_cards.dart';

class WrappedScreen extends StatefulWidget {
  final CachedContributionData data;
  final String username;
  const WrappedScreen({super.key, required this.data, required this.username});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final _pc = PageController();
  int _currentPage = 0;

  // ── Derived stats ──────────────────────────────────────────
  late final List<ContributionDay> _yearDays;
  late final int _yearTotal;
  late final int _activeDays;
  late final ContributionDay? _bestDay;
  late final RepoContribution? _topRepo;
  late final LanguageUsage? _topLang;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 365));
    _yearDays = widget.data.days
        .where((d) => !d.date.isBefore(from) && !d.date.isAfter(now))
        .toList();
    _yearTotal = _yearDays.fold(0, (sum, d) => sum + d.contributionCount);
    _activeDays =
        _yearDays.fold(0, (sum, d) => sum + (d.contributionCount > 0 ? 1 : 0));
    _bestDay = _yearDays.isEmpty
        ? null
        : (List<ContributionDay>.from(_yearDays)
              ..sort(
                  (a, b) => b.contributionCount.compareTo(a.contributionCount)))
            .first;
    _topRepo = widget.data.repositories.isEmpty
        ? null
        : widget.data.repositories.first;
    _topLang = widget.data.topLanguages.isEmpty
        ? null
        : widget.data.topLanguages.first;
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _setCurrentPage(int page) {
    HapticFeedback.selectionClick();
    if (mounted) setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) => _buildWrappedScreen(context);
}
