class ReportReason {
  const ReportReason({required this.id, required this.label});

  final String id;
  final String label;
}

const List<ReportReason> demoReportReasons = [
  ReportReason(id: 'inappropriate_behavior', label: 'Inappropriate behavior'),
  ReportReason(
    id: 'harassment_or_abusive_language',
    label: 'Harassment or abusive language',
  ),
  ReportReason(
    id: 'spam_or_misleading_information',
    label: 'Spam or misleading information',
  ),
  ReportReason(id: 'fake_match', label: 'Fake match'),
  ReportReason(id: 'safety_concern', label: 'Safety concern'),
  ReportReason(
    id: 'no_show_or_unreliable_host',
    label: 'No-show / unreliable host',
  ),
  ReportReason(id: 'other', label: 'Other'),
];

class ReportMatchRequest {
  const ReportMatchRequest({
    required this.matchId,
    required this.reportedUserId,
    required this.reasonId,
    required this.notes,
  });

  final String matchId;
  final String reportedUserId;
  final String reasonId;
  final String notes;
}
