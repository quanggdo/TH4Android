import 'product.dart';

class CartItemDTO {
  CartItemDTO({
    required this.productId,
    required this.product,
    required this.quantity,
    required this.size,
    required this.color,
    required this.unitPrice,
  });

  final int productId;
  final Product product;
  final int quantity;
  final String size;
  final String color;
  final double unitPrice;

  factory CartItemDTO.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? productJson =
        json['product'] as Map<String, dynamic>?;

    return CartItemDTO(
      productId: json['productId'] as int? ?? 0,
      product: Product.fromJson(productJson ?? <String, dynamic>{}),
      quantity: json['quantity'] as int? ?? 1,
      size: json['size'] as String? ?? 'M',
      color: json['color'] as String? ?? 'Default',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'product': product.toJson(),
      'quantity': quantity,
      'size': size,
      'color': color,
      'unitPrice': unitPrice,
    };
  }
}