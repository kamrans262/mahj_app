import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_surface_container.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/support_data.dart';

typedef SupportScreenshotPicker = Future<SupportAttachment?> Function();
typedef SupportSubmitCallback = Future<bool> Function(
  SupportIssueRequest request,
);

class SupportScreen extends StatefulWidget {
  const SupportScreen({
    required this.faqs,
    required this.topics,
    super.key,
    this.onBack,
    this.supportEmail = '',
    this.onPickScreenshot,
    this.onSubmitIssue,
    this.onEmailSupport,
  });

  final List<SupportFaq> faqs;
  final List<SupportTopic> topics;
  final String supportEmail;
  final VoidCallback? onBack;
  final SupportScreenshotPicker? onPickScreenshot;
  final SupportSubmitCallback? onSubmitIssue;
  final VoidCallback? onEmailSupport;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  SupportTopic? _selectedTopic;
  SupportAttachment? _screenshot;
  bool _topicError = false;
  bool _messageError = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showUnavailable(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is not connected yet.')));
  }

  Future<void> _selectTopic() async {
    if (_isSubmitting || widget.topics.isEmpty) return;

    final selected = await showModalBottomSheet<SupportTopic>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheetTop),
        ),
      ),
      builder: (sheetContext) {
        final sheetHeight = MediaQuery.sizeOf(sheetContext).height;
        final maxListHeight = math
            .max(52.0, (sheetHeight * 0.55) - 80.0)
            .toDouble();
        final listHeight = math
            .min(widget.topics.length * 52.0, math.min(300.0, maxListHeight))
            .toDouble();

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Topic',
                  textAlign: TextAlign.center,
                  style: AppTypography.homeMatchTitle18,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: listHeight,
                  child: ListView.separated(
                    key: const ValueKey('support-topic-options-list'),
                    padding: EdgeInsets.zero,
                    itemCount: widget.topics.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final topic = widget.topics[index];
                      final selected = topic.id == _selectedTopic?.id;
                      return InkWell(
                        key: ValueKey('support-topic-option-${topic.id}'),
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        onTap: () => Navigator.of(sheetContext).pop(topic),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  topic.label,
                                  style: AppTypography.body16.copyWith(
                                    color: AppColors.heading,
                                  ),
                                ),
                              ),
                              if (selected)
                                AppAssetIcon(
                                  assetPath: AppAssets.approveIcon,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
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

    if (!mounted || selected == null) return;
    setState(() {
      _selectedTopic = selected;
      _topicError = false;
    });
  }

  Future<void> _pickScreenshot() async {
    if (_isSubmitting) return;
    final picker = widget.onPickScreenshot;
    if (picker == null) {
      _showUnavailable('Screenshot upload');
      return;
    }

    final attachment = await picker();
    if (!mounted || attachment == null) return;
    setState(() => _screenshot = attachment);
  }

  Future<void> _submitIssue() async {
    if (_isSubmitting) return;

    final topic = _selectedTopic;
    final message = _messageController.text.trim();
    final hasTopic = topic != null;
    final hasMessage = message.isNotEmpty;

    if (!hasTopic || !hasMessage) {
      setState(() {
        _topicError = !hasTopic;
        _messageError = !hasMessage;
      });
      return;
    }

    final submit = widget.onSubmitIssue;
    if (submit == null) {
      _showUnavailable('Support submission');
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await submit(
      SupportIssueRequest(
        topic: topic,
        message: message,
        screenshot: _screenshot,
      ),
    );
    if (!mounted) return;

    if (success) {
      setState(() {
        _isSubmitting = false;
        _messageController.clear();
        _selectedTopic = null;
        _screenshot = null;
        _topicError = false;
        _messageError = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Support request submitted.')),
        );
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Unable to submit issue. Please retry.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('support-screen'),
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
              child: SingleChildScrollView(
                key: const ValueKey('support-scroll-view'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  25,
                  AppSpacing.pageHorizontal,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel(text: 'Contact Support / Report a Problem'),
                    const SizedBox(height: AppSpacing.sm),
                    _TopicField(
                      selectedTopic: _selectedTopic,
                      hasError: _topicError,
                      onTap: _selectTopic,
                    ),
                    if (_topicError) ...[
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        'Please select a topic.',
                        style: AppTypography.homeMeta12.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel(text: 'Describe your issue'),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      key: const ValueKey('support-message-field'),
                      controller: _messageController,
                      hintText: 'Message:',
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 5,
                      maxLines: 8,
                      contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      onChanged: (value) {
                        if (_messageError && value.trim().isNotEmpty) {
                          setState(() => _messageError = false);
                        }
                      },
                    ),
                    if (_messageError) ...[
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        'Please describe your issue.',
                        style: AppTypography.homeMeta12.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionLabel(text: 'Add screenshot'),
                    const SizedBox(height: AppSpacing.sm),
                    _ScreenshotUploadSurface(
                      attachment: _screenshot,
                      onTap: _pickScreenshot,
                    ),

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
                      key: const ValueKey('support-submit-button'),
                      label: 'Submit Issue',
                      onPressed: _isSubmitting ? null : _submitIssue,
                      isEnabled: !_isSubmitting,
                      isLoading: _isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.outlined(
                      key: const ValueKey('support-email-button'),
                      label: 'Email Support',
                      onPressed: _isSubmitting
                          ? null
                          : widget.onEmailSupport ??
                                () => _showUnavailable('Email support'),
                    ),
                    if (widget.supportEmail.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.supportEmail,
                        textAlign: TextAlign.center,
                        style: AppTypography.homeMeta12,
                      ),
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.homeMeta14);
  }
}

class _FaqGroup extends StatelessWidget {
  const _FaqGroup({
    required this.faqs,
    required this.expandedIds,
    required this.onToggle,
  });

  final List<SupportFaq> faqs;
  final Set<String> expandedIds;
  final ValueChanged<SupportFaq> onToggle;

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) {
      return AppSurfaceContainer(
        minHeight: 0,
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: AppColors.background,
        child: Text('No FAQs available.', style: AppTypography.homeMeta14),
      );
    }

    return AppSurfaceContainer(
      key: const ValueKey('support-faq-group'),
      minHeight: 0,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < faqs.length; index++) ...[
            _FaqRow(
              faq: faqs[index],
              expanded: expandedIds.contains(faqs[index].id),
              onTap: () => onToggle(faqs[index]),
            ),
            if (index < faqs.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({
    required this.faq,
    required this.expanded,
    required this.onTap,
  });

  final SupportFaq faq;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: faq.question,
      child: InkWell(
        key: ValueKey('support-faq-${faq.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
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
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: AppAssetIcon(
                      assetPath: AppAssets.settingsForwardIcon,
                      size: 18,
                      color: AppColors.heading,
                    ),
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  faq.answer,
                  key: ValueKey('support-faq-answer-${faq.id}'),
                  style: AppTypography.body14.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicField extends StatelessWidget {
  const _TopicField({
    required this.selectedTopic,
    required this.hasError,
    required this.onTap,
  });

  final SupportTopic? selectedTopic;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceContainer(
      key: const ValueKey('support-topic-field'),
      minHeight: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      backgroundColor: AppColors.background,
      borderColor: hasError ? AppColors.error : AppColors.controlBorder,
      semanticsLabel: selectedTopic == null
          ? 'Choose support topic'
          : 'Support topic: ${selectedTopic!.label}',
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedTopic?.label ?? 'Topic:',
              style: AppTypography.body16.copyWith(color: AppColors.heading),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Transform.rotate(
            angle: math.pi / 2,
            child: AppAssetIcon(
              assetPath: AppAssets.settingsForwardIcon,
              size: 18,
              color: AppColors.heading,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotUploadSurface extends StatelessWidget {
  const _ScreenshotUploadSurface({
    required this.attachment,
    required this.onTap,
  });

  final SupportAttachment? attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: attachment == null
          ? 'Upload screenshot'
          : 'Replace screenshot ${attachment!.displayName}',
      child: CustomPaint(
        painter: _DashedRoundedRectPainter(
          color: AppColors.primary,
          radius: AppRadius.control,
        ),
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.control),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('support-upload-screenshot'),
            onTap: onTap,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.controlPressedOverlay;
              }
              return Colors.transparent;
            }),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    attachment?.displayName ?? 'Upload Screenshot',
                    textAlign: TextAlign.center,
                    style: AppTypography.body16.copyWith(
                      color: AppColors.heading,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1 || size.height <= 1) return;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const dashLength = 6.0;
    const gapLength = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
