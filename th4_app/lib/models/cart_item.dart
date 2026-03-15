import 'cart_item_dto.dart';
import 'product.dart';

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.isSelected = true,
    this.size = 'M',
    this.color = 'Default',
  });

  final Product product;
  int quantity;
  bool isSelected;
  String size;
  String color;

  CartItemDTO toDTO() {
    return CartItemDTO(
      productId: product.id,
      product: product,
      quantity: quantity,
      size: size,
      color: color,
      unitPrice: product.price,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      isSelected: json['isSelected'] as bool? ?? true,
      size: json['size'] as String? ?? 'M',
      color: json['color'] as String? ?? 'Default',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'isSelected': isSelected,
      'size': size,
      'color': color,
    };
  }
}
