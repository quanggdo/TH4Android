import 'cart_item_dto.dart';

class OrderRequest {
  OrderRequest({
    required this.items,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.totalAmount,
    this.note,
  });

  final List<CartItemDTO> items;
  final String paymentMethod;
  final String shippingAddress;
  final double totalAmount;
  final String? note;

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = (json['items'] as List<dynamic>?) ??
        <dynamic>[];

    return OrderRequest(
      items: rawItems
          .map(
            (dynamic e) => CartItemDTO.fromJson(
              (e as Map<dynamic, dynamic>).map(
                (dynamic key, dynamic value) =>
                    MapEntry(key as String, value),
              ),
            ),
          )
          .toList(),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'paymentMethod': paymentMethod,
      'shippingAddress': shippingAddress,
      'totalAmount': totalAmount,
      'note': note,
    };
  }
}
