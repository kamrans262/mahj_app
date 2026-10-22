import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/subscription/data/checkout_return_store.dart';

void main() {
  test('accepts a verified-format Stripe success callback as a pending event', () {
    final store = CheckoutReturnStore();
    addTearDown(store.dispose);
    var events = 0;
    store.addListener(() => events++);

    store.accept(
      Uri.parse('mahjaroundtown://billing/success?session_id=cs_test_abc123'),
    );

    expect(events, 1);
    final result = store.take();
    expect(result, isNotNull);
    expect(result!.cancelled, isFalse);
    expect(result.sessionId, 'cs_test_abc123');
    expect(store.take(), isNull);
  });

  test('cancel callback does not carry an activation session', () {
    final store = CheckoutReturnStore();
    addTearDown(store.dispose);

    store.accept(Uri.parse('mahjaroundtown://billing/cancel'));
    final result = store.take();

    expect(result, isNotNull);
    expect(result!.cancelled, isTrue);
    expect(result.sessionId, isNull);
  });

  test('rejects unknown schemes, paths, and malformed session IDs', () {
    final store = CheckoutReturnStore();
    addTearDown(store.dispose);
    var events = 0;
    store.addListener(() => events++);

    for (final value in [
      'https://billing/success?session_id=cs_test_1234',
      'mahjaroundtown://other/success?session_id=cs_test_1234',
      'mahjaroundtown://billing/home?session_id=cs_test_1234',
      'mahjaroundtown://billing/success',
      'mahjaroundtown://billing/success?session_id=not_a_session',
      'mahjaroundtown://billing/success?session_id=cs_test_%3Cscript%3E',
    ]) {
      store.accept(Uri.parse(value));
    }

    expect(events, 0);
    expect(store.take(), isNull);
  });

  test('a newer callback replaces an unconsumed previous callback', () {
    final store = CheckoutReturnStore();
    addTearDown(store.dispose);

    store.accept(
      Uri.parse('mahjaroundtown://billing/success?session_id=cs_test_first'),
    );
    store.accept(
      Uri.parse('mahjaroundtown://billing/success?session_id=cs_test_latest'),
    );

    expect(store.take()?.sessionId, 'cs_test_latest');
    expect(store.take(), isNull);
  });
}
