import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/domain/match_report.dart';
import 'package:mahj_app/features/matches/presentation/widgets/report_reason_selection_dialog.dart';

class _ReasonHarness extends StatefulWidget {
  const _ReasonHarness();

  @override
  State<_ReasonHarness> createState() => _ReasonHarnessState();
}

class _ReasonHarnessState extends State<_ReasonHarness> {
  ReportReason? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const ValueKey('open-reason-selector'),
          onPressed: () async {
            final value = await showReportReasonSelectionDialog(
              context: context,
              reasons: demoReportReasons,
              selectedReason: selected,
            );
            if (!mounted || value == null) return;
            setState(() => selected = value);
          },
          child: Text(selected?.label ?? 'Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('reason selector avoids intrinsic viewport measurement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: _ReasonHarness()));
    await tester.tap(find.byKey(const ValueKey('open-reason-selector')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('report-reason-selection-dialog')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('report-reason-option-inappropriate_behavior')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inappropriate behavior'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reason selector can reach a lazily built lower option', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const reasons = <ReportReason>[
      ReportReason(id: 'one', label: 'One'),
      ReportReason(id: 'two', label: 'Two'),
      ReportReason(id: 'three', label: 'Three'),
      ReportReason(id: 'four', label: 'Four'),
      ReportReason(id: 'five', label: 'Five'),
      ReportReason(id: 'safety_concern', label: 'Safety concern'),
      ReportReason(id: 'other', label: 'Other'),
    ];

    ReportReason? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('open-long-reason-selector'),
                onPressed: () async {
                  selected = await showReportReasonSelectionDialog(
                    context: context,
                    reasons: reasons,
                    selectedReason: null,
                  );
                },
                child: const Text('Open long list'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-long-reason-selector')));
    await tester.pumpAndSettle();

    final list = find.byKey(const ValueKey('report-reason-options-list'));
    final target = find.byKey(
      const ValueKey('report-reason-option-safety_concern'),
    );
    expect(list, findsOneWidget);

    for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
      await tester.drag(list, const Offset(0, -72));
      await tester.pump();
    }

    expect(target, findsOneWidget);
    await tester.ensureVisible(target);
    await tester.pump();
    await tester.tap(target);
    await tester.pumpAndSettle();

    expect(selected?.id, 'safety_concern');
    expect(tester.takeException(), isNull);
  });
}
