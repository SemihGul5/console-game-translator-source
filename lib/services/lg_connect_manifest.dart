/// Registration manifests for LG's second-screen (SSAP) API.
///
/// Firmware differs: some webOS releases (including webOS Hub builds sold by
/// partner brands) reject an unsigned manifest, while newer releases reject
/// the old signature. The client tries the unsigned manifest first and falls
/// back to the signed one when the TV refuses it before showing a prompt.
///
/// The signed block and its signature are LG's public test manifest from the
/// LG Connect SDK (Apache License 2.0), as used by open-source webOS clients
/// such as aiowebostv. It is not a secret. Only the notification permission is
/// requested at the top level; no remote-control privileges are asked for.
abstract final class LgConnectManifest {
  static const requested = <String>['WRITE_NOTIFICATION_TOAST'];

  static Map<String, Object> unsigned() => {
    'manifestVersion': 1,
    'permissions': requested,
  };

  static Map<String, Object> signed() => {
    'manifestVersion': 1,
    'appVersion': '1.1',
    'signed': _signedBlock,
    'permissions': requested,
    'signatures': const [
      {'signatureVersion': 1, 'signature': _signature},
    ],
  };

  static const _signedBlock = <String, Object>{
    'created': '20140509',
    'appId': 'com.lge.test',
    'vendorId': 'com.lge',
    'localizedAppNames': {
      '': 'LG Remote App',
      'ko-KR': '리모컨 앱',
      'zxx-XX': 'ЛГ Rэмotэ AПП',
    },
    'localizedVendorNames': {'': 'LG Electronics'},
    'permissions': [
      'TEST_SECURE',
      'CONTROL_INPUT_TEXT',
      'CONTROL_MOUSE_AND_KEYBOARD',
      'READ_INSTALLED_APPS',
      'READ_LGE_SDX',
      'READ_NOTIFICATIONS',
      'SEARCH',
      'WRITE_SETTINGS',
      'WRITE_NOTIFICATION_ALERT',
      'CONTROL_POWER',
      'READ_CURRENT_CHANNEL',
      'READ_RUNNING_APPS',
      'READ_UPDATE_INFO',
      'UPDATE_FROM_REMOTE_APP',
      'READ_LGE_TV_INPUT_EVENTS',
      'READ_TV_CURRENT_TIME',
    ],
    'serial': '2f930e2d2cfe083771f68e4fe7bb07',
  };

  static const _signature =
      'eyJhbGdvcml0aG0iOiJSU0EtU0hBMjU2Iiwia2V5SWQiOiJ0ZXN0LXNpZ25pbm'
      'ctY2VydCIsInNpZ25hdHVyZVZlcnNpb24iOjF9.hrVRgjCwXVvE2OOSpDZ58hR'
      '+59aFNwYDyjQgKk3auukd7pcegmE2CzPCa0bJ0ZsRAcKkCTJrWo5iDzNhMBWRy'
      'aMOv5zWSrthlf7G128qvIlpMT0YNY+n/FaOHE73uLrS/g7swl3/qH/BGFG2Hu4'
      'RlL48eb3lLKqTt2xKHdCs6Cd4RMfJPYnzgvI4BNrFUKsjkcu+WD4OO2A27Pq1n'
      '50cMchmcaXadJhGrOqH5YmHdOCj5NSHzJYrsW0HPlpuAx/ECMeIZYDh6RMqaFM'
      '2DXzdKX9NmmyqzJ3o/0lkk/N97gfVRLW5hA29yeAwaCViZNCP8iC9aO0q9fQoj'
      'oa7NQnAtw==';
}
