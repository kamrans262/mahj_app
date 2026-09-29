import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../app_services.dart';
import '../../features/auth/domain/auth_flow_args.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/chat/data/match_chat_preview_data.dart';
import '../../features/chat/domain/chat_models.dart';
import '../../features/chat/presentation/match_chat_screen.dart';
import '../../features/home/data/home_preview_data.dart';
import '../../features/home/domain/home_match.dart';
import '../../features/home/presentation/all_nearby_matches_screen.dart';
import '../../features/matches/data/invite_players_preview_data.dart';
import '../../features/matches/data/match_completed_preview_data.dart';
import '../../features/matches/data/my_matches_preview_data.dart';
import '../../features/matches/domain/my_matches_data.dart';
import '../../features/matches/presentation/create_match_screen.dart';
import '../../features/matches/presentation/invite_players_screen.dart';
import '../../features/matches/presentation/invitation_receiving_screen.dart';
import '../../features/matches/presentation/match_completed_screen.dart';
import '../../features/matches/presentation/match_details_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/notifications/domain/mahj_notification.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/data/player_profile_preview_data.dart';
import '../../features/profile/data/profile_preview_data.dart';
import '../../features/profile/domain/player_profile_data.dart';
import '../../features/profile/domain/player_profile_route_args.dart';
import '../../features/profile/domain/profile_data.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/player_profile_screen.dart';
import '../../features/settings/data/legal_preview_data.dart';
import '../../features/settings/data/privacy_safety_preview_data.dart';
import '../../features/settings/data/support_preview_data.dart';
import '../../features/settings/domain/legal_data.dart';
import '../../features/settings/presentation/account_settings_screen.dart';
import '../../features/settings/presentation/legal_screen.dart';
import '../../features/settings/presentation/notification_settings_screen.dart';
import '../../features/settings/presentation/privacy_safety_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/support_screen.dart';
import '../../features/subscription/presentation/connected_manage_subscription_screen.dart';
import '../../features/subscription/presentation/subscription_entry_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String resetPassword = '/reset-password';
  static const String premiumPlan = '/premium-plan';
  static const String home = '/home';
  static const String map = '/map';
  static const String myMatches = '/my-matches';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String playerProfile = '/player-profile';
  static const String settings = '/settings';
  static const String accountSettings = '/account-settings';
  static const String notificationSettings = '/notification-settings';
  static const String manageSubscription = '/manage-subscription';
  static const String privacySafety = '/privacy-safety';
  static const String support = '/support';
  static const String legal = '/legal';
  static const String nearbyMatches = '/nearby-matches';
  static const String createMatch = '/create-match';
  static const String matchDetails = '/match-details';
  static const String invitePlayers = '/invite-players';
  static const String invitationReceiving = '/invitation-receiving';
  static const String matchChat = '/match-chat';
  static const String matchCompleted = '/match-completed';
  static const String notifications = '/notifications';
}

abstract final class AppRouter {
  static final _authRepository = AppServices.authRepository;

