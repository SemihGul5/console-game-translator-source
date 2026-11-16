import '../models/game_catalog_entry.dart';

String _searchName(String text) {
  var value = text.toLowerCase().replaceAll('ı', 'i').replaceAll('İ', 'i');
  for (final letter in const {
    'ç': 'c',
    'ğ': 'g',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
  }.entries) {
    value = value.replaceAll(letter.key, letter.value);
  }
  return value
      .replaceAll('\u0307', '')
      .replaceAll(RegExp("['’]"), '')
      .replaceAll(RegExp(r'[\s_-]+'), ' ')
      .trim();
}

String _sortName(String name) {
  var value = name
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('\u0307', '');
  // Place Turkish letters immediately after their Latin counterparts.
  for (final letter in const {
    'ç': 'c~',
    'ğ': 'g~',
    'ö': 'o~',
    'ş': 's~',
    'ü': 'u~',
  }.entries) {
    value = value.replaceAll(letter.key, letter.value);
  }
  return value;
}

List<GameCatalogEntry> gameLibraryResults(
  Iterable<GameCatalogEntry> games,
  String query, {
  String? selectedGameId,
  String? targetLanguage,
  Set<String> downloadedContentKeys = const {},
}) {
  final terms = _searchName(
    query,
  ).split(' ').where((term) => term.isNotEmpty).toList();
  final results = games.where((game) {
    if (targetLanguage != null && game.targetLanguage != targetLanguage)
      return false;
    final name = _searchName('${game.name} ${game.id}');
    return terms.every(name.contains);
  }).toList();
  final sortNames = {for (final game in results) game.id: _sortName(game.name)};
  return results..sort((a, b) {
    if (a.id == selectedGameId && b.id != selectedGameId) return -1;
    if (b.id == selectedGameId && a.id != selectedGameId) return 1;
    final aDownloaded = downloadedContentKeys.contains(a.contentKey);
    final bDownloaded = downloadedContentKeys.contains(b.contentKey);
    if (aDownloaded != bDownloaded) return aDownloaded ? -1 : 1;
    final order = sortNames[a.id]!.compareTo(sortNames[b.id]!);
    return order == 0 ? a.id.compareTo(b.id) : order;
  });
}
