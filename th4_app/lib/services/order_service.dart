import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../models/order_request.dart';
import '../utils/app_constants.dart';

class OrderService {
  const OrderService();

  static int _orderCounter = 0;

  Future<String> placeOrder({
    required OrderRequest orderRequest,
  }) async {
    if (orderRequest.items.isEmpty) {
      throw StateError('OrderRequest items cannot be empty');
    }

    final String nowIso = DateTime.now().toIso8601String();
    _orderCounter += 1;
    final String orderId =
      'local_${DateTime.now().microsecondsSinceEpoch}_$_orderCounter';

    final Order newOrder = Order.fromRequest(
      id: orderId,
      createdAt: nowIso,
      status: AppConstants.orderStatusPending,
      request: orderRequest,
    );

    final List<Order> currentOrders = await loadOrderModels();
    currentOrders.insert(0, newOrder);
    await _saveOrderModels(currentOrders);

    return orderId;
  }

  Future<List<Map<String, dynamic>>> loadOrders() async {
    final List<Order> orders = await loadOrderModels();
    return orders.map((Order order) => order.toJson()).toList();
  }

  Future<List<Order>> loadOrderModels() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(AppConstants.orderStorageKey);

    if (raw == null || raw.isEmpty) {
      return <Order>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (dynamic e) => Order.fromJson(
              (e as Map<dynamic, dynamic>).map(
                (dynamic key, dynamic value) =>
                    MapEntry(key as String, value),
              ),
            ),
          )
          .toList();
    } catch (_) {
      return <Order>[];
    }
  }

  Future<List<Order>> loadOrdersByStatus(String status) async {
    final String normalizedStatus = _normalizeStatus(status);
    final List<Order> orders = await loadOrderModels();
    return orders
        .where(
          (Order order) => _normalizeStatus(order.status) == normalizedStatus,
        )
        .toList();
  }

  Future<Order?> getOrderById(String orderId) async {
    final List<Order> orders = await loadOrderModels();
    for (final Order order in orders) {
      if (order.id == orderId) {
        return order;
      }
    }
    return null;
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    final String normalizedStatus = _normalizeStatus(newStatus);
    if (!AppConstants.supportedOrderStatuses.contains(normalizedStatus)) {
      throw StateError('Unsupported order status: $newStatus');
    }

    final List<Order> orders = await loadOrderModels();
    final int index = orders.indexWhere((Order order) => order.id == orderId);
    if (index == -1) {
      return;
    }

    orders[index] = orders[index].copyWith(status: normalizedStatus);
    await _saveOrderModels(orders);
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, AppConstants.orderStatusCancelled);
  }

  Future<void> clearOrders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.orderStorageKey);
  }

  Future<void> _saveOrderModels(List<Order> orders) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.orderStorageKey,
      jsonEncode(orders.map((Order order) => order.toJson()).toList()),
    );
  }

  String _normalizeStatus(String status) {
    return status.trim().toLowerCase();
  }
}
