import 'dart:typed_data';

class SupportFaq {
  const SupportFaq({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;
}

class SupportTopic {
  const SupportTopic({required this.id, required this.label});

  final String id;
  final String label;
}

class SupportAttachment {
  const SupportAttachment({
    required this.id,
    required this.displayName,
    required this.bytes,
    required this.contentType,
  });

  final String id;
  final String displayName;
  final Uint8List bytes;
  final String contentType;
}

class SupportIssueRequest {
  const SupportIssueRequest({
    required this.topic,
    required this.message,
    this.screenshot,
  });

  final SupportTopic topic;
  final String message;
  final SupportAttachment? screenshot;
}

class SupportContentData {
  const SupportContentData({
    required this.faqs,
    required this.topics,
    required this.supportEmail,
  });

  final List<SupportFaq> faqs;
  final List<SupportTopic> topics;
  final String supportEmail;
}
