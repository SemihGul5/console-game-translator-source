Map<String, dynamic> purchasesCustomerInfo({
  String userId = 'test-user',
  bool premium = false,
  bool sandbox = false,
  String verification = 'VERIFIED',
}) {
  final entitlement = <String, dynamic>{
    'identifier': 'console_game_translator_premium',
    'isActive': true,
    'willRenew': false,
    'latestPurchaseDate': '2026-11-07T12:00:00Z',
    'originalPurchaseDate': '2026-11-07T12:00:00Z',
    'productIdentifier': 'rc_promo_lifetime',
    'isSandbox': sandbox,
    'periodType': 'PROMOTIONAL',
    'store': 'PROMOTIONAL',
    'verification': verification,
  };
  final active = <String, dynamic>{
    if (premium) 'console_game_translator_premium': entitlement,
  };
  return <String, dynamic>{
    'entitlements': {
      'all': active,
      'active': active,
      'verification': verification,
    },
    'allPurchaseDates': <String, String>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers': <String>[],
    'nonSubscriptionTransactions': <Object>[],
    'firstSeen': '2026-11-07T12:00:00Z',
    'originalAppUserId': userId,
    'allExpirationDates': <String, String>{},
    'requestDate': '2026-11-07T12:00:00Z',
  };
}
