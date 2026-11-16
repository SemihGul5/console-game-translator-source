import 'dart:convert';
import 'dart:typed_data';

class PsnAccountIdService {
  /// Sony yanıtından alınan sayısal user_id değerini,
  /// Chiaki'nin beklediği 8 baytlık little-endian Base64
  /// biçimine dönüştürür.
  ///
  /// Bu metot token almaz ve Sony sunucusuna bağlanmaz.
  static String convertUserIdToBase64(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(normalized)) {
      throw const FormatException('user_id pozitif bir tam sayı olmalıdır.');
    }

    final id = int.tryParse(normalized);

    // Dart int sınırı içinde ve 8 bayta sığan değerleri kabul et.
    if (id == null || id < 0) {
      throw const FormatException('user_id geçerli bir sayısal değer değil.');
    }

    final data = ByteData(8);
    data.setUint64(0, id, Endian.little);

    return base64Encode(data.buffer.asUint8List());
  }
}
