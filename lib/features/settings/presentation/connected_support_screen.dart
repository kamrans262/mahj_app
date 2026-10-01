import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_loader.dart';
import '../data/support_content_repository.dart';
import '../domain/support_data.dart';
import 'support_screen.dart';

class ConnectedSupportScreen extends StatefulWidget {
  const ConnectedSupportScreen({
    required this.repository,
    super.key,
    this.onBack,
  });

  final SupportContentRepository repository;
  final VoidCallback? onBack;

  @override
  State<ConnectedSupportScreen> createState() => _ConnectedSupportScreenState();
}

class _ConnectedSupportScreenState extends State<ConnectedSupportScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  SupportContentData? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _errorMessage = null);

    try {
      final data = await widget.repository.loadSupport();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(error));
    }
  }

  Future<SupportAttachment?> _pickScreenshot() async {
    final selected = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (selected == null) return null;

    final bytes = await selected.readAsBytes();
    if (bytes.isEmpty) return null;

    final extension = selected.name.toLowerCase();
    final contentType = extension.endsWith('.png')
        ? 'image/png'
        : extension.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';

    return SupportAttachment(
      id: selected.path,
      displayName: selected.name,
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<bool> _submit(SupportIssueRequest request) async {
    try {
      await widget.repository.submitIssue(request);
      return true;
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error));
      return false;
    }
  }

  Future<void> _emailSupport() async {
    final email = _data?.supportEmail.trim() ?? '';
    if (email.isEmpty) {
      _showMessage('Support email is not available.');
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: const {'subject': 'Mahj Support'},
    );

    if (!await launchUrl(uri)) {
      _showMessage('Could not open your email app.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Could not load support. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data != null) {
      return SupportScreen(
        faqs: data.faqs,
        topics: data.topics,
        supportEmail: data.supportEmail,
        onBack: widget.onBack,
        onPickScreenshot: _pickScreenshot,
        onSubmitIssue: _submit,
        onEmailSupport: _emailSupport,
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
                title: 'Support',
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
