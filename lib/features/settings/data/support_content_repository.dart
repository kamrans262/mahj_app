import '../../../core/network/api_client.dart';
import '../domain/legal_data.dart';
import '../domain/support_data.dart';

class SupportContentRepository {
  const SupportContentRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<SupportContentData> loadSupport() async {
    final payload = await _apiClient.get(
      '/content/support',
      authenticated: false,
    );

    final faqsRaw = payload['faqs'];
    final topicsRaw = payload['topics'];

    final faqs = faqsRaw is List
        ? faqsRaw
              .whereType<Map>()
              .map((item) {
                final json = _normalize(item);
                return SupportFaq(
                  id: json['id']?.toString() ?? '',
                  question: json['question']?.toString() ?? '',
                  answer: json['answer']?.toString() ?? '',
                );
              })
              .where((faq) => faq.id.isNotEmpty && faq.question.isNotEmpty)
              .toList(growable: false)
        : const <SupportFaq>[];

    final topics = topicsRaw is List
        ? topicsRaw
              .whereType<Map>()
              .map((item) {
                final json = _normalize(item);
                return SupportTopic(
                  id: json['id']?.toString() ?? '',
                  label: json['label']?.toString() ?? '',
                );
              })
              .where((topic) => topic.id.isNotEmpty && topic.label.isNotEmpty)
              .toList(growable: false)
        : const <SupportTopic>[];

    return SupportContentData(
      faqs: faqs,
      topics: topics,
      supportEmail: payload['support_email']?.toString() ?? '',
    );
  }

  Future<({LegalDocumentData terms, LegalDocumentData privacy})>
  loadLegal() async {
    final payload = await _apiClient.get(
      '/content/legal',
      authenticated: false,
    );

    return (
      terms: _legalDocument(
        payload['terms'],
        fallbackType: LegalDocumentType.terms,
        fallbackTitle: 'Terms & Conditions',
      ),
      privacy: _legalDocument(
        payload['privacy'],
        fallbackType: LegalDocumentType.privacy,
        fallbackTitle: 'Privacy Policy',
      ),
    );
  }

  Future<void> submitIssue(SupportIssueRequest request) async {
    final screenshot = request.screenshot;

    await _apiClient.postMultipart(
      '/support-requests',
      fields: {
        'topic': request.topic.id,
        'message': request.message.trim(),
      },
      fileField: screenshot == null ? null : 'screenshot',
      fileBytes: screenshot?.bytes,
      fileName: screenshot?.displayName,
    );
  }

  LegalDocumentData _legalDocument(
    dynamic raw, {
    required LegalDocumentType fallbackType,
    required String fallbackTitle,
  }) {
    final json = raw is Map
        ? _normalize(raw)
        : const <String, dynamic>{};
    final sectionsRaw = json['sections'];

    final sections = sectionsRaw is List
        ? sectionsRaw
              .whereType<Map>()
              .map((item) {
                final section = _normalize(item);
                final paragraphsRaw = section['paragraphs'];
                final paragraphs = paragraphsRaw is List
                    ? paragraphsRaw
                          .map((item) => item.toString())
                          .where((item) => item.trim().isNotEmpty)
                          .toList(growable: false)
                    : const <String>[];

                return LegalSectionData(
                  title: section['title']?.toString() ?? '',
                  paragraphs: paragraphs,
                );
              })
              .where(
                (section) =>
                    section.title.trim().isNotEmpty ||
                    section.paragraphs.isNotEmpty,
              )
              .toList(growable: false)
        : const <LegalSectionData>[];

    return LegalDocumentData(
      type: fallbackType,
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString()
          : fallbackTitle,
      lastUpdated: json['last_updated']?.toString() ?? '',
      sections: sections,
    );
  }

  Map<String, dynamic> _normalize(Map value) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
