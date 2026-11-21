class GameCatalogEntry {
  const GameCatalogEntry({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.file,
    this.baseGameId,
    this.targetLanguageName = '',
    this.targetLanguageEnglishName = '',
    this.targetLanguageNativeName = '',
    this.cover = '',
    this.sha256 = '',
    this.bytes = 0,
    this.coverSha256 = '',
    this.coverAspectRatio = 3 / 4,
  });

  final String id;
  final String? baseGameId;
  String get gameId => baseGameId ?? id;
  final String targetLanguageName;
  final String targetLanguageEnglishName;
  final String targetLanguageNativeName;

  /// Language choices keep their own names regardless of the app's UI language.
  String get languageLabel => targetLanguageNativeName.trim().isNotEmpty
      ? targetLanguageNativeName.trim()
      : targetLanguage == 'tr'
      ? 'Türkçe'
      : targetLanguage.toUpperCase();

  final String name;
  final String sourceLanguage;
  final String targetLanguage;
  final String file;
  final String cover;
  final String sha256;
  final int bytes;
  final String coverSha256;
  final double coverAspectRatio;

  String get contentKey => '$id:${sha256.isEmpty ? file : sha256}';
  String get coverKey => coverSha256.isEmpty ? cover : coverSha256;
  bool get isRemote => Uri.tryParse(file)?.hasScheme == true;

  /// Packs above Cloudflare's 25 MiB asset limit are published as `.json.gz`.
  /// [sha256] and [bytes] then describe the compressed download.
  bool get isCompressedPack =>
      (Uri.tryParse(file)?.path ?? file).endsWith('.json.gz');

  factory GameCatalogEntry.fromJson(Map<String, dynamic> value) {
    final aspectRatio = value['coverAspectRatio'];
    if (aspectRatio != null && aspectRatio is! num) {
      throw const FormatException('Oyun kataloğu kaydı geçersiz.');
    }
    String requiredString(String key) {
      final result = value[key];
      if (result is! String || result.trim().isEmpty) {
        throw FormatException('Oyun kataloğunda "$key" alanı eksik.');
      }
      return result;
    }

    return GameCatalogEntry(
      id: requiredString('id'),
      baseGameId: value['gameId'] as String?,
      targetLanguageName: value['targetLanguageName'] as String? ?? '',
      targetLanguageEnglishName:
          value['targetLanguageEnglishName'] as String? ?? '',
      targetLanguageNativeName:
          value['targetLanguageNativeName'] as String? ?? '',
      name: requiredString('name'),
      sourceLanguage: requiredString('sourceLanguage'),
      targetLanguage: requiredString('targetLanguage'),
      file: requiredString('file'),
      cover: value['cover'] as String? ?? '',
      sha256: value['sha256'] as String? ?? '',
      bytes: (value['bytes'] as num?)?.toInt() ?? 0,
      coverSha256: value['coverSha256'] as String? ?? '',
      coverAspectRatio: (aspectRatio as num?)?.toDouble() ?? 3 / 4,
    );
  }
}
