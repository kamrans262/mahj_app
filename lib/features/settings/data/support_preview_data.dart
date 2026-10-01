import '../domain/support_data.dart';

abstract final class SupportPreviewData {
  static const faqs = <SupportFaq>[
    SupportFaq(
      id: 'invitations',
      question: 'How do match invitations work?',
      answer:
          'A host can invite players to an open match. Invitations appear in My Matches under Invites while the match remains available.',
    ),
    SupportFaq(
      id: 'nearby',
      question: 'How do I find matches near me?',
      answer:
          'Use the Home filters to choose a location and radius, then browse the nearby list or map.',
    ),
    SupportFaq(
      id: 'safety',
      question: 'How do I report or block another player?',
      answer:
          'Open that player’s profile and use Report User or Block User in the safety actions.',
    ),
  ];

  static const topics = <SupportTopic>[
    SupportTopic(id: 'matches', label: 'Matches & invitations'),
    SupportTopic(id: 'account', label: 'Account & profile'),
    SupportTopic(id: 'subscription', label: 'Subscription & billing'),
    SupportTopic(id: 'safety', label: 'Safety & reporting'),
    SupportTopic(id: 'technical', label: 'Technical issue'),
    SupportTopic(id: 'other', label: 'Other'),
  ];

  static const supportEmail = 'support@mahj.app';
}
