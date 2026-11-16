import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/access_action_guard.dart';

AccessActionGuard _guard(WidgetTester tester) {
  final start = tester.binding.clock.now();
  final guard = AccessActionGuard(
    elapsed: () => tester.binding.clock.now().difference(start),
  );
  addTearDown(guard.dispose);
  return guard;
}

void main() {
  testWidgets('refresh and restore share an in-flight lock without a queue', (
    tester,
  ) async {
    final guard = _guard(tester);
    final completion = Completer<void>();
    var requests = 0;
    final first = guard.run(AccessAction.refresh, () {
      requests++;
      return completion.future;
    });
    for (var i = 0; i < 10; i++) {
      await expectLater(
        guard.run(AccessAction.refresh, () async => requests++),
        throwsStateError,
      );
      await expectLater(
        guard.run(AccessAction.restore, () async => requests++),
        throwsStateError,
      );
    }
    expect(requests, 1);
    // Even when cooldown has elapsed, an unfinished request keeps the lock.
    await tester.pump(const Duration(seconds: 65));
    expect(guard.canRun(AccessAction.restore), isFalse);
    completion.complete();
    await first;
    await tester.pump();
    expect(requests, 1);
    expect(guard.busy, isFalse);
  });

  testWidgets('refresh is limited to one request every thirty seconds', (
    tester,
  ) async {
    final guard = _guard(tester);
    var requests = 0;
    await guard.run(AccessAction.refresh, () async => requests++);
    await tester.pump(const Duration(seconds: 29));
    await expectLater(
      guard.run(AccessAction.refresh, () async => requests++),
      throwsStateError,
    );
    expect(requests, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(guard.canRun(AccessAction.refresh), isTrue);
    await guard.run(AccessAction.refresh, () async => requests++);
    expect(requests, 2);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('restore failures still enforce sixty seconds without requests', (
    tester,
  ) async {
    final guard = _guard(tester);
    var requests = 0;
    await expectLater(
      guard.run(AccessAction.restore, () async {
        requests++;
        throw StateError('Network unavailable');
      }),
      throwsStateError,
    );
    expect(guard.busy, isFalse);
    await tester.pump(const Duration(seconds: 59));
    await expectLater(
      guard.run(AccessAction.restore, () async => requests++),
      throwsStateError,
    );
    expect(requests, 1);
    await tester.pump(const Duration(seconds: 1));
    await guard.run(AccessAction.restore, () async => requests++);
    expect(requests, 2);
    await tester.pump(const Duration(seconds: 60));
  });

  testWidgets(
    'cooldown expiry only notifies the UI, it never sends a request',
    (tester) async {
      final guard = _guard(tester);
      var requests = 0;
      var notifications = 0;
      guard.addListener(() => notifications++);
      await guard.run(AccessAction.refresh, () async => requests++);
      await guard.run(AccessAction.restore, () async => requests++);
      final previous = notifications;
      await tester.pump(const Duration(seconds: 30));
      expect(guard.canRun(AccessAction.refresh), isTrue);
      expect(guard.canRun(AccessAction.restore), isFalse);
      expect(notifications, greaterThan(previous));
      await tester.pump(const Duration(seconds: 30));
      expect(guard.canRun(AccessAction.restore), isTrue);
      expect(requests, 2);
    },
  );
}
