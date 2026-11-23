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
  String? _selectedId;
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

  /// The plan the purchase button buys: the user's choice, otherwise the
  /// recommended one (lifetime, then annual, then monthly, then the first).
  Package? get _selectedPackage {
    final packages = _service.packages;
    if (packages.isEmpty) return null;
    for (final package in packages) {
      if (package.identifier == _selectedId) return package;
    }
    for (final pick in <bool Function(Package)>[
      PremiumPlanCard.isHighlighted,
      (p) => p.packageType == PackageType.annual,
      (p) => p.packageType == PackageType.monthly,
    ]) {
      for (final package in packages) {
        if (pick(package)) return package;
      }
    }
    return packages.first;
  }

  Widget _package(Package package, Package? selected) => PremiumPlanCard(
    package: package,
    availablePackages: _service.packages,
    selected: identical(package, selected),
    onSelect: () => setState(() => _selectedId = package.identifier),
  );

  @override
  Widget build(BuildContext context) {
    final status = _service.status;
    final description = _description(status);
    final busy = _busy || _service.actions.busy;
    final selected = _selectedPackage;
    final showTrialOffer =
        widget.forTranslation &&
        _service.configured &&
        !status.premium &&
        !status.canStart &&
        status.state != 'expired' &&
        status.state != 'verification_required';
    const muted = Color(0xFF929DB4);
    const small = TextStyle(fontSize: 12, color: Colors.white60, height: 1.4);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Premium'))),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              _run(() => _service.refreshManually(loadProducts: true)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (showTrialOffer)
                FreeTrialOfferCard(
                  minutes: status.freeTrialMinutes,
                  onStart: busy || status.freeTrialMinutes == null
                      ? null
                      : _tryTrial,
                )
              else
                _PremiumHero(premium: status.premium),
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
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5, color: muted),
                ),
              ],
              if (status.source == 'free_trial' && status.state == 'trial') ...[
                const SizedBox(height: 12),
                Text(
                  status.remainingLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
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
              const SizedBox(height: 16),
              if (widget.forTranslation && status.canStart)
                FilledButton(
                  onPressed: busy ? null : _continue,
                  child: Text(context.tr("Çeviriye devam et")),
                ),
              if (_service.configured &&
                  !status.premium &&
                  !widget.forTranslation &&
                  _service.user == null) ...[
                _TrialSignInCard(
                  minutes: status.freeTrialMinutes,
                  onPressed: busy ? null : _tryTrial,
                ),
                const SizedBox(height: 20),
              ],
              if (_service.configured && !status.premium) ...[
                if (_service.packages.isNotEmpty)
                  Text(
                    context.tr('Planını seç'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                if (_service.packages.isNotEmpty) const SizedBox(height: 12),
                for (final package in _service.packages)
                  _package(package, selected),
                if (_service.packages.isEmpty && !busy && _error == null)
                  Text(
                    context.tr(
                      "Satın alınabilir paket bulunamadı. Biraz sonra tekrar dene.",
                    ),
                  ),
                if (selected != null) ...[
                  const SizedBox(height: 8),
                  _PurchaseButton(
                    label: PremiumPlanCard.actionLabel(context, selected),
                    onPressed: busy
                        ? null
                        : () => _run(() => _service.purchase(selected)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    PremiumPlanCard.termsFor(context, selected),
                    textAlign: TextAlign.center,
                    style: small,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _TrustItem(
                        icon: Icons.lock_outline_rounded,
                        text: context.tr('Google Play ile güvenli ödeme'),
                      ),
                      if (selected.packageType != PackageType.lifetime)
                        _TrustItem(
                          icon: Icons.event_repeat_rounded,
                          text: context.tr('İstediğin zaman iptal'),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    "Deneme uygunluğu ve son ödeme koşulları Google Play ekranında gösterilir.",
                  ),
                  textAlign: TextAlign.center,
                  style: small,
                ),
              ],
              const SizedBox(height: 8),
              const Divider(height: 32, color: Colors.white12),
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
                  Text(
                    _service.user!.email ?? context.tr("Google hesabı"),
                    textAlign: TextAlign.center,
                    style: small,
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: busy ? null : () => _run(_service.signOut),
                        child: Text(context.tr("Çıkış yap")),
                      ),
                      TextButton(
                        onPressed: busy ? null : _deleteAccount,
                        child: Text(context.tr("Hesabımı sil")),
                      ),
                    ],
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
              const SizedBox(height: 4),
              Text(
                context.tr("Erişim durumunu yenilemek için aşağı çek."),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.premium});
  final bool premium;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B2747), Color(0xFF121A2C), Color(0xFF0D2A31)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          premium
              ? context.tr("Premium aktif")
              : context.tr("Oyununu kendi dilinde yaşa"),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.white,
          ),
        ),
        if (!premium) ...[
          const SizedBox(height: 12),
          _Feature(
            icon: Icons.translate_rounded,
            text: context.tr(
              'Diyaloglar, görevler ve menüler oynarken çevrilir',
            ),
          ),
          _Feature(
            icon: Icons.subtitles_rounded,
            text: context.tr('Altyazılar TV’de oyunun üstünde görünür'),
          ),
          _Feature(
            icon: Icons.auto_stories_rounded,
            text: context.tr(
              'Desteklenen oyunlarda hazır, özenli çeviriler',
            ),
            last: true,
          ),
        ],
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text, this.last = false});
  final IconData icon;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4DE2D0)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: Color(0xFFD5DEEA),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TrialSignInCard extends StatelessWidget {
  const _TrialSignInCard({required this.minutes, required this.onPressed});
  final int? minutes;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF4DE2D0);
    return Container(
      key: const ValueKey('trial-sign-in-card'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cyan.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cyan.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 17,
                  color: cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      minutes == null
                          ? context.tr('Önce ücretsiz dene')
                          : context.tr('{0} dakika ücretsiz dene', [minutes]),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        'Ödeme bilgisi gerekmez. Otomatik abonelik başlamaz.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Color(0xFFA8B7C5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: cyan.withValues(alpha: 0.14),
              foregroundColor: cyan,
              minimumSize: const Size.fromHeight(40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: cyan.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text(
              context.tr("Deneme için Google ile giriş yap"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onPressed == null ? 0.5 : 1,
        child: DecoratedBox(
          key: const ValueKey('premium-purchase-button'),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              colors: [Color(0xFF0070D1), Color(0xFF00A6C8)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A6C8).withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xFF4DE2D0)),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFFA8B7C5)),
        ),
      ),
    ],
  );
}
