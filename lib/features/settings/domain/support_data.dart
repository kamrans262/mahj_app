class SupportFaq {
  const SupportFaq({required this.id, required this.question});

  final String id;
  final String question;
}

class SupportTopic {
  const SupportTopic({required this.id, required this.label});

  final String id;
  final String label;
}

class SupportAttachment {
  const SupportAttachment({required this.id, required this.displayName});

  final String id;
  final String displayName;
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
