import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/access_service.dart';

void main() {
  test(
    'unused verified trials can prepare a session without granting paid output or spending time',
    () {
      final ready = AccessStatus.fromMap({
        'state': 'available',
        'source': 'free_trial',
        'freeTrialMinutes': 60,
      });
      expect(ready.canPrepareTranslation, isTrue);
      expect(ready.canStart, isFalse);
      expect(ready.expiresAt, isNull);
      expect(ready.trialRemaining, Duration.zero);
      for (final state in ['signed_out', 'expired', 'verification_required']) {
        expect(
          AccessStatus.fromMap({
            'state': state,
            'source': 'free_trial',
            'freeTrialMinutes': 60,
          }).canPrepareTranslation,
          isFalse,
        );
      }
      expect(
        const AccessStatus(
          'available',
          source: 'free_trial',
        ).canPrepareTranslation,
        isFalse,
      );
    },
  );
  test(
    'a calendar trial grants translation without pretending to be a purchase',
    () {
      final status = AccessStatus.fromMap({
        'state': 'trial',
        'source': 'free_trial',
        'expiresAtMs': 3600000,
        'trialRemainingMs': 3599001,
      });
      expect(status.canStart, isTrue);
      expect(status.premium, isFalse);
      expect(status.remainingLabel, '60:00');
      expect(
        AccessStatus.fromMap({
          'state': 'trial',
          'source': 'free_trial',
          'trialRemainingMs': 1,
        }).remainingLabel,
        '00:01',
      );
      expect(
        AccessStatus.fromMap({
          'state': 'trial',
          'source': 'free_trial',
          'trialRemainingMs': 0,
        }).canStart,
        isFalse,
      );
    },
  );
  test(
    'trial countdown supports longer remote offers while preserving existing deadlines',
    () {
      AccessStatus trial(int remaining) => AccessStatus.fromMap({
        'state': 'trial',
        'source': 'free_trial',
        'trialRemainingMs': remaining,
      });
      expect(trial(1800000).remainingLabel, '30:00');
      expect(trial(3600000).remainingLabel, '60:00');
      expect(trial(7200000).remainingLabel, '120:00');
      expect(trial(999999999).remainingLabel, '1440:00');
      expect(trial(-1).canStart, isFalse);
    },
  );
  test('only valid server durations can be advertised', () {
    for (final minutes in [15, 60, 90, 120, 1440]) {
      expect(
        AccessStatus.fromMap({'freeTrialMinutes': minutes}).freeTrialMinutes,
        minutes,
      );
    }
    for (final value in [null, 0, -1, 1441, '60', 60.5]) {
      expect(
        AccessStatus.fromMap({'freeTrialMinutes': value}).freeTrialMinutes,
        isNull,
      );
    }
  });
  test('an unstarted or expired trial never grants translation', () {
    for (final state in [
      'signed_out',
      'available',
      'expired',
      'verification_required',
    ]) {
      expect(AccessStatus(state).canStart, isFalse);
    }
    expect(const AccessStatus('premium').canStart, isTrue);
    expect(const AccessStatus('lifetime').canStart, isTrue);
  });
}
