import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../home/domain/home_match.dart';
import '../data/match_repository.dart';
import '../domain/sport_option.dart';
import 'create_match_screen.dart';

class ConnectedCreateMatchScreen extends StatefulWidget {
  const ConnectedCreateMatchScreen({
    required this.repository,
    super.key,
    this.onBack,
    this.onCancel,
    this.onInvitePlayers,
    this.onBackHome,
    this.onViewMatch,
  });

  final MatchRepository repository;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final ValueChanged<HomeMatch>? onInvitePlayers;
  final ValueChanged<HomeMatch>? onBackHome;
  final ValueChanged<HomeMatch>? onViewMatch;

  @override
  State<ConnectedCreateMatchScreen> createState() =>
      _ConnectedCreateMatchScreenState();
}

class _ConnectedCreateMatchScreenState
    extends State<ConnectedCreateMatchScreen> {
  List<SportOption> _sports = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSports();
  }

  Future<void> _loadSports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sports = await widget.repository.listSports();
      if (!mounted) return;
      setState(() {
        _sports = sports;
        if (sports.isEmpty) {
          _error = 'No sports are available right now.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Could not load sports. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _error == null && _sports.isNotEmpty) {
      return CreateMatchScreen(
        sports: _sports,
        onBack: widget.onBack,
        onCancel: widget.onCancel,
        onSubmit: widget.repository.create,
        onInvitePlayers: widget.onInvitePlayers,
        onBackHome: widget.onBackHome,
        onViewMatch: widget.onViewMatch,
      );
    }

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
                title: 'Create Match',
                onBack: widget.onBack,
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                  child: _loading
                      ? const AppLoader()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error ?? 'Could not load sports.',
                              textAlign: TextAlign.center,
                              style: AppTypography.body14,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              width: 160,
                              child: AppButton.primary(
                                label: 'Try Again',
                                onPressed: _loadSports,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
