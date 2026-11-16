import 'dart:io';

/// TV setup accepts literal private IPv4 addresses, never URLs or DNS names.
abstract final class LanTvAddress {
  static bool isPrivateIpv4(String value) {
    final address = InternetAddress.tryParse(value);
    if (address == null ||
        address.type != InternetAddressType.IPv4 ||
        address.address != value) {
      return false;
    }
    final b = address.rawAddress;
    return b[0] == 10 ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 192 && b[1] == 168);
  }

  static Future<List<String>> localAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return interfaces
        .expand((i) => i.addresses)
        .map((a) => a.address)
        .where(isPrivateIpv4)
        .toSet()
        .toList();
  }
}
