import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<void> _onCheckoutPressed() async {
    final CartProvider cart = Provider.of<CartProvider>(context, listen: false);
    await cart.checkoutSelected();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thành công (giả bố)')));
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat priceFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<CartItem> items = cart.items.toList();

          if (items.isEmpty) {
            return const Center(child: Text('Giỏ hàng trống'));
          }

          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: items.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    final CartItem item = items[index];
                    final String keyId = '${item.product.id}-${item.size}-${item.color}';
                    return Dismissible(
                      key: ValueKey(keyId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        Provider.of<CartProvider>(context, listen: false).removeAt(index);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sản phẩm')));
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: <Widget>[
                              Checkbox(
                                value: item.isSelected,
                                onChanged: (bool? v) {
                                  Provider.of<CartProvider>(context, listen: false).toggleSelect(index, v ?? false);
                                },
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.product.image,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Container(
                                    width: 64,
                                    height: 64,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(item.product.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Text('Kích cỡ: ${item.size}, Màu: ${item.color}', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text(priceFormat.format(item.product.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      Provider.of<CartProvider>(context, listen: false).incrementQuantity(index);
                                    },
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () async {
                                      final CartProvider cp = Provider.of<CartProvider>(context, listen: false);
                                      if (cp.shouldConfirmRemoveOnDecrement(index)) {
                                        // confirm
                                        final bool? res = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext ctx) => AlertDialog(
                                            title: const Text('Xác nhận'),
                                            content: const Text('Giảm số lượng sẽ xóa sản phẩm. Bạn có muốn tiếp tục?'),
                                            actions: <Widget>[
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa')),
                                            ],
                                          ),
                                        );

                                        if (res == true) {
                                          cp.decrementOrRemove(index, confirmedRemove: true);
                                          return;
                                        }

                                        return;
                                      }

                                      cp.decrementOrRemove(index, confirmedRemove: false);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom sticky bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                child: Row(
                  children: <Widget>[
                    Checkbox(
                      value: cart.isAllSelected,
                      tristate: false,
                      onChanged: (bool? v) {
                        Provider.of<CartProvider>(context, listen: false).toggleAll(v ?? false);
                      },
                    ),
                    const Text('Chọn tất cả'),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text('Tổng: ${priceFormat.format(cart.totalAmount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${cart.totalSelectedQuantity} sản phẩm được chọn', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: cart.totalAmount <= 0 ? null : _onCheckoutPressed,
                      child: const Text('Mua hàng'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

