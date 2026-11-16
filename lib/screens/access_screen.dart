import '../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/access_service.dart';
import '../services/access_action_guard.dart';
import '../widgets/premium_plan_card.dart';
import '../widgets/free_trial_offer_card.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, this.forTranslation = false});
  final bool forTranslation;
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _service = AccessService.instance;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _service.addListener(_updated);
    _run(_refresh);
  }

  void _updated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_updated);
    super.dispose();
  }

  Future<void> _refresh() async {
    await _service.refresh(force: true);
    if (!_service.status.premium) await _service.loadPackages();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _service.actions.busy || !mounted) return;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      await action();
    } catch (error) {
      final message = AccessService.errorMessage(error);
      if (mounted && message.isNotEmpty) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() => _run(() async {
    if ((await _service.refresh(force: true)).canStart && mounted) {
      Navigator.pop(context, true);
    }
  });
  Future<void> _tryTrial() => _run(() async {
    if (_service.user == null) await _service.signIn();
    if (widget.forTranslation) {
      final status = await _service.prepareTranslation();
      if (status.canPrepareTranslation && mounted) Navigator.pop(context, true);
    } else {
      await _service.refresh(force: true);
      if (!_service.status.premium) await _service.loadPackages();
    }
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

  Future<void> _open(Uri uri) async {
    if (uri.scheme != 'https' ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError("Sayfa açılamadı. Biraz sonra tekrar dene.");
    }
  }

  Future<void> _manage() =>
      _open(Uri.https('play.google.com', '/store/account/subscriptions'));
  String? _description(AccessStatus status) {
    final end = status.expiresAt?.toLocal();
    final date = end == null
        ? ''
        : '${end.day}.${end.month}.${end.year} '
              '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return switch (status.state) {
      'trial' when status.source == 'free_trial' => context.tr(
        "Kalan deneme: {0}. Süre Remote Play bağlantısı başladığında kesintisiz işler. Uygulamayı kapatsan da süre devam eder. Otomatik ücret alınmaz.",
        [status.remainingLabel],
      ),
      'available' => context.tr(
        "Google girişin tamamlandı. Ücretsiz denemen, Çeviriyi başlat düğmesine basıp Remote Play bağlantısı kurulduğunda başlayacak.",
      ),
      'expired' => context.tr(
        "Ücretsiz denemen sona erdi. Çeviriye devam etmek için bir paket seçebilirsin.",
      ),
      'trial' =>
        status.willRenew
            ? context.tr(
                "Google Play denemen {0} tarihine kadar aktif. Ücret alınmasını istemiyorsan deneme bitmeden Google Play’den iptal et.",
                [date],
              )
            : context.tr(
                "Deneme aboneliğinin yenilenmesi iptal edildi. {0} tarihine kadar çeviriyi kullanabilirsin.",
                [date],
              ),
      'premium' =>
        status.willRenew
            ? context.tr(
                "Premium aktif. Aboneliğini Google Play’den yönetebilirsin.",
              )
            : context.tr(
                "Yenileme iptal edildi. {0} tarihine kadar Premium erişimin sürer.",
                [date],
              ),
      'lifetime' => context.tr("Süresiz Premium erişimin aktif."),
      'verification_required' => context.tr(
        "Satın alma durumu doğrulanamadı. İnternete bağlanıp durumu yenile.",
      ),
      _ => null,
    };
  }

  Widget _package(Package package) => PremiumPlanCard(
    package: package,
    availablePackages: _service.packages,
    onPurchase: _busy || _service.actions.busy
        ? null
        : () => _run(() => _service.purchase(package)),
  );

  @override
  Widget build(BuildContext context) {
    final status = _service.status;
    final description = _description(status);
    final busy = _busy || _service.actions.busy;
    final showTrialOffer =
        widget.forTranslation &&
        _service.configured &&
        !status.premium &&
        !status.canStart &&
        status.state != 'expired' &&
        status.state != 'verification_required';
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Premium'))),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              _run(() => _service.refreshManually(loadProducts: true)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              if (showTrialOffer)
                FreeTrialOfferCard(
                  minutes: status.freeTrialMinutes,
                  onStart: busy || status.freeTrialMinutes == null
                      ? null
                      : _tryTrial,
                )
              else ...[
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 54,
                  color: Color(0xFF4DE2D0),
                ),
                const SizedBox(height: 16),
                Text(
                  status.premium
                      ? context.tr("Premium aktif")
                      : context.tr("Oyununu kendi dilinde yaşa"),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
              if (showTrialOffer &&
                  !busy &&
                  status.freeTrialMinutes == null) ...[
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Deneme süresi alınamadı. İnternet bağlantını kontrol edip aşağı çekerek yenile.',
                  ),
                ),
              ],
              if (description != null && !showTrialOffer) ...[
                const SizedBox(height: 16),
                Text(description, style: const TextStyle(height: 1.5)),
              ],
              if (status.source == 'free_trial' && status.state == 'trial') ...[
                const SizedBox(height: 12),
                Text(
                  status.remainingLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.tr("Erişim durumunu yenilemek için aşağı çek."),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
              if (busy) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  context.trMessage(_error!),
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ],
              const SizedBox(height: 20),
              if (widget.forTranslation && status.canStart)
                FilledButton(
                  onPressed: busy ? null : _continue,
                  child: Text(context.tr("Çeviriye devam et")),
                ),
              if (_service.configured &&
                  !status.premium &&
                  !widget.forTranslation &&
                  _service.user == null)
                FilledButton(
                  onPressed: busy ? null : _tryTrial,
                  child: Text(context.tr("Deneme için Google ile giriş yap")),
                ),
              if (_service.configured && !status.premium) ...[
                if (showTrialOffer && _service.packages.isNotEmpty) ...[
                  Text(
                    context.tr('Premium paketleri'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_service.packages.isNotEmpty &&
                    _service.launchPricingActive) ...[
                  Container(
                    key: const ValueKey('launch-pricing-banner'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DE2D0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF4DE2D0).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Lansmana özel fiyatlar'),
                          style: const TextStyle(
                            color: Color(0xFF4DE2D0),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(
                            'İlk çıkışa özel, sınırlı süreli fiyatlar.',
                          ),
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ..._service.packages.map(_package),
                if (_service.packages.isEmpty && !busy && _error == null)
                  Text(
                    context.tr(
                      "Satın alınabilir paket bulunamadı. Biraz sonra tekrar dene.",
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    "Deneme uygunluğu ve son ödeme koşulları Google Play ekranında gösterilir.",
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
              const SizedBox(height: 12),
              if (_service.configured) ...[
                TextButton(
                  onPressed:
                      busy || !_service.actions.canRun(AccessAction.restore)
                      ? null
                      : () => _run(_service.restore),
                  child: Text(
                    _service.actions.remaining(AccessAction.restore) >
                            Duration.zero
                        ? context.tr("Geri yükleme için biraz bekle")
                        : context.tr("Satın alımları geri yükle"),
                  ),
                ),
                if (_service.user != null) ...[
                  Text(_service.user!.email ?? context.tr("Google hesabı")),
                  TextButton(
                    onPressed: busy ? null : () => _run(_service.signOut),
                    child: Text(context.tr("Çıkış yap")),
                  ),
                  TextButton(
                    onPressed: busy ? null : _deleteAccount,
                    child: Text(context.tr("Hesabımı sil")),
                  ),
                ],
                if (status.state != 'lifetime')
                  TextButton(
                    onPressed: busy ? null : () => _run(_manage),
                    child: Text(
                      context.tr("Google Play aboneliğini yönet / iptal et"),
                    ),
                  ),
              ],
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  if (_service.privacyUrl.isNotEmpty)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => _run(
                              () => _open(Uri.parse(_service.privacyUrl)),
                            ),
                      child: Text(context.tr("Gizlilik politikası")),
                    ),
                  if (_service.termsUrl.isNotEmpty)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () =>
                                _run(() => _open(Uri.parse(_service.termsUrl))),
                      child: Text(context.tr("Kullanım şartları")),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