  static Map<String, WidgetBuilder> get routes => {
    AppRoutes.splash: (_) => SplashScreen(
      onResolveRoute: () async {
        final restored = await _authRepository.restoreSession();
        return restored ? AppRoutes.home : AppRoutes.login;
      },
    ),
    AppRoutes.login: (context) => LoginScreen(
      onLogin: (email, password) async {
        try {
          await _authRepository.login(email: email, password: password);
          if (!context.mounted) return;
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
        }
      },
      onForgotPassword: () {
        Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
      },
      onSignUp: () {
        Navigator.of(context).pushNamed(AppRoutes.signUp);
      },
    ),
    AppRoutes.signUp: (context) => SignUpScreen(
      onSignUp: (fullName, email, password) async {
        try {
          await _authRepository.requestRegistrationOtp(
            name: fullName,
            email: email,
            password: password,
          );
          if (!context.mounted) return;
          Navigator.of(context).pushNamed(
            AppRoutes.otp,
            arguments: OtpRouteArgs(
              email: email,
              purpose: OtpPurpose.registration,
            ),
          );
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
        }
      },
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onLogin: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          navigator.pushReplacementNamed(AppRoutes.login);
        }
      },
    ),
    AppRoutes.forgotPassword: (context) => ForgotPasswordScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onBackToLogin: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          navigator.pushReplacementNamed(AppRoutes.login);
        }
      },
      onSendResetLink: (email) async {
        try {
          await _authRepository.requestPasswordResetOtp(email);
          if (!context.mounted) return false;
          Navigator.of(context).pushNamed(
            AppRoutes.otp,
            arguments: OtpRouteArgs(
              email: email,
              purpose: OtpPurpose.passwordReset,
            ),
          );
          return true;
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
          return false;
        }
      },
    ),
    AppRoutes.premiumPlan: (context) => SubscriptionEntryScreen(
      repository: AppServices.subscriptionRepository,
      onBack: () => Navigator.of(context).maybePop(),
      onActivated: () {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      },
      onTermsTap: () => _openLegal(context, LegalDocumentType.terms),
      onPrivacyPolicyTap: () => _openLegal(context, LegalDocumentType.privacy),
    ),
    AppRoutes.home: (context) => _mainShell(context),
    AppRoutes.map: (context) => _mainShell(context, initialIndex: 1),
    AppRoutes.myMatches: (context) => _mainShell(context, initialIndex: 2),
    AppRoutes.profile: (context) => _mainShell(context, initialIndex: 3),
    AppRoutes.notifications: (context) => NotificationsScreen(
      onBack: () => Navigator.of(context).maybePop(),
      onNotificationTap: (notification) async {
        _openNotificationDestination(context, notification);
      },
    ),
    AppRoutes.settings: (context) => SettingsScreen(
      onBack: () => Navigator.of(context).maybePop(),
      onAccountSettingsTap: () {
        Navigator.of(context).pushNamed(AppRoutes.accountSettings);
      },
      onNotificationSettingsTap: () {
        Navigator.of(context).pushNamed(AppRoutes.notificationSettings);
      },
      onSubscriptionTap: () {
        Navigator.of(context).pushNamed(AppRoutes.manageSubscription);
      },
      onPrivacySafetyTap: () {
        Navigator.of(context).pushNamed(AppRoutes.privacySafety);
      },
      onFaqTap: () {
        Navigator.of(context).pushNamed(AppRoutes.support);
      },
      onSupportTap: () {
        Navigator.of(context).pushNamed(AppRoutes.support);
      },
      onTermsTap: () {
        _openLegal(context, LegalDocumentType.terms);
      },
      onPrivacyPolicyTap: () {
        _openLegal(context, LegalDocumentType.privacy);
      },
      onLogOut: () async {
        try {
          await _authRepository.logout();
          if (!context.mounted) return true;
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          return true;
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
          return false;
        }
      },
      onDeleteAccount: () async {
        try {
          await _authRepository.deleteAccount();
          if (!context.mounted) return true;
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          return true;
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
          return false;
        }
      },
    ),
    AppRoutes.accountSettings: (context) => AccountSettingsScreen(
      initialEmail:
          _authRepository.currentUser?.email ??
          ProfilePreviewData.currentUser.email,
      isGoogleConnected: _authRepository.currentUser?.googleConnected ?? false,
      isAppleConnected: _authRepository.currentUser?.appleConnected ?? false,
      onBack: () => Navigator.of(context).maybePop(),
      onChangeEmail: (email) async {
        try {
          await _authRepository.changeEmail(email);
          if (context.mounted) {
            _showSuccess(context, 'Email updated.');
          }
          return true;
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
          return false;
        }
      },
      onChangePassword: (password, confirmation) async {
        if (password != confirmation) {
          _showApiError(context, 'Passwords do not match.');
          return false;
        }
        try {
          await _authRepository.changePassword(password);
          if (context.mounted) {
            _showSuccess(context, 'Password updated.');
          }
          return true;
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
          return false;
        }
      },
      onDeleteAccount: () async {
        try {
          await _authRepository.deleteAccount();
          if (!context.mounted) return true;
          Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
          return true;
        } catch (error) {
          if (context.mounted) _showApiError(context, error);
          return false;
        }
      },
    ),
    AppRoutes.notificationSettings: (context) => NotificationSettingsScreen(
      onBack: () => Navigator.of(context).maybePop(),
    ),
    AppRoutes.support: (context) => SupportScreen(
      faqs: SupportPreviewData.faqs,
      topics: SupportPreviewData.topics,
      onBack: () => Navigator.of(context).maybePop(),
    ),
    AppRoutes.privacySafety: (context) => PrivacySafetyScreen(
      blockedUsers: PrivacySafetyPreviewData.blockedUsers,
      rules: PrivacySafetyPreviewData.rules,
      reportHistory: PrivacySafetyPreviewData.reportHistory,
      onBack: () => Navigator.of(context).maybePop(),
      onPlayerTap: (player) {
        final profile = PlayerProfilePreviewData.forIdentity(
          id: player.id,
          displayName: player.displayName,
          avatarAsset: player.avatarAsset,
        );
        Navigator.of(context).pushNamed(
          AppRoutes.playerProfile,
          arguments: PlayerProfileRouteArgs(
            player: profile,
            inviteMatch: _defaultInviteMatch(),
          ),
        );
      },
    ),
    AppRoutes.manageSubscription: (context) =>
        ConnectedManageSubscriptionScreen(
          repository: AppServices.subscriptionRepository,
          onBack: () => Navigator.of(context).maybePop(),
          onTermsTap: () => _openLegal(context, LegalDocumentType.terms),
          onPrivacyPolicyTap: () =>
              _openLegal(context, LegalDocumentType.privacy),
        ),
    AppRoutes.nearbyMatches: (context) => AllNearbyMatchesScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onMatchTap: (match) {
        _openMatchDetails(context, match);
      },
      onCreateMatch: () {
        Navigator.of(context).pushNamed(AppRoutes.createMatch);
      },
    ),
    AppRoutes.createMatch: (context) => CreateMatchScreen(
      onBack: () {
        Navigator.of(context).maybePop();
      },
      onCancel: () {
        Navigator.of(context).maybePop();
      },
      onInvitePlayers: (match) {
        _openInvitePlayers(context, match);
      },
    ),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final match = settings.arguments;

    if (settings.name == AppRoutes.otp) {
      final args = settings.arguments;
      if (args is! OtpRouteArgs) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => OtpScreen(
          email: args.email,
          purpose: args.purpose,
          onBack: () => Navigator.of(context).maybePop(),
          onResend: () async {
            try {
              await _authRepository.resendOtp(
                email: args.email,
                purpose: args.purpose,
              );
              return true;
            } catch (error) {
              if (context.mounted) _showApiError(context, error);
              return false;
            }
          },
          onVerify: (otp) async {
            try {
              if (args.purpose == OtpPurpose.registration) {
                await _authRepository.verifyRegistrationOtp(
                  email: args.email,
                  otp: otp,
                );
                if (!context.mounted) return true;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.premiumPlan,
                  (route) => false,
                );
              } else {
                final resetToken = await _authRepository.verifyPasswordResetOtp(
                  email: args.email,
                  otp: otp,
                );
                if (!context.mounted) return true;
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.resetPassword,
                  arguments: ResetPasswordRouteArgs(
                    email: args.email,
                    resetToken: resetToken,
                  ),
                );
              }
              return true;
            } catch (error) {
              if (context.mounted) _showApiError(context, error);
              return false;
            }
          },
        ),
      );
    }

    if (settings.name == AppRoutes.resetPassword) {
      final args = settings.arguments;
      if (args is! ResetPasswordRouteArgs) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => ResetPasswordScreen(
          onBack: () => Navigator.of(context).maybePop(),
          onResetPassword: (password) async {
            try {
              await _authRepository.resetPassword(
                email: args.email,
                resetToken: args.resetToken,
                password: password,
              );
              if (!context.mounted) return true;
              _showSuccess(context, 'Password reset successfully.');
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              return true;
            } catch (error) {
              if (context.mounted) _showApiError(context, error);
              return false;
            }
          },
        ),
      );
    }

    if (settings.name == AppRoutes.legal) {
      final initialDocument = match is LegalDocumentType
          ? match
          : LegalDocumentType.terms;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => LegalScreen(
          terms: LegalPreviewData.terms,
          privacy: LegalPreviewData.privacy,
          initialDocument: initialDocument,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    if (settings.name == AppRoutes.playerProfile) {
      final arguments = settings.arguments;
      final PlayerProfileData player;
      final HomeMatch? inviteMatch;

      if (arguments is PlayerProfileRouteArgs) {
        player = arguments.player;
        inviteMatch = arguments.inviteMatch;
      } else if (arguments is PlayerProfileData) {
        player = arguments;
        inviteMatch = null;
      } else {
        return null;
      }

      final currentProfile =
          _authRepository.currentUser?.toProfileData() ??
          ProfilePreviewData.currentUser;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => PlayerProfileScreen(
          player: player,
          notificationCount: currentProfile.unreadNotificationCount,
          messageCount: currentProfile.unreadMessageCount,
          onNotificationTap: () {
            Navigator.of(context).pushNamed(AppRoutes.notifications);
          },
          onMessageTap: () => _openHeaderChat(context),
          onMutualGameTap: (mutualMatch) {
            _openMatchDetails(context, mutualMatch);
          },
          onSendInvite: () {
            final resolvedMatch = inviteMatch ?? _defaultInviteMatch();
            if (resolvedMatch == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Create a match before inviting this player.'),
                ),
              );
              return;
            }
            _openInvitePlayers(context, resolvedMatch);
          },
        ),
      );
    }

    if (settings.name == AppRoutes.editProfile) {
      final profile = settings.arguments;
      if (profile is! ProfileData) return null;

      return MaterialPageRoute<ProfileData>(
        settings: settings,
        builder: (context) => EditProfileScreen(
          profile: profile,
          onBack: () => Navigator.of(context).maybePop(),
          onCancel: () => Navigator.of(context).maybePop(),
          onSave: (draft) async {
            try {
              return await _authRepository.updateProfile(draft);
            } catch (error) {
              if (context.mounted) _showApiError(context, error);
              return null;
            }
          },
        ),
      );
    }

    if (settings.name == AppRoutes.matchDetails) {
      if (match is! HomeMatch) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => MatchDetailsScreen(
          match: match,
          onBack: () => Navigator.of(context).maybePop(),
          onInvitePlayers: () {
            _openInvitePlayers(context, match);
          },
          onChat: (_) {
            Navigator.of(context)
                .pushNamed(AppRoutes.matchChat, arguments: match);
          },
        ),
      );
    }

    if (settings.name == AppRoutes.matchCompleted) {
      if (match is! HomeMatch) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => MatchCompletedScreen(
          match: match,
          players: MatchCompletedPreviewData.players,
          inviterName: MatchCompletedPreviewData.inviterName,
          inviterAvatarAsset: MatchCompletedPreviewData.inviterAvatarAsset,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    if (settings.name == AppRoutes.matchChat) {
      if (match is! HomeMatch) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => MatchChatScreen(
          match: match,
          participants: MatchChatPreviewData.participantsFor(match),
          messages: MatchChatPreviewData.messagesFor(match),
          currentUserId: MatchChatPreviewData.currentUserId,
          onBack: () => Navigator.of(context).maybePop(),
          onPlayerTap: (participant) {
            if (participant.id == MatchChatPreviewData.currentUserId) return;
            _openPlayerProfile(context, participant, match);
          },
        ),
      );
    }

    if (settings.name == AppRoutes.invitePlayers) {
      if (match is! HomeMatch) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => InvitePlayersScreen(
          match: match,
          initialResults: InvitePlayersPreviewData.forMatch(match),
          onBack: () => Navigator.of(context).maybePop(),
          onPreviewInvitationReceived: () {
            _openInvitationReceiving(context, match);
          },
        ),
      );
    }

    if (settings.name == AppRoutes.invitationReceiving) {
      if (match is! HomeMatch) return null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => _buildInvitationReceivingScreen(context, match),
      );
    }

    return null;
  }

  static void _openLegal(BuildContext context, LegalDocumentType document) {
    Navigator.of(context).pushNamed(AppRoutes.legal, arguments: document);
  }

  static void _showApiError(BuildContext context, Object error) {
    final message = error is ApiException
        ? error.message
        : error is String
        ? error
        : 'Something went wrong. Please try again.';
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void _showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static MainNavigationShell _mainShell(
    BuildContext context, {
    int initialIndex = 0,
  }) {
    return MainNavigationShell(
      initialIndex: initialIndex,
      initialProfileData:
          _authRepository.currentUser?.toProfileData() ??
          ProfilePreviewData.currentUser,
      onNearbyViewAll: () {
        Navigator.of(context).pushNamed(AppRoutes.nearbyMatches);
      },
      onCreateMatch: () {
        Navigator.of(context).pushNamed(AppRoutes.createMatch);
      },
      onMatchTap: (match) {
        _openMatchDetails(context, match);
      },
      onMyMatchesMatchTap: (item, tab) {
        _openMyMatchesEntry(context, item, tab);
      },
      onMyMatchesInvitationTap: (item) {
        _openInvitationReceiving(context, item.match);
      },
      onNotificationTap: () {
        Navigator.of(context).pushNamed(AppRoutes.notifications);
      },
      onMessageTap: () {
        _openHeaderChat(context);
      },
      onProfileSettingsTap: () {
        Navigator.of(context).pushNamed(AppRoutes.settings);
      },
      onEditProfileRequest: (profile) {
        return Navigator.of(context)
            .pushNamed<ProfileData>(AppRoutes.editProfile, arguments: profile);
      },
    );
  }

  static void _openMyMatchesEntry(
    BuildContext context,
    MyMatchesItem item,
    MyMatchesTab tab,
  ) {
    final match = item.match;

    if (match.status == MatchStatus.completed) {
      Navigator.of(context)
          .pushNamed(AppRoutes.matchCompleted, arguments: match);
      return;
    }

    if (tab == MyMatchesTab.invites) {
      _openInvitationReceiving(context, match);
      return;
    }

    final isCreatedByMe = tab == MyMatchesTab.createdByMe;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MatchDetailsScreen(
          match: match,
          isCurrentUserJoined: true,
          canCancelMatch: isCreatedByMe,
          onBack: () => Navigator.of(context).maybePop(),
          onInvitePlayers: () {
            _openInvitePlayers(context, match);
          },
          onChat: (_) {
            Navigator.of(context)
                .pushNamed(AppRoutes.matchChat, arguments: match);
          },
        ),
      ),
    );
  }

  static Future<void> _openInvitePlayers(
    BuildContext context,
    HomeMatch match,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: AppRoutes.invitePlayers,
          arguments: match,
        ),
        builder: (inviteContext) => InvitePlayersScreen(
          match: match,
          initialResults: InvitePlayersPreviewData.forMatch(match),
          onBack: () => Navigator.of(inviteContext).maybePop(),
          onPreviewInvitationReceived: () {
            _openInvitationReceiving(inviteContext, match);
          },
        ),
      ),
    );
  }

  static Future<void> _openInvitationReceiving(
    BuildContext context,
    HomeMatch match,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: AppRoutes.invitationReceiving,
          arguments: match,
        ),
        builder: (invitationContext) =>
            _buildInvitationReceivingScreen(invitationContext, match),
      ),
    );
  }

  static InvitationReceivingScreen _buildInvitationReceivingScreen(
    BuildContext context,
    HomeMatch match,
  ) {
    return InvitationReceivingScreen(
      match: match,
      onBack: () => Navigator.of(context).maybePop(),
      onDecline: (_) async {
        if (context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      onAccept: (_) async {
        if (!context.mounted) return;
        _replaceWithJoinedMatchDetails(context, match);
      },
      onOkay: () => Navigator.of(context).maybePop(),
    );
  }

  static void _replaceWithJoinedMatchDetails(
    BuildContext context,
    HomeMatch match,
  ) {
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: AppRoutes.matchDetails, arguments: match),
        builder: (joinedContext) => MatchDetailsScreen(
          match: match,
          isCurrentUserJoined: true,
          canCancelMatch: false,
          onBack: () => Navigator.of(joinedContext).maybePop(),
          onInvitePlayers: () {
            _openInvitePlayers(joinedContext, match);
          },
          onChat: (_) {
            Navigator.of(joinedContext)
                .pushNamed(AppRoutes.matchChat, arguments: match);
          },
        ),
      ),
    );
  }

  static void _openPlayerProfile(
    BuildContext context,
    ChatParticipant participant,
    HomeMatch match,
  ) {
    final player = PlayerProfilePreviewData.forIdentity(
      id: participant.id,
      displayName: participant.displayName,
      avatarAsset: participant.avatarAsset,
    );

    Navigator.of(context).pushNamed(
      AppRoutes.playerProfile,
      arguments: PlayerProfileRouteArgs(player: player, inviteMatch: match),
    );
  }

  static HomeMatch? _defaultInviteMatch() {
    final data = MyMatchesPreviewData.create();
    for (final item in data.createdByMe) {
      final match = item.match;
      if (match.status != MatchStatus.cancelled &&
          match.status != MatchStatus.completed) {
        return match;
      }
    }
    return null;
  }

  static void _openHeaderChat(BuildContext context) {
    final myMatches = MyMatchesPreviewData.create();
    HomeMatch? chatMatch;
    for (final item in myMatches.upcoming) {
      if (item.match.status != MatchStatus.cancelled) {
        chatMatch = item.match;
        break;
      }
    }

    final match = chatMatch ?? HomePreviewData.create().upcomingMatches.first;
    Navigator.of(context).pushNamed(AppRoutes.matchChat, arguments: match);
  }

  static void _openNotificationDestination(
    BuildContext context,
    MahjNotification notification,
  ) {
    final match = _resolveNotificationMatch(notification.relatedMatchId);
    if (match == null) return;

    switch (notification.type) {
      case MahjNotificationType.matchInvite:
        _openInvitationReceiving(context, match);
        return;
      case MahjNotificationType.chatMessage:
        Navigator.of(context).pushNamed(AppRoutes.matchChat, arguments: match);
        return;
      case MahjNotificationType.matchCompleted:
      case MahjNotificationType.scoreSubmitted:
        Navigator.of(context)
            .pushNamed(AppRoutes.matchCompleted, arguments: match);
        return;
      case MahjNotificationType.nearbyMatch:
      case MahjNotificationType.matchAccepted:
      case MahjNotificationType.matchCancelled:
      case MahjNotificationType.matchConfirmed:
        _openMatchDetails(context, match);
        return;
    }
  }

  static HomeMatch? _resolveNotificationMatch(String? id) {
    if (id == null || id.isEmpty) return null;

    final home = HomePreviewData.create();
    for (final match in <HomeMatch>[
      ...home.upcomingMatches,
      ...home.nearbyMatches,
    ]) {
      if (match.id == id) return match;
    }

    final myMatches = MyMatchesPreviewData.create();
    for (final item in <MyMatchesItem>[
      ...myMatches.upcoming,
      ...myMatches.createdByMe,
      ...myMatches.invites,
    ]) {
      if (item.match.id == id) return item.match;
    }

    return null;
  }

  static void _openMatchDetails(BuildContext context, HomeMatch match) {
    Navigator.of(context).pushNamed(AppRoutes.matchDetails, arguments: match);
  }
}
