class CartItemDTO {
  CartItemDTO({
    required this.productId,
    required this.quantity,
    required this.size,
    required this.color,
    required this.price,
  });

  final int productId;
  final int quantity;
  final String size;
  final String color;
  final double price;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'size': size,
      'color': color,
      'price': price,
    };
  }
}