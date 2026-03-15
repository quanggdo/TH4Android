import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../utils/app_constants.dart';

class ApiService {
  Future<List<Product>> fetchProducts({
    int? limit,
    String? sort,
  }) async {
    final Uri uri = _buildProductsUri(
      limit: limit,
      sort: sort,
    );

    return _fetchProductList(uri, errorPrefix: 'Cannot fetch products');
  }

  Future<List<Product>> fetchProductsByCategory(
    String category, {
    int? limit,
    String? sort,
  }) async {
    if (category.trim().isEmpty) {
      throw ArgumentError('category cannot be empty');
    }

    final Uri base = Uri.parse(
      '${AppConstants.baseApiUrl}/products/category/${Uri.encodeComponent(category)}',
    );
    final Uri uri = _withQueryParameters(base, limit: limit, sort: sort);

    return _fetchProductList(
      uri,
      errorPrefix: 'Cannot fetch products for category "$category"',
    );
  }

  Future<List<String>> fetchCategories() async {
    final Uri uri = Uri.parse('${AppConstants.baseApiUrl}/products/categories');

    try {
      final http.Response response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }

      final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
      return raw.map((dynamic e) => e.toString()).toList();
    } catch (e) {
      throw Exception('Cannot fetch categories: $e');
    }
  }

  // FakeStore has no page param, so pagination is emulated via limit + slice.
  Future<List<Product>> fetchProductsPage({
    required int page,
    int pageSize = 10,
    String? sort,
    String? category,
  }) async {
    if (page < 1) {
      throw ArgumentError('page must be >= 1');
    }
    if (pageSize < 1) {
      throw ArgumentError('pageSize must be >= 1');
    }

    final int limit = page * pageSize;
    final List<Product> allUntilPage = (category == null || category.isEmpty)
        ? await fetchProducts(limit: limit, sort: sort)
        : await fetchProductsByCategory(
            category,
            limit: limit,
            sort: sort,
          );

    final int start = (page - 1) * pageSize;
    if (start >= allUntilPage.length) {
      return <Product>[];
    }
    final int endExclusive =
        (start + pageSize > allUntilPage.length) ? allUntilPage.length : start + pageSize;
    return allUntilPage.sublist(start, endExclusive);
  }

  Uri _buildProductsUri({
    int? limit,
    String? sort,
  }) {
    final Uri base = Uri.parse('${AppConstants.baseApiUrl}/products');
    return _withQueryParameters(base, limit: limit, sort: sort);
  }

  Uri _withQueryParameters(
    Uri base, {
    int? limit,
    String? sort,
  }) {
    final Map<String, String> query = <String, String>{};
    if (limit != null && limit > 0) {
      query['limit'] = limit.toString();
    }
    if (sort == 'asc' || sort == 'desc') {
      query['sort'] = sort!;
    }

    return query.isEmpty ? base : base.replace(queryParameters: query);
  }

  Future<List<Product>> _fetchProductList(
    Uri uri, {
    required String errorPrefix,
  }) async {

    try {
      final http.Response response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to load products: ${response.statusCode}');
      }

      final List<dynamic> raw = jsonDecode(response.body) as List<dynamic>;
      return raw
          .map((dynamic e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('$errorPrefix: $e');
    }
  }
}
