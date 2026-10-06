import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../home/domain/home_match.dart';
import '../../home/presentation/widgets/match_card.dart';
import '../../matches/data/match_repository.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

enum ChatsTab { byMatch, byIndividualPlayer }

class JoinedMatchChatsScreen extends StatefulWidget {
  const JoinedMatchChatsScreen({
    required this.matchRepository,
    required this.chatRepository,
    required this.onStartMatchChat,
    required this.onOpenDirectChat,
    required this.onStartPlayerChat,
    super.key,
    this.onBack,
    this.onFindMatches,
  });

  final MatchRepository matchRepository;
  final ChatRepository chatRepository;
  final ValueChanged<HomeMatch> onStartMatchChat;
  final ValueChanged<DirectChatSummary> onOpenDirectChat;
  final ValueChanged<ChatParticipant> onStartPlayerChat;
  final VoidCallback? onBack;
  final VoidCallback? onFindMatches;

  @override
  State<JoinedMatchChatsScreen> createState() => _JoinedMatchChatsScreenState();
}

class _JoinedMatchChatsScreenState extends State<JoinedMatchChatsScreen> {
  final TextEditingController _searchController = TextEditingController();

  ChatsTab _selectedTab = ChatsTab.byMatch;
  List<HomeMatch> _matches = const <HomeMatch>[];
  List<DirectChatSummary> _directChats = const <DirectChatSummary>[];
  List<ChatParticipant> _searchResults = const <ChatParticipant>[];
  bool _loading = true;
  bool _searching = false;
  String? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.matchRepository.listMyMatches(perPage: 50);
      final directChats = await widget.chatRepository.listDirectChats();
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

      setState(() {
        _matches = matches;
        _directChats = directChats;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load chats. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectTab(ChatsTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
  }

  void _searchPlayers(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        _searching = false;
        _searchResults = const <ChatParticipant>[];
      });
      return;
    }

    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final results = await widget.chatRepository.searchUsers(query);
        if (!mounted || _searchController.text.trim() != query) return;
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      } catch (_) {
        if (!mounted || _searchController.text.trim() != query) return;
        setState(() {
          _searchResults = const <ChatParticipant>[];
          _searching = false;
        });
      }
    });
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.xxl,
                AppSpacing.pageHorizontal,
                0,
              ),
              child: _ChatsTabs(
                selectedTab: _selectedTab,
                onSelected: _selectTab,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: 60),
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

    return _selectedTab == ChatsTab.byMatch
        ? _buildMatchChats()
        : _buildIndividualChats();
  }

  Widget _buildMatchChats() {
    if (_matches.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          children: [
            const SizedBox(height: 60),
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
                    'Join a nearby match to start its group chat.',
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
          0,
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
            onTap: () => widget.onStartMatchChat(match),
            trailing: const _StartChatBadge(),
          );
        },
      ),
    );
  }

  Widget _buildIndividualChats() {
    final query = _searchController.text.trim();
    final isSearching = query.length >= 2;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          0,
          AppSpacing.pageHorizontal,
          AppSpacing.xxl,
        ),
        children: [
          AppTextField(
            controller: _searchController,
            hintText: 'Search users',
            leadingIcon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onChanged: _searchPlayers,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isSearching) ...[
            Text('Search Results', style: AppTypography.homeSectionHeading),
            const SizedBox(height: AppSpacing.sm),
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(child: AppLoader()),
              )
            else if (_searchResults.isEmpty)
              const _ChatStateMessage(message: 'No users found')
            else
              ..._searchResults.map(
                (player) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ChatPlayerCard(
                    participant: player,
                    subtitle: 'Start individual chat',
                    onTap: () => widget.onStartPlayerChat(player),
                  ),
                ),
              ),
          ] else ...[
            Text(
              'Individual Players',
              style: AppTypography.homeSectionHeading,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_directChats.isEmpty)
              const _ChatStateMessage(
                message:
                    'No individual chats yet. Search for a player to start one.',
              )
            else
              ..._directChats.map(
                (chat) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ChatPlayerCard(
                    participant: chat.participant,
                    subtitle: (chat.lastMessageText?.trim().isNotEmpty ?? false)
                        ? chat.lastMessageText!
                        : 'Open individual chat',
                    onTap: () => widget.onOpenDirectChat(chat),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ChatsTabs extends StatelessWidget {
  const _ChatsTabs({
    required this.selectedTab,
    required this.onSelected,
  });

  final ChatsTab selectedTab;
  final ValueChanged<ChatsTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChatTabButton(
            label: 'By Match',
            selected: selectedTab == ChatsTab.byMatch,
            onTap: () => onSelected(ChatsTab.byMatch),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChatTabButton(
            label: 'By Individual Player',
            selected: selectedTab == ChatsTab.byIndividualPlayer,
            onTap: () => onSelected(ChatsTab.byIndividualPlayer),
          ),
        ),
      ],
    );
  }
}

class _ChatTabButton extends StatelessWidget {
  const _ChatTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      onTap: onTap,
      minHeight: 42,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: selected ? AppColors.primary : AppColors.subtleSurface,
      borderColor: selected ? AppColors.primary : AppColors.controlBorder,
      child: Center(
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.homeMeta14.copyWith(
            color: selected ? Colors.white : AppColors.heading,
          ),
        ),
      ),
    );
  }
}

class _ChatPlayerCard extends StatelessWidget {
  const _ChatPlayerCard({
    required this.participant,
    required this.subtitle,
    required this.onTap,
  });

  final ChatParticipant participant;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppAvatar(
            fallbackAsset: participant.avatarAsset.isEmpty
                ? AppAssets.bottomProfileIcon
                : participant.avatarAsset,
            imageUrl: participant.avatarUrl,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.homeMatchTitle16,
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.homeMeta12,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _StartChatBadge(),
        ],
      ),
    );
  }
}

class _ChatStateMessage extends StatelessWidget {
  const _ChatStateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      minHeight: 110,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.body14,
        ),
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
