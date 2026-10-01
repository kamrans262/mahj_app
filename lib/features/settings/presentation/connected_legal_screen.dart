import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../data/support_content_repository.dart';
import '../domain/legal_data.dart';
import 'legal_screen.dart';

class ConnectedLegalScreen extends StatefulWidget {
  const ConnectedLegalScreen({
    required this.repository,
    super.key,
    this.initialDocument = LegalDocumentType.terms,
    this.onBack,
  });

  final SupportContentRepository repository;
  final LegalDocumentType initialDocument;
  final VoidCallback? onBack;

  @override
  State<ConnectedLegalScreen> createState() => _ConnectedLegalScreenState();
}

class _ConnectedLegalScreenState extends State<ConnectedLegalScreen> {
  ({LegalDocumentData terms, LegalDocumentData privacy})? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _errorMessage = null);

    try {
      final data = await widget.repository.loadLegal();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(error));
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load legal content. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data != null) {
      return LegalScreen(
        terms: data.terms,
        privacy: data.privacy,
        initialDocument: widget.initialDocument,
        onBack: widget.onBack,
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
                title: 'Legal',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: Center(
                child: _errorMessage == null
                    ? const AppLoader()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.pageHorizontal,
                            ),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTypography.body14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: _load,
                            child: Text('Retry', style: AppTypography.action14),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
