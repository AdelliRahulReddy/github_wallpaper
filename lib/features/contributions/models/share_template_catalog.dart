import 'package:flutter/material.dart';

enum ShareCardFamily {
  dailyFlex,
  repoFocus,
  streakMilestone,
  monthlySnapshot,
  wrapped,
}

enum ShareExportFormat {
  story,
}

class ShareTemplateDefinition {
  final ShareCardFamily family;
  final String label;
  final String subtitle;
  final String purpose;
  final String bestFor;
  final IconData icon;
  final ShareExportFormat defaultFormat;
  final Set<ShareExportFormat> supportedFormats;
  final bool isCoreTemplate;

  const ShareTemplateDefinition({
    required this.family,
    required this.label,
    required this.subtitle,
    required this.purpose,
    required this.bestFor,
    required this.icon,
    required this.defaultFormat,
    required this.supportedFormats,
    this.isCoreTemplate = true,
  });
}

class ShareTemplateCatalog {
  static const List<ShareCardFamily> coreFamilies = [
    ShareCardFamily.dailyFlex,
    ShareCardFamily.repoFocus,
    ShareCardFamily.streakMilestone,
    ShareCardFamily.monthlySnapshot,
  ];

  static const Map<ShareCardFamily, ShareTemplateDefinition> _definitions = {
    ShareCardFamily.dailyFlex: ShareTemplateDefinition(
      family: ShareCardFamily.dailyFlex,
      label: 'Daily Flex',
      subtitle: 'Today, streak, and momentum.',
      purpose: 'High-frequency share for everyday progress and consistency.',
      bestFor: 'A strong day, a visible comeback, or a clean momentum update.',
      icon: Icons.today_rounded,
      defaultFormat: ShareExportFormat.story,
      supportedFormats: {
        ShareExportFormat.story,
      },
    ),
    ShareCardFamily.repoFocus: ShareTemplateDefinition(
      family: ShareCardFamily.repoFocus,
      label: 'Repo Focus',
      subtitle: 'Spotlight one repository.',
      purpose: 'Project-led share when one repository carries the story.',
      bestFor: 'Launches, concentrated build sprints, and project visibility.',
      icon: Icons.folder_open_rounded,
      defaultFormat: ShareExportFormat.story,
      supportedFormats: {
        ShareExportFormat.story,
      },
    ),
    ShareCardFamily.streakMilestone: ShareTemplateDefinition(
      family: ShareCardFamily.streakMilestone,
      label: 'Streak Milestone',
      subtitle: 'Celebrate a streak milestone.',
      purpose: 'Retention-focused share built around streak motivation.',
      bestFor: '7-day, 14-day, 30-day, and larger streak checkpoints.',
      icon: Icons.local_fire_department_rounded,
      defaultFormat: ShareExportFormat.story,
      supportedFormats: {
        ShareExportFormat.story,
      },
    ),
    ShareCardFamily.monthlySnapshot: ShareTemplateDefinition(
      family: ShareCardFamily.monthlySnapshot,
      label: 'Monthly Snapshot',
      subtitle: 'Month-to-date performance.',
      purpose:
          'Reflective share that summarizes progress over a broader window.',
      bestFor: 'End-of-month recaps, progress check-ins, and growth posts.',
      icon: Icons.calendar_month_rounded,
      defaultFormat: ShareExportFormat.story,
      supportedFormats: {
        ShareExportFormat.story,
      },
    ),
    ShareCardFamily.wrapped: ShareTemplateDefinition(
      family: ShareCardFamily.wrapped,
      label: 'Wrapped',
      subtitle: 'Yearly recap and highlights.',
      purpose: 'Seasonal recap asset outside the core share template set.',
      bestFor: 'Longer recap moments and year-end storytelling.',
      icon: Icons.auto_awesome_rounded,
      defaultFormat: ShareExportFormat.story,
      supportedFormats: {
        ShareExportFormat.story,
      },
      isCoreTemplate: false,
    ),
  };

  static ShareTemplateDefinition definitionFor(ShareCardFamily family) {
    return _definitions[family]!;
  }

  static List<ShareCardFamily> orderedCoreFamilies({
    ShareCardFamily? recommendation,
    ShareCardFamily? selected,
  }) {
    final ordered = <ShareCardFamily>[];
    if (selected != null && !_definitions[selected]!.isCoreTemplate) {
      ordered.add(selected);
    }
    if (recommendation != null && !ordered.contains(recommendation)) {
      ordered.add(recommendation);
    }
    for (final family in coreFamilies) {
      if (!ordered.contains(family)) {
        ordered.add(family);
      }
    }
    return ordered;
  }
}

extension ShareCardFamilyX on ShareCardFamily {
  ShareTemplateDefinition get definition =>
      ShareTemplateCatalog.definitionFor(this);

  String get label => definition.label;
  String get subtitle => definition.subtitle;
  String get purpose => definition.purpose;
  String get bestFor => definition.bestFor;
  IconData get icon => definition.icon;
  ShareExportFormat get defaultFormat => definition.defaultFormat;
  Set<ShareExportFormat> get supportedFormats => definition.supportedFormats;
  bool get isCoreTemplate => definition.isCoreTemplate;

  bool supportsFormat(ShareExportFormat format) =>
      supportedFormats.contains(format);
}

extension ShareExportFormatX on ShareExportFormat {
  String get label => switch (this) {
        ShareExportFormat.story => 'Story 9:16',
      };

  bool get isStory => this == ShareExportFormat.story;

  double get aspectRatio => switch (this) {
        ShareExportFormat.story => 9 / 16,
      };

  EdgeInsets get framePadding => switch (this) {
        ShareExportFormat.story => const EdgeInsets.all(14),
      };
}
