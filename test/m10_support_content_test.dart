import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/core/network/api_client.dart';
import 'package:mahj_app/core/storage/token_store.dart';
import 'package:mahj_app/features/home/data/home_preview_data.dart';
import 'package:mahj_app/features/home/presentation/widgets/featured_match_card.dart';
import 'package:mahj_app/features/settings/data/support_content_repository.dart';
import 'package:mahj_app/features/settings/domain/legal_data.dart';
import 'package:mahj_app/features/settings/domain/support_data.dart';
import 'package:mahj_app/features/settings/presentation/support_screen.dart';

void main() {
  test('M10 repository loads support and legal content', () async {
    final tokenStore = SecureTokenStore(useMemoryOnly: true);
    final client = MockClient((request) async {
      if (request.url.path == '/api/content/support') {
        return http.Response(
          jsonEncode({
            'faqs': [
              {
                'id': '1',
                'question': 'How do invitations work?',
                'answer': 'Open the invitation from My Matches.',
              },
            ],
            'topics': [
              {'id': 'technical', 'label': 'Technical issue'},
            ],
            'support_email': 'help@mahj.test',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.url.path == '/api/content/legal') {
        return http.Response(
          jsonEncode({
            'terms': {
              'type': 'terms',
              'title': 'Terms & Conditions',
              'last_updated': 'October 2, 2026',
              'sections': [
                {
                  'title': 'Acceptance',
                  'paragraphs': ['Use Mahj according to these terms.'],
                },
              ],
            },
            'privacy': {
              'type': 'privacy',
              'title': 'Privacy Policy',
              'last_updated': 'October 2, 2026',
              'sections': [
                {
                  'title': 'Information We Collect',
                  'paragraphs': ['Mahj processes service information.'],
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('Not found', 404);
    });

    final repository = SupportContentRepository(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        tokenStore: tokenStore,
        httpClient: client,
      ),
    );

    final support = await repository.loadSupport();
    expect(support.faqs, hasLength(1));
    expect(support.faqs.single.answer, 'Open the invitation from My Matches.');
    expect(support.supportEmail, 'help@mahj.test');

    final legal = await repository.loadLegal();
    expect(legal.terms.type, LegalDocumentType.terms);
    expect(legal.terms.sections.single.title, 'Acceptance');
    expect(legal.privacy.type, LegalDocumentType.privacy);
    expect(legal.privacy.sections.single.title, 'Information We Collect');
  });

  testWidgets('M10 support stays merged and submits on the same screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const faq = SupportFaq(
      id: 'faq-1',
      question: 'How do invitations work?',
      answer: 'Open the invitation from My Matches.',
    );
    const topic = SupportTopic(id: 'technical', label: 'Technical issue');

    SupportIssueRequest? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: SupportScreen(
          faqs: const [faq],
          topics: const [topic],
          supportEmail: 'help@mahj.test',
          onPickScreenshot: () async => SupportAttachment(
            id: 'shot',
            displayName: 'problem.png',
            bytes: Uint8List.fromList(const [1, 2, 3]),
            contentType: 'image/png',
          ),
          onSubmitIssue: (request) async {
            submitted = request;
            return true;
          },
          onEmailSupport: () {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('support-faq-faq-1')));
    await tester.pump();
    expect(find.text('Open the invitation from My Matches.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('support-topic-field')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('support-topic-option-technical')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('support-message-field')),
      'The match screen does not load.',
    );

    final upload = find.byKey(const ValueKey('support-upload-screenshot'));
    await tester.ensureVisible(upload);
    await tester.tap(upload);
    await tester.pumpAndSettle();
    expect(find.text('problem.png'), findsOneWidget);

    final submit = find.byKey(const ValueKey('support-submit-button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.topic.id, 'technical');
    expect(submitted!.screenshot?.displayName, 'problem.png');
    expect(find.text('Support request submitted.'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-email-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home Join Match uses Mahj orange', (tester) async {
    final match = HomePreviewData.create().upcomingMatches.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeaturedMatchCard(
            match: match,
            onJoin: () {},
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Join Match'),
    );
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.primary,
    );
  });
}
