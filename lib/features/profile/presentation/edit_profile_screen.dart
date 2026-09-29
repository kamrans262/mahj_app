import 'package:flutter/material.dart';

import '../../../app/app_assets.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_asset_icon.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_centered_page_header.dart';
import '../../../core/widgets/app_responsive_action_pair.dart';
import '../../../core/widgets/app_text_field.dart';
import '../domain/profile_data.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.profile,
    super.key,
    this.onBack,
    this.onCancel,
    this.onChangePhoto,
    this.onSave,
  });

  final ProfileData profile;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;
  final VoidCallback? onChangePhoto;
  final Future<ProfileData?> Function(ProfileData draft)? onSave;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _zipController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _bioController;

  bool _hasChanges = false;
  bool _isSaving = false;

  Iterable<TextEditingController> get _controllers => [
    _nameController,
    _phoneController,
    _zipController,
    _cityController,
    _stateController,
    _bioController,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _zipController = TextEditingController(text: widget.profile.postCode);
    _cityController = TextEditingController(
      text: widget.profile.city.isNotEmpty
          ? widget.profile.city
          : widget.profile.address,
    );
    _stateController = TextEditingController(text: widget.profile.state);
    _bioController = TextEditingController(text: widget.profile.bio);

    for (final controller in _controllers) {
      controller.addListener(_updateHasChanges);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_updateHasChanges);
      controller.dispose();
    }
    super.dispose();
  }

  void _updateHasChanges() {
    final changed =
        _nameController.text.trim() != widget.profile.name.trim() ||
        _phoneController.text.trim() != widget.profile.phone.trim() ||
        _zipController.text.trim() != widget.profile.postCode.trim() ||
        _cityController.text.trim() !=
            (widget.profile.city.isNotEmpty
                ? widget.profile.city.trim()
                : widget.profile.address.trim()) ||
        _stateController.text.trim() != widget.profile.state.trim() ||
        _bioController.text.trim() != widget.profile.bio.trim();

    if (changed == _hasChanges || !mounted) return;
    setState(() => _hasChanges = changed);
  }

  String? _requiredNameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  ProfileData _buildDraft() {
    final city = _cityController.text.trim();
    return widget.profile.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      postCode: _zipController.text.trim(),
      city: city,
      address: city,
      state: _stateController.text.trim(),
      bio: _bioController.text.trim(),
    );
  }

  void _handleCancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    final callback = widget.onCancel ?? widget.onBack;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_hasChanges) return;

    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final onSave = widget.onSave;
    if (onSave == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile update service is not connected yet.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final savedProfile = await onSave(_buildDraft());
      if (!mounted) return;

      setState(() => _isSaving = false);
      if (savedProfile != null) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(savedProfile);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile changes. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('edit-profile-screen'),
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
                title: 'Edit Profile',
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('edit-profile-scroll-view'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: _EditableProfileAvatar(
                          profile: widget.profile,
                          onChangePhoto: widget.onChangePhoto,
                        ),
                      ),
                      const SizedBox(height: 25),
                      AppTextField(
                        key: const ValueKey('edit-profile-full-name'),
                        controller: _nameController,
                        hintText: 'Full Name',
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: _requiredNameValidator,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        key: const ValueKey('edit-profile-phone'),
                        controller: _phoneController,
                        hintText: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        key: const ValueKey('edit-profile-zip'),
                        controller: _zipController,
                        hintText: 'Zip Code',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        key: const ValueKey('edit-profile-city'),
                        controller: _cityController,
                        hintText: 'City',
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        key: const ValueKey('edit-profile-state'),
                        controller: _stateController,
                        hintText: 'State',
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        key: const ValueKey('edit-profile-bio'),
                        controller: _bioController,
                        hintText: 'Bio (optional)',
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 3,
                        maxLines: 5,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                      const SizedBox(height: 100),
                      AppResponsiveActionPair(
                        horizontalGap: AppSpacing.md,
                        first: AppButton.secondary(
                          key: const ValueKey('edit-profile-cancel'),
                          label: 'Cancel',
                          onPressed: _isSaving ? null : _handleCancel,
                          textStyle: AppTypography.matchSuccessSecondaryButton,
                        ),
                        second: AppButton.primary(
                          key: const ValueKey('edit-profile-save'),
                          label: 'Save Changes',
                          onPressed: _handleSave,
                          isLoading: _isSaving,
                          textStyle: AppTypography.matchSuccessSecondaryButton
                              .copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
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

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({
    required this.profile,
    required this.onChangePhoto,
  });

  final ProfileData profile;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(
            key: const ValueKey('edit-profile-avatar'),
            fallbackAsset: profile.avatarAsset,
            imageUrl: profile.avatarUrl,
            size: 84,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Semantics(
              button: true,
              enabled: onChangePhoto != null,
              label: 'Change profile photo',
              child: SizedBox.square(
                dimension: 24,
                child: Center(
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const ValueKey('edit-profile-change-photo'),
                      onTap: onChangePhoto,
                      child: const SizedBox.square(
                        dimension: 16,
                        child: Center(
                          child: AppAssetIcon(
                            assetPath: AppAssets.profileEditIcon,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
