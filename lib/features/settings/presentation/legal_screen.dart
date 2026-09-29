import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../domain/legal_data.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({
    required this.terms,
    required this.privacy,
    super.key,
    this.initialDocument = LegalDocumentType.terms,
    this.onBack,
  });

  final LegalDocumentData terms;
  final LegalDocumentData privacy;
  final LegalDocumentType initialDocument;
  final VoidCallback? onBack;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late LegalDocumentType _selectedDocument;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.initialDocument;
  }

  @override
  void didUpdateWidget(covariant LegalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDocument != widget.initialDocument) {
      _selectedDocument = widget.initialDocument;
    }
  }

  LegalDocumentData get _document =>
      _selectedDocument == LegalDocumentType.terms
      ? widget.terms
      : widget.privacy;

  void _select(LegalDocumentType document) {
    if (_selectedDocument == document) return;
    setState(() => _selectedDocument = document);
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;

    return Scaffold(
      key: const ValueKey('legal-screen'),
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
              child: ListView(
                key: const ValueKey('legal-scroll-view'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  25,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          selected:
                              _selectedDocument == LegalDocumentType.terms,
                          button: true,
                          label: 'Terms and Conditions tab',
                          child: _selectedDocument == LegalDocumentType.terms
                              ? AppButton.primary(
                                  key: const ValueKey('legal-tab-terms'),
                                  label: 'Terms & Conditions',
                                  onPressed: () =>
                                      _select(LegalDocumentType.terms),
                                )
                              : AppButton.outlined(
                                  key: const ValueKey('legal-tab-terms'),
                                  label: 'Terms & Conditions',
                                  textStyle: AppTypography.body16.copyWith(
                                    color: AppColors.heading,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onPressed: () =>
                                      _select(LegalDocumentType.terms),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Semantics(
                          selected:
                              _selectedDocument == LegalDocumentType.privacy,
                          button: true,
                          label: 'Privacy Policy tab',
                          child: _selectedDocument == LegalDocumentType.privacy
                              ? AppButton.primary(
                                  key: const ValueKey('legal-tab-privacy'),
                                  label: 'Privacy Policy',
                                  onPressed: () =>
                                      _select(LegalDocumentType.privacy),
                                )
                              : AppButton.outlined(
                                  key: const ValueKey('legal-tab-privacy'),
                                  label: 'Privacy Policy',
                                  textStyle: AppTypography.body16.copyWith(
                                    color: AppColors.heading,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onPressed: () =>
                                      _select(LegalDocumentType.privacy),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    document.title,
                    key: const ValueKey('legal-document-title'),
                    style: AppTypography.homeSectionHeading,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Last updated ${document.lastUpdated}',
                    style: AppTypography.homeMeta14,
                  ),
                  const SizedBox(height: 30),
                  for (
                    var index = 0;
                    index < document.sections.length;
                    index++
                  ) ...[
                    _LegalSection(section: document.sections[index]),
                    if (index < document.sections.length - 1)
                      const SizedBox(height: AppSpacing.xl),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.section});

  final LegalSectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(section.title, style: AppTypography.homeMatchTitle18),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < section.paragraphs.length; index++) ...[
          Text(
            section.paragraphs[index],
            style: AppTypography.body14.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (index < section.paragraphs.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
