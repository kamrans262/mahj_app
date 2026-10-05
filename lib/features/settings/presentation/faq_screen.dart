import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../data/support_content_repository.dart';
import '../domain/support_data.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({
    required this.repository,
    super.key,
    this.onBack,
    this.onSupportTap,
  });

  final SupportContentRepository repository;
  final VoidCallback? onBack;
  final VoidCallback? onSupportTap;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<SupportFaq> _faqs = const <SupportFaq>[];
  final Set<String> _expanded = <String>{};
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
      final data = await widget.repository.loadSupport();
      if (!mounted) return;
      setState(() => _faqs = data.faqs);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load FAQs. Please try again.');
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
                title: 'FAQs',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(child: _buildBody()),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.md,
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
              ),
              child: AppButton.primary(
                label: 'Support',
                onPressed: widget.onSupportTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: AppLoader());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: AppTypography.body14),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: _load, child: Text('Retry', style: AppTypography.action14)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        25,
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
      ),
      itemCount: _faqs.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        final expanded = _expanded.contains(faq.id);
        return AppSurfaceContainer(
          minHeight: 0,
          padding: EdgeInsets.zero,
          child: InkWell(
            key: ValueKey('faq-${faq.id}'),
            onTap: () {
              setState(() {
                if (!_expanded.add(faq.id)) _expanded.remove(faq.id);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: AppTypography.body16.copyWith(
                            color: AppColors.heading,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: const AppAssetIcon(
                          assetPath: AppAssets.settingsForwardIcon,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(faq.answer, style: AppTypography.homeMeta14),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
