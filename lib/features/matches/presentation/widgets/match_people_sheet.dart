import 'package:flutter/material.dart';

import '../../../../app/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/app_asset_icon.dart';
import '../../domain/match_people_data.dart';

Future<void> showMatchPeopleSheet({
  required BuildContext context,
  required String title,
  required List<MatchPerson> people,
  bool showInvitationStatus = false,
  Future<void> Function(MatchPerson person)? onPersonTap,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) {
      final maxListHeight = MediaQuery.sizeOf(sheetContext).height * 0.52;

      return Material(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheetTop),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.controlBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  14,
                  AppSpacing.pageHorizontal,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.homeGreeting),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.controlBorder),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: people.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.controlBorder),
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return _MatchPersonRow(
                      person: person,
                      showInvitationStatus: showInvitationStatus,
                      onTap: onPersonTap == null
                          ? null
                          : () async {
                              Navigator.of(sheetContext).pop();
                              await onPersonTap(person);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MatchPersonRow extends StatelessWidget {
  const _MatchPersonRow({
    required this.person,
    required this.showInvitationStatus,
    this.onTap,
  });

  final MatchPerson person;
  final bool showInvitationStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: onTap == null ? person.name : 'Open ${person.name} profile',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _PlayerAvatar(avatarUrl: person.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  person.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.homeMeta14.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showInvitationStatus && person.invitationStatus != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _InvitationStatusBadge(status: person.invitationStatus!),
              ],
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();

    Widget fallback() {
      return ColoredBox(
        color: AppColors.subtleSurface,
        child: Center(
          child: AppAssetIcon(
            assetPath: AppAssets.bottomProfileIcon,
            size: 22,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback(),
              )
            : fallback(),
      ),
    );
  }
}

class _InvitationStatusBadge extends StatelessWidget {
  const _InvitationStatusBadge({required this.status});

  final MatchInvitationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchInvitationStatus.pending => ('Pending', AppColors.primary),
      MatchInvitationStatus.accepted => ('Accepted', AppColors.matchSuccess),
      MatchInvitationStatus.declined => ('Declined', AppColors.destructive),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.homeMeta12.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
