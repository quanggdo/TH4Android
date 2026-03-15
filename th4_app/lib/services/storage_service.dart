import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../utils/app_constants.dart';

class StorageService {
  Future<void> saveCart(List<CartItem> items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.cartStorageKey, encoded);
  }

  Future<List<CartItem>> loadCart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(AppConstants.cartStorageKey);

    if (encoded == null || encoded.isEmpty) {
      return <CartItem>[];
    }

    try {
      final List<dynamic> raw = jsonDecode(encoded) as List<dynamic>;
      return raw
          .map((dynamic e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <CartItem>[];
    }
  }

  Future<void> clearCart() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.cartStorageKey);
  }
}
