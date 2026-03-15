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
