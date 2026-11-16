import 'dart:async';

import 'package:flutter/foundation.dart';

enum AccessAction { refresh, restore }

/// Shares request locks and cooldowns across the account and purchase screens.
class AccessActionGuard extends ChangeNotifier {
  AccessActionGuard({Duration Function()? elapsed})
    : _elapsed = elapsed ?? _monotonicClock();

  static Duration Function() _monotonicClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  final Duration Function() _elapsed;
  final _nextAllowed = <AccessAction, Duration>{};
  Timer? _timer;
  bool _busy = false;
  bool get busy => _busy;

  Duration remaining(AccessAction action) {
    final wait = (_nextAllowed[action] ?? Duration.zero) - _elapsed();
    return wait > Duration.zero ? wait : Duration.zero;
  }

  bool canRun(AccessAction action) =>
      !busy && remaining(action) == Duration.zero;

  Future<void> run(AccessAction action, Future<void> Function() request) async {
    if (busy) throw StateError('Devam eden işlemin tamamlanmasını bekle.');
    final wait = remaining(action);
    if (wait > Duration.zero) {
      final seconds = (wait.inMilliseconds / 1000).ceil();
      throw StateError('Tekrar denemek için $seconds saniye bekle.');
    }
    _busy = true;
    _nextAllowed[action] =
        _elapsed() +
        Duration(seconds: action == AccessAction.refresh ? 30 : 60);
    _schedule();
    notifyListeners();
    try {
      await request();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _schedule() {
    _timer?.cancel();
    final waits = AccessAction.values
        .map(remaining)
        .where((wait) => wait > Duration.zero);
    if (waits.isEmpty) return;
    final soonest = waits.reduce((a, b) => a < b ? a : b);
    _timer = Timer(soonest, () {
      _schedule();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
