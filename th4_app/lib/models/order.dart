import 'order_request.dart';

class Order {
  Order({
    required this.id,
    required this.items,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  final String shippingAddress;
  final double totalAmount;
  final String status;
  final String createdAt;
  final String? note;

  factory Order.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = (json['items'] as List<dynamic>?) ??
        <dynamic>[];
    return Order(
      id: json['id'] as String,
      items: rawItems
          .map((dynamic e) => (e as Map<dynamic, dynamic>)
              .map((dynamic key, dynamic value) =>
                  MapEntry(key as String, value)))
          .toList(),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  factory Order.fromRequest({
    required String id,
    required String createdAt,
    required String status,
    required OrderRequest request,
  }) {
    return Order(
      id: id,
      items: request.items.map((e) => e.toJson()).toList(),
      paymentMethod: request.paymentMethod,
      shippingAddress: request.shippingAddress,
      totalAmount: request.totalAmount,
      status: status,
      createdAt: createdAt,
      note: request.note,
    );
  }

  Order copyWith({
    String? status,
  }) {
    return Order(
      id: id,
      items: items,
      paymentMethod: paymentMethod,
      shippingAddress: shippingAddress,
      totalAmount: totalAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      note: note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items,
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'note': note,
    };
  }
}
