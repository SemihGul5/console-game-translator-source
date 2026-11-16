import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/subtitle_settings_store.dart';
import 'ps5_stream_screen.dart';

class SubtitleProfilesScreen extends StatefulWidget {
  const SubtitleProfilesScreen({super.key});

  @override
  State<SubtitleProfilesScreen> createState() => _SubtitleProfilesScreenState();
}

class _SubtitleProfilesScreenState extends State<SubtitleProfilesScreen> {
  final _store = const SubtitleSettingsStore();
  List<SubtitleProfile> _profiles = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await _store.loadProfiles();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
  }

  Future<void> _setDefault(SubtitleProfile selected) async {
    final profiles = _profiles
        .map(
          (profile) => SubtitleProfile(
            name: profile.name,
            settings: profile.settings,
            snapshotId: profile.snapshotId,
            isDefault: profile.name == selected.name,
          ),
        )
        .toList();
    await _store.saveProfiles(profiles);
    await _store.save(selected.settings);
    if (!mounted) return;
    setState(() => _profiles = profiles);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr("{0} varsayılan profil seçildi.", [selected.name]),
        ),
      ),
    );
  }

  Future<void> _createProfile() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NewProfileDialog(),
    );
    if (!mounted || name == null || name.trim().isEmpty) return;
    final trimmed = name.trim();
    if (_profiles.any((profile) => profile.name == trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr("Bu isimde bir oyun profili zaten var.")),
        ),
      );
      return;
    }
    final base = _profiles.where((profile) => profile.isDefault).firstOrNull;
    final settings = base?.settings ?? await _store.load();
    final profile = SubtitleProfile(
      name: trimmed,
      settings: settings,
      isDefault: _profiles.isEmpty,
    );
    final profiles = [..._profiles, profile];
    await _store.saveProfiles(profiles);
    if (!mounted) return;
    setState(() => _profiles = profiles);
    await _openProfile(profile);
  }

  Future<void> _openProfile(SubtitleProfile profile) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Ps5StreamScreen(
          openSubtitleSettingsOnStart: true,
          initialProfileName: profile.name,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr("Altyazı ayarları"))),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _createProfile,
      icon: const Icon(Icons.add),
      label: Text(context.tr("Oyun profili ekle")),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _profiles.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.subtitles_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(
                      "Henüz oyun profili yok. Her oyun için OCR alanlarını ve altyazı görünümünü ayrı kaydedebilirsin.",
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _createProfile,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr("İlk profili oluştur")),
                  ),
                ],
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  context.tr(
                    "Bir oyun profilini açıp OCR ve altyazı konumunu ayrı ayrı düzenle. Yıldızlı profil uygulama açılışında varsayılan olarak kullanılır.",
                  ),
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
              for (final profile in _profiles)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sports_esports),
                    title: Text(profile.name),
                    subtitle: Text(
                      context.tr("{0} → {1} · {2} OCR alanı", [
                        _languageName(profile.settings.sourceLanguageCode),
                        _languageName(profile.settings.targetLanguageCode),
                        profile.settings.effectiveOcrRegions.length,
                      ]),
                    ),
                    onTap: () => _openProfile(profile),
                    trailing: IconButton(
                      tooltip: profile.isDefault
                          ? context.tr("Varsayılan profil")
                          : context.tr("Uygulama açılışında varsayılan yap"),
                      onPressed: profile.isDefault
                          ? null
                          : () => _setDefault(profile),
                      icon: Icon(
                        profile.isDefault ? Icons.star : Icons.star_border,
                        color: profile.isDefault
                            ? Colors.amber
                            : Colors.white70,
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );

  String _languageName(String code) => switch (code) {
    'en' => 'English',
    'tr' => context.tr("Türkçe"),
    _ => code,
  };
}

class _NewProfileDialog extends StatefulWidget {
  const _NewProfileDialog();

  @override
  State<_NewProfileDialog> createState() => _NewProfileDialogState();
}

class _NewProfileDialogState extends State<_NewProfileDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr("Oyun profili oluştur")),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 48,
      decoration: InputDecoration(labelText: context.tr("Oyun adı")),
      onSubmitted: (value) => Navigator.pop(context, value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr("İptal")),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: Text(context.tr("Oluştur")),
      ),
    ],
  );
}
