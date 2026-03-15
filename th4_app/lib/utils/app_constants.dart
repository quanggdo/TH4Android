class AppConstants {
  static const String baseApiUrl = 'https://fakestoreapi.com';
  static const String cartStorageKey = 'cart_items';
  static const String orderStorageKey = 'local_orders';

  static const String orderStatusPending = 'pending';
  static const String orderStatusShipping = 'shipping';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  static const Set<String> supportedOrderStatuses = <String>{
    orderStatusPending,
    orderStatusShipping,
    orderStatusDelivered,
    orderStatusCancelled,
  };
}