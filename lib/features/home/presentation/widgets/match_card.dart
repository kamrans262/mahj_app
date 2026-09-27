import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/home_match.dart';
import '../home_date_time_formatter.dart';
import 'match_status_badge.dart';
import 'sport_icon.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    required this.match,
    super.key,
    this.onTap,
    this.showStatus = true,
    this.showPlayerCount = true,
    this.subtitle,
    this.surfaceColor,
    this.titleStyle,
    this.sportIconSize = 24,
    this.footer,
  });

  final HomeMatch match;
  final VoidCallback? onTap;
  final bool showStatus;
  final bool showPlayerCount;
  final String? subtitle;
  final Color? surfaceColor;
  final TextStyle? titleStyle;
  final double sportIconSize;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final resolvedSubtitle = subtitle ?? match.location;
    final resolvedSurface =
        surfaceColor ?? AppColors.nearbyMatchCardSurface;

    return Semantics(
      button: onTap != null,
      label: '${match.sportName} match, $resolvedSubtitle',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.subtleShadow,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: resolvedSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.subtleBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primary.withValues(alpha: 0.03);
              }
              return Colors.transparent;
            }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 108),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SportIcon(
                          match: match,
                          size: sportIconSize,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.sportName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    titleStyle ??
                                    AppTypography.homeMatchTitle16,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                resolvedSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.homeMeta12,
                              ),
                            ],
                          ),
                        ),
                        if (showStatus) ...[
                          const SizedBox(width: 10),
                          MatchStatusBadge(status: match.status),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 14),
                    _MetadataRow(
                      match: match,
                      showPlayerCount: showPlayerCount,
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 20),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.match,
    required this.showPlayerCount,
  });

  final HomeMatch match;
  final bool showPlayerCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final children = <Widget>[
          MatchMetadataItem(
            icon: Icons.calendar_today,
            text: HomeDateTimeFormatter.compactDate(match.startsAt),
          ),
          MatchMetadataItem(
            icon: Icons.access_time,
            text: HomeDateTimeFormatter.time(match.startsAt),
          ),
          if (showPlayerCount)
            MatchMetadataItem(
              text:
                  '${match.currentPlayers}/${match.maxPlayers} Players',
            ),
        ];

        if (children.length == 2) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: children[0]),
              const SizedBox(width: 12),
              Flexible(child: children[1]),
            ],
          );
        }

        if (constraints.maxWidth < 315) {
          return Wrap(
            spacing: 16,
            runSpacing: 10,
            children: children,
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: children[0]),
            const SizedBox(width: 8),
            Flexible(child: children[1]),
            const SizedBox(width: 8),
            Flexible(child: children[2]),
          ],
        );
      },
    );
  }
}

class MatchMetadataItem extends StatelessWidget {
  const MatchMetadataItem({
    required this.text,
    super.key,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6E8668),
          ),
          const SizedBox(width: 7),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.homeMeta12,
          ),
        ),
      ],
    );
  }
}
