import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:th4_app/models/product.dart';
import 'package:th4_app/providers/cart_provider.dart';
import 'package:th4_app/services/storage_service.dart';

Future<void> _waitForAsyncState() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

Product _sampleProduct() {
  return Product(
    id: 1,
    title: 'T-Shirt',
    price: 120000,
    description: 'Sample',
    category: 'fashion',
    image: 'https://example.com/image.png',
  );
}

Product _sampleProduct2() {
  return Product(
    id: 2,
    title: 'Shoes',
    price: 350000,
    description: 'Sample 2',
    category: 'fashion',
    image: 'https://example.com/image2.png',
  );
}

void main() {
  group('CartProvider persistence', () {
    test('addItem updates state and local storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      provider.addItem(_sampleProduct());
      await _waitForAsyncState();

      expect(provider.items.length, 1);
      expect(provider.items.first.quantity, 1);

      final reloadedProvider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      expect(reloadedProvider.items.length, 1);
      expect(reloadedProvider.items.first.product.id, 1);
      expect(reloadedProvider.items.first.product.title, 'T-Shirt');
      expect(reloadedProvider.items.first.product.price, 120000);
      expect(reloadedProvider.items.first.product.description, 'Sample');
      expect(reloadedProvider.items.first.product.category, 'fashion');
      expect(
        reloadedProvider.items.first.product.image,
        'https://example.com/image.png',
      );
    });

    test('quantity and selection changes are persisted', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      provider.addItem(_sampleProduct());
      await _waitForAsyncState();
      provider.incrementQuantity(0);
      provider.toggleSelect(0, false);
      await _waitForAsyncState();

      expect(provider.items.first.quantity, 2);
      expect(provider.items.first.isSelected, isFalse);

      final reloadedProvider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      expect(reloadedProvider.items.first.quantity, 2);
      expect(reloadedProvider.items.first.isSelected, isFalse);
    });

    test('removeAt updates state and local storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      provider.addItem(_sampleProduct());
      await _waitForAsyncState();
      provider.removeAt(0);
      await _waitForAsyncState();

      expect(provider.items, isEmpty);

      final reloadedProvider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      expect(reloadedProvider.items, isEmpty);
    });

    test('select all logic stays in sync with individual item selection',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      provider.addItem(_sampleProduct());
      provider.addItem(_sampleProduct2());
      await _waitForAsyncState();

      provider.toggleAll(true);
      await _waitForAsyncState();
      expect(provider.isAllSelected, isTrue);

      provider.toggleSelect(0, false);
      await _waitForAsyncState();
      expect(provider.isAllSelected, isFalse);

      provider.toggleSelect(0, true);
      await _waitForAsyncState();
      expect(provider.isAllSelected, isTrue);
    });

    test('decrement to zero requires confirmation and removes when confirmed',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      provider.addItem(_sampleProduct());
      await _waitForAsyncState();

      expect(provider.shouldConfirmRemoveOnDecrement(0), isTrue);

      provider.decrementOrRemove(0, confirmedRemove: false);
      await _waitForAsyncState();
      expect(provider.items.length, 1);

      provider.decrementOrRemove(0, confirmedRemove: true);
      await _waitForAsyncState();
      expect(provider.items, isEmpty);
    });

    test('totalSelectedQuantity sums only selected item quantities', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      provider.addItem(_sampleProduct());
      provider.addItem(_sampleProduct2());
      await _waitForAsyncState();

      provider.incrementQuantity(0);
      await _waitForAsyncState();

      // Item 0 qty = 2, item 1 qty = 1, both selected by default.
      expect(provider.totalSelectedQuantity, 3);

      provider.toggleSelect(1, false);
      await _waitForAsyncState();
      expect(provider.totalSelectedQuantity, 2);
      expect(provider.hasPartialSelection, isTrue);
    });

    test('buildSelectedOrderRequest throws when no item is selected',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = CartProvider(storageService: StorageService());
      await _waitForAsyncState();

      provider.addItem(_sampleProduct());
      await _waitForAsyncState();
      provider.toggleAll(false);
      await _waitForAsyncState();

      expect(
        () => provider.buildSelectedOrderRequest(
          paymentMethod: 'COD',
          shippingAddress: '123 Nguyen Trai',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
