import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:th4_app/models/cart_item_dto.dart';
import 'package:th4_app/models/order_request.dart';
import 'package:th4_app/models/product.dart';
import 'package:th4_app/services/order_service.dart';

OrderRequest _sampleOrderRequest({String paymentMethod = 'COD'}) {
  return OrderRequest(
    items: <CartItemDTO>[
      CartItemDTO(
        productId: 1,
        product: Product(
          id: 1,
          title: 'T-Shirt',
          price: 120000,
          description: 'Sample',
          category: 'fashion',
          image: 'https://example.com/image.png',
          rating: ProductRating(rate: 4.2, count: 50),
        ),
        quantity: 2,
        size: 'M',
        color: 'Red',
        unitPrice: 120000,
      ),
    ],
    paymentMethod: paymentMethod,
    shippingAddress: '123 Nguyen Trai, Q1, TP.HCM',
    totalAmount: 240000,
    note: 'Test order',
  );
}

void main() {
  group('OrderService local persistence', () {
    test('placeOrder stores order and getOrderById finds it', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const OrderService service = OrderService();

      final String orderId = await service.placeOrder(
        orderRequest: _sampleOrderRequest(),
      );

      final order = await service.getOrderById(orderId);

      expect(order, isNotNull);
      expect(order!.id, orderId);
      expect(order.status, 'pending');
      expect(order.paymentMethod, 'COD');
    });

    test('updateOrderStatus and cancelOrder update local state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const OrderService service = OrderService();

      final String orderId = await service.placeOrder(
        orderRequest: _sampleOrderRequest(paymentMethod: 'Momo'),
      );

      await service.updateOrderStatus(orderId, 'shipping');
      var order = await service.getOrderById(orderId);
      expect(order, isNotNull);
      expect(order!.status, 'shipping');

      await service.cancelOrder(orderId);
      order = await service.getOrderById(orderId);
      expect(order, isNotNull);
      expect(order!.status, 'cancelled');
    });

    test('loadOrdersByStatus filters correctly', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const OrderService service = OrderService();

      final String orderA = await service.placeOrder(
        orderRequest: _sampleOrderRequest(paymentMethod: 'COD'),
      );
      final String orderB = await service.placeOrder(
        orderRequest: _sampleOrderRequest(paymentMethod: 'Momo'),
      );

      await service.updateOrderStatus(orderA, 'shipping');
      await service.updateOrderStatus(orderB, 'delivered');

      final shipping = await service.loadOrdersByStatus('shipping');
      final delivered = await service.loadOrdersByStatus('delivered');

      expect(shipping.length, 1);
      expect(delivered.length, 1);
      expect(shipping.first.id, orderA);
      expect(delivered.first.id, orderB);
    });

    test('loadOrdersByStatus normalizes input casing and spaces', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const OrderService service = OrderService();

      final String orderId = await service.placeOrder(
        orderRequest: _sampleOrderRequest(),
      );
      await service.updateOrderStatus(orderId, 'shipping');

      final List<dynamic> shipping =
          await service.loadOrdersByStatus('  SHIPPING  ');
      expect(shipping.length, 1);
      expect(shipping.first.id, orderId);
    });

    test('updateOrderStatus throws for unsupported status', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const OrderService service = OrderService();

      final String orderId = await service.placeOrder(
        orderRequest: _sampleOrderRequest(),
      );

      expect(
        () => service.updateOrderStatus(orderId, 'unknown_status'),
        throwsA(isA<StateError>()),
      );
    });

    test('placeOrder throws when request items are empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const OrderService service = OrderService();

      final emptyRequest = OrderRequest(
        items: <CartItemDTO>[],
        paymentMethod: 'COD',
        shippingAddress: '123 Nguyen Trai, Q1, TP.HCM',
        totalAmount: 0,
      );

      expect(
        () => service.placeOrder(orderRequest: emptyRequest),
        throwsA(isA<StateError>()),
      );
    });
  });
}
