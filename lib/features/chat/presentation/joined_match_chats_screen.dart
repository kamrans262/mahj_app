import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../../matches/data/match_repository.dart';

class JoinedMatchChatsScreen extends StatefulWidget {
  const JoinedMatchChatsScreen({
    required this.repository,
    required this.onStartChat,
    super.key,
    this.onBack,
    this.onFindMatches,
  });

  final MatchRepository repository;
  final ValueChanged<HomeMatch> onStartChat;
  final VoidCallback? onBack;
  final VoidCallback? onFindMatches;

  @override
  State<JoinedMatchChatsScreen> createState() => _JoinedMatchChatsScreenState();
}

class _JoinedMatchChatsScreenState extends State<JoinedMatchChatsScreen> {
  List<HomeMatch> _matches = const <HomeMatch>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.repository.listMyMatches(perPage: 50);
      if (!mounted) return;

      final matches = data.upcoming
          .map((item) => item.match)
          .where(
            (match) =>
                match.isCurrentUserJoined &&
                match.status != MatchStatus.cancelled &&
                match.status != MatchStatus.completed,
          )
          .toList(growable: false)
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

      setState(() => _matches = matches);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your joined matches. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: AppCenteredPageHeader(
                title: 'Chats',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: AppLoader());
    }

    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          children: [
            const SizedBox(height: 80),
            AppSurfaceContainer(
              minHeight: 120,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body14,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _load,
                    child: Text('Retry', style: AppTypography.action14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          children: [
            const SizedBox(height: 80),
            AppSurfaceContainer(
              minHeight: 180,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 38,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No Joined Matches',
                    textAlign: TextAlign.center,
                    style: AppTypography.title18,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Join a nearby match to start chatting with its players.',
                    textAlign: TextAlign.center,
                    style: AppTypography.homeMeta14,
                  ),
                  if (widget.onFindMatches != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: 'Find Matches',
                      onPressed: widget.onFindMatches,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.xl,
          AppSpacing.pageHorizontal,
          AppSpacing.xxl,
        ),
        itemCount: _matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final match = _matches[index];

          return MatchCard(
            key: ValueKey('chat-match-${match.id}'),
            match: match,
            onTap: () => widget.onStartChat(match),
            trailing: const _StartChatBadge(),
          );
        },
      ),
    );
  }
}

class _StartChatBadge extends StatelessWidget {
  const _StartChatBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('start-chat-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        'Start Chat',
        maxLines: 1,
        style: AppTypography.homeMeta12.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
