import '../domain/support_data.dart';

abstract final class SupportPreviewData {
  static const faqs = <SupportFaq>[
    SupportFaq(id: 'invitations-1', question: 'How do invitations works?'),
    SupportFaq(id: 'invitations-2', question: 'How do invitations works?'),
    SupportFaq(id: 'invitations-3', question: 'How do invitations works?'),
  ];

  static const topics = <SupportTopic>[
    SupportTopic(id: 'matches', label: 'Matches & invitations'),
    SupportTopic(id: 'account', label: 'Account & profile'),
    SupportTopic(id: 'subscription', label: 'Subscription & billing'),
    SupportTopic(id: 'safety', label: 'Safety & reporting'),
    SupportTopic(id: 'technical', label: 'Technical issue'),
    SupportTopic(id: 'other', label: 'Other'),
  ];
}
