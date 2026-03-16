import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../models/product_variation.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  bool _expanded = false;

  final List<String> _sizes = <String>['S', 'M', 'L'];
  final List<String> _colors = <String>['Xanh', 'Đỏ', 'Đen'];

  ProductVariationSelection _selection = ProductVariationSelection();

  void _openVariationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: _VariationSheet(
            selection: _selection,
            sizes: _sizes,
            colors: _colors,
            onConfirm: (ProductVariationSelection sel) {
              setState(() => _selection = sel);
              Navigator.of(ctx).pop();
              final CartProvider cart =
                  Provider.of<CartProvider>(context, listen: false);
              for (int i = 0; i < sel.quantity; i++) {
                cart.addItem(widget.product,
                    size: sel.size, color: sel.color);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thêm thành công')),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat priceFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final double originalPrice = (widget.product.price * 1.2).roundToDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 320,
              child: Stack(
                children: <Widget>[
                  PageView.builder(
                    controller: _pageController,
                    itemCount: 3,
                    itemBuilder: (BuildContext ctx, int index) {
                      // Use same image 3 times to simulate multiple angles
                      return Hero(
                        tag: 'product-${widget.product.id}',
                        child: Image.network(
                          widget.product.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(
                          3,
                          (int i) => AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              final double page = _pageController.hasClients
                                  ? (_pageController.page ?? 0)
                                  : 0;
                              final double diff = (i - page).abs();
                              final double size = (8 - (diff * 4)).clamp(4, 8);
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.product.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Text(
                            priceFormat.format(widget.product.price),
                            style: const TextStyle(
                                color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            priceFormat.format(originalPrice),
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _openVariationSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text('Phân loại', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Kích cỡ: ${_selection.size}, Màu: ${_selection.color}'),
                                ],
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      LayoutBuilder(builder: (context, constraints) {
                        // description display (animated collapse handled below)
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            AnimatedCrossFade(
                              firstChild: Text(
                                widget.product.description,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              secondChild: Text(widget.product.description),
                              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _expanded = !_expanded),
                              child: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: SizedBox(
        height: 66,
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: _openVariationSheet,
                        child: const Text('Thêm vào giỏ hàng'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('Mua ngay'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariationSheet extends StatefulWidget {
  const _VariationSheet({
    required this.selection,
    required this.sizes,
    required this.colors,
    required this.onConfirm,
  });

  final ProductVariationSelection selection;
  final List<String> sizes;
  final List<String> colors;
  final void Function(ProductVariationSelection) onConfirm;

  @override
  State<_VariationSheet> createState() => _VariationSheetState();
}

class _VariationSheetState extends State<_VariationSheet> {
  late String _size;
  late String _color;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _size = widget.selection.size;
    _color = widget.selection.color;
    _quantity = widget.selection.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Center(child: SizedBox(height: 6, width: 48, child: Divider())),
          const SizedBox(height: 8),
          const Text('Chọn Kích cỡ', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: widget.sizes.map((String s) {
              final bool sel = s == _size;
              return ChoiceChip(
                label: Text(s),
                selected: sel,
                onSelected: (_) => setState(() => _size = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Chọn Màu sắc', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: widget.colors.map((String c) {
              final bool sel = c == _color;
              return ChoiceChip(
                label: Text(c),
                selected: sel,
                onSelected: (_) => setState(() => _color = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => setState(() => _quantity = (_quantity > 1 ? _quantity - 1 : 1)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_quantity', style: const TextStyle(fontSize: 16)),
              IconButton(
                onPressed: () => setState(() => _quantity += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => widget.onConfirm(ProductVariationSelection(size: _size, color: _color, quantity: _quantity)),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
