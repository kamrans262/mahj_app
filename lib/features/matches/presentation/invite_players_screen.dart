import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_success_message.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../home/domain/home_match.dart';
import '../domain/invite_player_result.dart';
import 'widgets/invite_result_card.dart';

typedef InvitePlayerSearchCallback = Future<List<InvitePlayerResult>> Function(
  String query,
);
typedef SendMatchInvitesCallback = Future<void> Function(
  String matchId,
  Set<String> inviteTargetIds,
);
typedef InvitationPreviewCallback = VoidCallback;

class InvitePlayersScreen extends StatefulWidget {
  const InvitePlayersScreen({
    required this.match,
    super.key,
    this.initialResults = const [],
    this.onBack,
    this.onSearchUsers,
    this.onSendInvites,
    this.onPreviewInvitationReceived,
  });

  final HomeMatch match;
  final List<InvitePlayerResult> initialResults;
  final VoidCallback? onBack;
  final InvitePlayerSearchCallback? onSearchUsers;
  final SendMatchInvitesCallback? onSendInvites;
  final InvitationPreviewCallback? onPreviewInvitationReceived;

  @override
  State<InvitePlayersScreen> createState() => _InvitePlayersScreenState();
}

class _InvitePlayersScreenState extends State<InvitePlayersScreen> {
  final _searchController = TextEditingController();
  final _selectedInviteIds = <String>{};

  Timer? _searchDebounce;
  late List<InvitePlayerResult> _sourceResults;
  late List<InvitePlayerResult> _visibleResults;
  String? _searchError;
  bool _isSearching = false;
  bool _isSending = false;
  bool _inviteSucceeded = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _sourceResults = List<InvitePlayerResult>.of(widget.initialResults);
    _visibleResults = List<InvitePlayerResult>.of(widget.initialResults);
  }

  @override
  void didUpdateWidget(covariant InvitePlayersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id ||
        oldWidget.initialResults != widget.initialResults) {
      _sourceResults = List<InvitePlayerResult>.of(widget.initialResults);
      _visibleResults = List<InvitePlayerResult>.of(widget.initialResults);
      _selectedInviteIds.clear();
      _searchController.clear();
      _searchError = null;
      _inviteSucceeded = false;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(value.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    final callback = widget.onSearchUsers;

    if (callback == null) {
      final normalized = query.toLowerCase();
      if (!mounted) return;
      setState(() {
        _searchError = null;
        _visibleResults = normalized.isEmpty
            ? List<InvitePlayerResult>.of(_sourceResults)
            : _sourceResults
                  .where(
                    (result) =>
                        result.searchText.toLowerCase().contains(normalized) ||
                        result.title.toLowerCase().contains(normalized),
                  )
                  .toList(growable: false);
      });
      return;
    }

    final generation = ++_searchGeneration;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await callback(query);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _sourceResults = List<InvitePlayerResult>.of(results);
        _visibleResults = List<InvitePlayerResult>.of(results);
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchError = 'Could not load users. Please try again.';
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _toggleSelection(InvitePlayerResult result) {
    setState(() {
      _inviteSucceeded = false;
      if (!_selectedInviteIds.add(result.id)) {
        _selectedInviteIds.remove(result.id);
      }
    });
  }

  Future<void> _sendInvites() async {
    if (_isSending) return;

    if (_selectedInviteIds.isEmpty) {
      _showMessage('Select at least one user to invite.');
      return;
    }

    final callback = widget.onSendInvites;
    if (callback == null) {
      final previewCallback = widget.onPreviewInvitationReceived;
      if (previewCallback != null) {
        previewCallback();
        return;
      }

      _showMessage('Invitations are not connected yet.');
      return;
    }

    setState(() {
      _isSending = true;
      _inviteSucceeded = false;
    });

    try {
      await callback(
        widget.match.id,
        Set<String>.unmodifiable(_selectedInviteIds),
      );
      if (!mounted) return;
      setState(() => _inviteSucceeded = true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not send the invite. Please try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('invite-players-screen'),
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
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
                  title: 'Match Details',
                  onBack:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.xl,
                    AppSpacing.pageHorizontal,
                    0,
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _searchController,
                        hintText: 'Search Users',
                        leadingIcon: Icons.search_rounded,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onFieldSubmitted: (value) {
                          _searchDebounce?.cancel();
                          _runSearch(value.trim());
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(child: _buildResults()),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sm,
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton.primary(
                        key: const ValueKey('invite-players-send'),
                        label: 'Send invite',
                        isLoading: _isSending,
                        isEnabled: !_isSending,
                        onPressed: _sendInvites,
                      ),
                      if (_inviteSucceeded) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const AppSuccessMessage(
                          message: 'Invite Sent Successfully!',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(child: AppLoader(color: AppColors.primary));
    }

    if (_searchError != null) {
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          AppSurfaceContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _searchError!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body14,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.compactSecondary(
                  label: 'Retry',
                  onPressed: () => _runSearch(_searchController.text.trim()),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_visibleResults.isEmpty) {
      return const Center(
        child: AppSurfaceContainer(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Text(
            'No users found',
            textAlign: TextAlign.center,
            style: AppTypography.body14,
          ),
        ),
      );
    }

    return ListView.separated(
      key: const ValueKey('invite-players-results'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _visibleResults.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final result = _visibleResults[index];
        return InviteResultCard(
          key: ValueKey('invite-result-${result.id}'),
          result: result,
          isSelected: _selectedInviteIds.contains(result.id),
          onTap: () => _toggleSelection(result),
        );
      },
    );
  }
}
