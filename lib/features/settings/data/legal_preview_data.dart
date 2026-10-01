import '../domain/legal_data.dart';

abstract final class LegalPreviewData {
  static const LegalDocumentData terms = LegalDocumentData(
    type: LegalDocumentType.terms,
    title: 'Terms & Conditions',
    lastUpdated: 'June 8, 2026',
    sections: [
      LegalSectionData(
        title: 'Acceptance of Terms',
        paragraphs: [
          'By creating an account, accessing, or using Mahj, you agree to be bound by these Terms & Conditions. If you do not agree with any part of these terms, you must not use the app.',
        ],
      ),
      LegalSectionData(
        title: 'Eligibility',
        paragraphs: [
          'You must meet the minimum age requirements that apply in your jurisdiction to use Mahj. By using the app, you confirm that the information you provide is accurate and that you are permitted to participate in matches.',
        ],
      ),
      LegalSectionData(
        title: 'User Accounts',
        paragraphs: [
          'You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs through your account.',
        ],
      ),
      LegalSectionData(
        title: 'App Purpose',
        paragraphs: [
          'Mahj helps players discover, create, and coordinate local games. Mahj does not organize, supervise, or guarantee the quality, safety, legality, or availability of any match or event.',
        ],
      ),
      LegalSectionData(
        title: 'Match Participation',
        paragraphs: [
          'Players are responsible for their own safety, transportation, equipment, health, and conduct during any game or event arranged through the app.',
        ],
      ),
      LegalSectionData(
        title: 'Payment & Subscriptions',
        paragraphs: [
          'Certain features may require payment or a subscription. Pricing, billing cycles, trials, and renewal terms will be shown before purchase.',
          'Purchases are also subject to the policies of the platform or payment provider used to complete the transaction.',
        ],
      ),
      LegalSectionData(
        title: 'Content Ownership',
        paragraphs: [
          'You retain ownership of content you submit to Mahj. You grant Mahj the permissions reasonably required to host, display, and process that content to provide the service.',
        ],
      ),
      LegalSectionData(
        title: 'Community Conduct',
        paragraphs: [
          'You must treat other players respectfully and must not use Mahj for harassment, threats, fraud, unlawful activity, or conduct that places other users at risk.',
        ],
      ),
      LegalSectionData(
        title: 'Changes to These Terms',
        paragraphs: [
          'We may update these terms as the product evolves. Material changes should be presented to users through the app or another appropriate notice.',
        ],
      ),
    ],
  );

  static const LegalDocumentData privacy = LegalDocumentData(
    type: LegalDocumentType.privacy,
    title: 'Privacy Policy',
    lastUpdated: 'June 8, 2026',
    sections: [
      LegalSectionData(
        title: 'Information We Collect',
        paragraphs: [
          'Mahj may collect account information, profile details, match activity, support requests, device information, and other data you choose to provide when using the app.',
        ],
      ),
      LegalSectionData(
        title: 'How We Use Information',
        paragraphs: [
          'We use information to operate the app, show relevant matches, support account features, improve reliability, prevent abuse, and respond to support requests.',
        ],
      ),
      LegalSectionData(
        title: 'Location Information',
        paragraphs: [
          'When you allow location access, Mahj may use location information to show nearby matches and distance-based results. You can control device location permissions through your operating-system settings.',
        ],
      ),
      LegalSectionData(
        title: 'Sharing of Information',
        paragraphs: [
          'We do not sell personal information. Information may be shared with service providers when needed to operate Mahj, comply with law, protect users, or complete a service you request.',
        ],
      ),
      LegalSectionData(
        title: 'Data Retention',
        paragraphs: [
          'Information is retained only for as long as reasonably necessary for the purposes described in this policy, including account administration, safety, legal, and operational needs.',
        ],
      ),
      LegalSectionData(
        title: 'Your Choices',
        paragraphs: [
          'You may update profile information, manage certain permissions, block users, and request account deletion through the relevant Mahj settings when those services are connected.',
        ],
      ),
      LegalSectionData(
        title: 'Security',
        paragraphs: [
          'Mahj uses reasonable technical and organizational safeguards designed to protect information, but no method of transmission or storage can be guaranteed to be completely secure.',
        ],
      ),
      LegalSectionData(
        title: 'Children’s Privacy',
        paragraphs: [
          'Mahj is not intended for users who are below the minimum permitted age for the service in their jurisdiction.',
        ],
      ),
      LegalSectionData(
        title: 'Contact Us',
        paragraphs: [
          'Questions about this privacy policy can be submitted through the Support screen in the app.',
        ],
      ),
    ],
  );
}
