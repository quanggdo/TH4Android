import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cart_item_dto.dart';
import '../models/order_request.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.selectedItems});

  final List<CartItemDTO> selectedItems;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OrderService _orderService = const OrderService();

  String _paymentMethod = 'COD';
  bool _isPlacingOrder = false;

  double get _totalAmount {
    return widget.selectedItems.fold<double>(
      0,
      (double sum, CartItemDTO item) => sum + (item.unitPrice * item.quantity),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isPlacingOrder = true);

    final OrderRequest request = OrderRequest(
      items: widget.selectedItems,
      paymentMethod: _paymentMethod,
      shippingAddress: _addressController.text.trim(),
      totalAmount: _totalAmount,
    );

    try {
      await _orderService.placeOrder(orderRequest: request);
      if (!mounted) {
        return;
      }

      await Provider.of<CartProvider>(context, listen: false).checkoutSelected();
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Đặt hàng thành công'),
            content: const Text('Đơn hàng của bạn đã được ghi nhận.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt hàng thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  const Text(
                    'Sản phẩm đã chọn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...widget.selectedItems.map((CartItemDTO item) {
                    final double lineTotal = item.quantity * item.unitPrice;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          item.product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'SL: ${item.quantity} | Size: ${item.size} | Màu: ${item.color}',
                        ),
                        trailing: Text(
                          priceFormat.format(lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ nhận hàng',
                        border: OutlineInputBorder(),
                        hintText: 'Nhập địa chỉ giao hàng',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập địa chỉ nhận hàng';
                        }
                        if (value.trim().length < 10) {
                          return 'Địa chỉ quá ngắn';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Phương thức thanh toán',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('COD'),
                    value: 'COD',
                    groupValue: _paymentMethod,
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _paymentMethod = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Momo'),
                    value: 'Momo',
                    groupValue: _paymentMethod,
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _paymentMethod = value);
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Tổng tiền: ${priceFormat.format(_totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    child: _isPlacingOrder
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đặt hàng'),
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
