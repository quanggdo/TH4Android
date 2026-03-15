import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/cart_item_dto.dart';
import '../models/order_request.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({required StorageService storageService})
      : _storageService = storageService {
    loadCartFromStorage();
  }

  final StorageService _storageService;
  final List<CartItem> _items = <CartItem>[];
  bool _isLoading = true;

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);
  bool get isLoading => _isLoading;

  double get totalAmount {
    return _items
        .where((CartItem item) => item.isSelected)
        .fold<double>(0, (double sum, CartItem item) {
      return sum + (item.product.price * item.quantity);
    });
  }

  int get selectedCount {
    return _items.where((CartItem item) => item.isSelected).length;
  }

  int get totalSelectedQuantity {
    return _items
        .where((CartItem item) => item.isSelected)
        .fold<int>(0, (int sum, CartItem item) => sum + item.quantity);
  }

  bool get isAllSelected {
    return _items.isNotEmpty &&
        _items.every((CartItem item) => item.isSelected);
  }

  bool get hasPartialSelection {
    return selectedCount > 0 && !isAllSelected;
  }

  List<CartItemDTO> get selectedItemsDTO {
    return _items
        .where((CartItem item) => item.isSelected)
        .map((CartItem item) => item.toDTO())
        .toList();
  }

  Future<void> loadCartFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _items
      ..clear()
      ..addAll(await _storageService.loadCart());

    _isLoading = false;
    notifyListeners();
  }

  void addItem(
    Product product, {
    String size = 'M',
    String color = 'Default',
  }) {
    final int index = _items.indexWhere(
      (CartItem item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.color == color,
    );

    if (index == -1) {
      _items.add(
        CartItem(
          product: product,
          quantity: 1,
          isSelected: true,
          size: size,
          color: color,
        ),
      );
    } else {
      _items[index].quantity += 1;
    }

    _saveAndNotify();
  }

  void incrementQuantity(int index) {
    if (!_isValidIndex(index)) {
      return;
    }

    _items[index].quantity += 1;
    _saveAndNotify();
  }

  void decrementQuantity(int index) {
    if (!_isValidIndex(index)) {
      return;
    }

    if (_items[index].quantity > 1) {
      _items[index].quantity -= 1;
      _saveAndNotify();
    }
  }

  bool shouldConfirmRemoveOnDecrement(int index) {
    if (!_isValidIndex(index)) {
      return false;
    }

    return _items[index].quantity <= 1;
  }

  void decrementOrRemove(int index, {required bool confirmedRemove}) {
    if (!_isValidIndex(index)) {
      return;
    }

    if (_items[index].quantity > 1) {
      _items[index].quantity -= 1;
      _saveAndNotify();
      return;
    }

    if (confirmedRemove) {
      _items.removeAt(index);
      _saveAndNotify();
    }
  }

  void updateQuantity(int index, int quantity) {
    if (!_isValidIndex(index)) {
      return;
    }

    _items[index].quantity = quantity < 1 ? 1 : quantity;
    _saveAndNotify();
  }

  void toggleSelect(int index, bool value) {
    if (!_isValidIndex(index)) {
      return;
    }

    _items[index].isSelected = value;
    _saveAndNotify();
  }

  void toggleSelectAt(int index) {
    if (!_isValidIndex(index)) {
      return;
    }

    _items[index].isSelected = !_items[index].isSelected;
    _saveAndNotify();
  }

  void toggleAll(bool value) {
    for (final CartItem item in _items) {
      item.isSelected = value;
    }
    _saveAndNotify();
  }

  void syncSelectAllFromItems() {
    notifyListeners();
  }

  void removeAt(int index) {
    if (!_isValidIndex(index)) {
      return;
    }

    _items.removeAt(index);
    _saveAndNotify();
  }

  void removeSelectedItems() {
    _items.removeWhere((CartItem item) => item.isSelected);
    _saveAndNotify();
  }

  Future<void> checkoutSelected() async {
    _items.removeWhere((CartItem item) => item.isSelected);
    await _storageService.saveCart(_items);
    notifyListeners();
  }

  OrderRequest buildSelectedOrderRequest({
    required String paymentMethod,
    required String shippingAddress,
    String? note,
  }) {
    final List<CartItemDTO> selectedItems = selectedItemsDTO;
    if (selectedItems.isEmpty) {
      throw StateError('Cannot build order request from empty selection');
    }

    final double selectedTotal = selectedItems.fold<double>(
      0,
      (double sum, CartItemDTO item) => sum + (item.unitPrice * item.quantity),
    );

    return OrderRequest(
      items: selectedItems,
      paymentMethod: paymentMethod,
      shippingAddress: shippingAddress,
      totalAmount: selectedTotal,
      note: note,
    );
  }

  bool _isValidIndex(int index) {
    return index >= 0 && index < _items.length;
  }

  Future<void> _saveAndNotify() async {
    await _storageService.saveCart(_items);
    notifyListeners();
  }
}
