import '../../matches/domain/match_report.dart';

const List<ReportReason> playerReportReasons = [
  ReportReason(id: 'inappropriate_behavior', label: 'Inappropriate behavior'),
  ReportReason(
    id: 'harassment_or_abusive_language',
    label: 'Harassment or abusive language',
  ),
  ReportReason(
    id: 'spam_or_unwanted_messages',
    label: 'Spam or unwanted messages',
  ),
  ReportReason(
    id: 'offensive_profile_or_content',
    label: 'Offensive profile/content',
  ),
  ReportReason(
    id: 'fake_or_misleading_profile',
    label: 'Fake or misleading profile',
  ),
  ReportReason(
    id: 'cheating_or_unfair_behavior',
    label: 'Cheating or unfair behavior',
  ),
  ReportReason(id: 'safety_concern', label: 'Safety concern'),
  ReportReason(id: 'other', label: 'Other'),
];

const List<ReportReason> playerBlockReasons = [
  ReportReason(
    id: 'harassment_or_abusive_behavior',
    label: 'Harassment or abusive behavior',
  ),
  ReportReason(
    id: 'spam_or_unwanted_messages',
    label: 'Spam or unwanted messages',
  ),
  ReportReason(id: 'inappropriate_behavior', label: 'Inappropriate behavior'),
  ReportReason(
    id: 'do_not_want_to_play',
    label: 'I do not want to play with this person',
  ),
  ReportReason(id: 'repeated_no_shows', label: 'Repeated no-shows'),
  ReportReason(id: 'safety_concern', label: 'Safety concern'),
  ReportReason(id: 'other', label: 'Other'),
];
