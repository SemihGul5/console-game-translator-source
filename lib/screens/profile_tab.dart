import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../services/access_service.dart';
import '../services/access_action_guard.dart';
import '../services/app_links.dart';
import '../widgets/settings_section.dart';
import 'translation_cache_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.onOpenSubscription,
    required this.setupCompleted,
    required this.onOpenSetup,
    required this.onOpenFaq,
  });

  final VoidCallback onOpenSubscription;
  final bool setupCompleted;
  final VoidCallback onOpenSetup;
  final VoidCallback onOpenFaq;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with WidgetsBindingObserver {
  final _service = AccessService.instance;
  bool _busy = false;
  String? _error;
  AppInformation _information = const AppInformation();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.addListener(_updated);
    _loadInformation();
    _run(() async {
      await _service.refresh();
    });
  }

  Future<void> _loadInformation() async {
    final information = await AppInformation.load();
    if (mounted) setState(() => _information = information);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) {
      _run(() async {
        await _service.refresh();
      });
    }
  }

  void _updated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.removeListener(_updated);
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _service.actions.busy || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      final message = AccessService.errorMessage(error);
      if (mounted && message.isNotEmpty) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
    await _service.signIn();
    await _service.refresh(force: true);
  });

  Future<void> _deleteAccount() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr("Hesabını sil")),
        content: Text(
          context.tr(
            "Uygulamadaki hesabın kalıcı olarak silinir ve oturumun kapatılır. Tekrarlanan denemeleri önleyen bitiş kaydı saklanır. Bu işlem Google Play aboneliğini iptal etmez; aboneliğini Google Play’den yönetebilirsin.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr("Vazgeç")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr("Hesabımı sil")),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await _run(() async {
        await _service.deleteAccount();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr("Hesabın silindi ve oturumun kapatıldı.")),
          ),
        );
      });
    }
  }

  String get _subscriptionLabel => switch (_service.status.state) {
    'premium' => context.tr("Premium aktif"),
    'lifetime' => context.tr("Süresiz erişim aktif"),
    'trial' =>
      _service.status.source == 'free_trial'
          ? context.tr("Kalan deneme: {0}", [_service.status.remainingLabel])
          : context.tr("Mağaza denemesi aktif"),
    'expired' => context.tr("Deneme süresi sona erdi"),
    'available' when _service.status.source == 'free_trial' => context.tr(
      'Ücretsiz denemen hazır. Remote Play bağlantısıyla başlar.',
    ),
    'verification_required' => context.tr("Erişim doğrulaması gerekiyor"),
    _ => context.tr("Paketleri ve erişim durumunu görüntüle"),
  };

  @override
  Widget build(BuildContext context) {
    final user = _service.user;
    final busy = _busy || _service.actions.busy;
    return RefreshIndicator(
      onRefresh: () => _run(_service.refreshManually),
      child: ListView(
        key: const PageStorageKey('profile-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          SettingsPageHeader(
            title: context.tr("Profil"),
            description: context.tr(
              "Hesabın, Premium erişimin ve uygulama ayarların. Yenilemek için aşağı çek.",
            ),
          ),
          Container(
            padding: const EdgeInsets.all(22),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF163052), settingsPanel],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2C4260)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFF234365),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ??
                      (user == null
                          ? context.tr("Oyununa kaldığın yerden devam et")
                          : context.tr("Google hesabın")),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ??
                      context.tr(
                        "Deneme ve hesap işlemleri için Google hesabınla giriş yap.",
                      ),
                  style: const TextStyle(
                    color: Color(0xFFB4C5DD),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (user == null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: busy ? null : _signIn,
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(context.tr("Google ile giriş yap")),
                  ),
                ],
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                context.trMessage(_error!),
                style: const TextStyle(color: Colors.orangeAccent, height: 1.5),
              ),
            ),
          SettingsSection(
            title: context.tr("Abonelik"),
            children: [
              SettingsEntry(
                icon: Icons.workspace_premium_outlined,
                title: context.tr("Aboneliğim"),
                subtitle: _subscriptionLabel,
                onTap: widget.onOpenSubscription,
              ),
              SettingsEntry(
                icon: Icons.card_giftcard_rounded,
                title: context.tr("Hediye kodunu kullan"),
                subtitle: context.tr("Google Play hediye veya promosyon kodu"),
                onTap: () =>
                    AppLinks.openWeb(context, 'https://play.google.com/redeem'),
              ),
              SettingsEntry(
                icon: Icons.restore_rounded,
                title: context.tr("Satın alımları geri yükle"),
                subtitle:
                    _service.actions.remaining(AccessAction.restore) >
                        Duration.zero
                    ? context.tr("Tekrar denemeden önce kısa bir süre bekle.")
                    : context.tr(
                        "Önceki satın alımlarını Google Play’den geri getir.",
                      ),
                onTap: busy || !_service.actions.canRun(AccessAction.restore)
                    ? null
                    : () => _run(_service.restore),
              ),
            ],
          ),
          SettingsSection(
            title: context.tr('Gelişmiş'),
            children: [
              SettingsEntry(
                icon: Icons.storage_rounded,
                title: context.tr('Çeviri önbelleği'),
                subtitle: context.tr(
                  'Saklama sınırları, yedekleme ve temizleme',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TranslationCacheScreen(),
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: context.tr("Yardım"),
            children: [
              SettingsEntry(
                icon: Icons.quiz_outlined,
                title: context.tr("Sık Sorulan Sorular"),
                subtitle: context.tr("Bağlantı ve çeviri hakkında yanıtlar"),
                onTap: widget.onOpenFaq,
              ),
              if (widget.setupCompleted)
                SettingsEntry(
                  icon: Icons.checklist_rounded,
                  title: context.tr("Kurulum rehberi"),
                  subtitle: context.tr("Tamamladığın adımları yeniden incele"),
                  onTap: widget.onOpenSetup,
                ),
              SettingsEntry(
                icon: Icons.mail_outline_rounded,
                title: context.tr("Bize e-posta gönder"),
                subtitle: AppLinks.supportEmail,
                onTap: () => AppLinks.contactSupport(context),
              ),
              SettingsEntry(
                icon: Icons.alternate_email_rounded,
                title: 'X (Twitter)',
                subtitle: AppLinks.xHandle,
                onTap: () => AppLinks.openWeb(context, AppLinks.xProfileUrl),
              ),
            ],
          ),
          SettingsSection(
            title: context.tr("Uygulama hakkında"),
            children: [
              SettingsEntry(
                icon: Icons.privacy_tip_outlined,
                title: context.tr("Gizlilik politikası"),
                onTap: () =>
                    AppLinks.openWeb(context, _information.privacyUrl),
              ),
              SettingsEntry(
                icon: Icons.description_outlined,
                title: context.tr("Kullanım şartları"),
                onTap: () => AppLinks.openWeb(context, _information.termsUrl),
              ),
              SettingsEntry(
                icon: Icons.info_outline_rounded,
                title: context.tr("Sürüm"),
                subtitle: context.tr(_information.versionLabel),
              ),
            ],
          ),
          if (user != null)
            SettingsSection(
              title: context.tr("Hesap"),
              children: [
                SettingsEntry(
                  icon: Icons.logout_rounded,
                  title: context.tr("Çıkış yap"),
                  onTap: busy ? null : () => _run(_service.signOut),
                ),
                SettingsEntry(
                  icon: Icons.person_remove_outlined,
                  title: context.tr("Hesabımı sil"),
                  color: const Color(0xFFFF9D9D),
                  onTap: busy ? null : _deleteAccount,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
