
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/services/psn_account_id_service.dart';

void main() {
  group('PsnAccountIdService', () {
    test('sayısal user_id değerini Base64 biçimine çevirir', () {
      final result =
      PsnAccountIdService.convertUserIdToBase64('1');

      expect(result, 'AQAAAAAAAAA=');
    });

    test('boş user_id kabul edilmez', () {
      expect(
            () => PsnAccountIdService.convertUserIdToBase64(''),
        throwsFormatException,
      );
    });

    test('sayısal olmayan user_id kabul edilmez', () {
      expect(
            () => PsnAccountIdService.convertUserIdToBase64('abc'),
        throwsFormatException,
      );
    });
  });
}
