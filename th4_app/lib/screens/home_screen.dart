import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_scroller.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_badge.dart';
import 'order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<Product> _products = <Product>[];
  final List<String> _categories = <String>[];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';
  List<Product> _displayedProducts = <Product>[];
  String? _selectedCategory;

  int _page = 1;
  final int _pageSize = 10;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await _loadCategories();
    await _refreshProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final List<String> cats = await _apiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories.clear();
        _categories.addAll(cats);
      });
    } catch (e) {
      // ignore errors silently for demo
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
      _page = 1;
      _hasMore = true;
    });

    try {
      final List<Product> page = await _apiService.fetchProductsPage(
        page: _page,
        pageSize: _pageSize,
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(page);
        _hasMore = page.length == _pageSize;
        _applyQuery();
      });
    } catch (e) {
      // ignore for now
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    setState(() => _isLoading = true);
    _page += 1;
    try {
      final List<Product> page = await _apiService.fetchProductsPage(
        page: _page,
        pageSize: _pageSize,
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(page);
        _hasMore = page.length == _pageSize;
        _applyQuery();
      });
    } catch (e) {
      _page -= 1;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCategorySelected(String? category) async {
    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
      _query = '';
      _searchController.text = '';
      _page = 1;
      _hasMore = true;
      _products.clear();
      _displayedProducts.clear();
      _isLoading = true;
    });

    try {
      await _refreshProducts();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double max = _scrollController.position.maxScrollExtent;
    final double current = _scrollController.position.pixels;
    if (max - current <= 300) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        // Reset pagination when performing a search for better UX
        _page = 1;
      });
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final String q = _query.toLowerCase();
    if (q.isEmpty) {
      // clear search -> show normal list
      _applyQuery();
      return;
    }

    setState(() => _isLoading = true);
    try {
      // FakeStore has no search endpoint, so fetch a broad list and filter locally.
      final List<Product> all = (_selectedCategory == null ||
              _selectedCategory!.isEmpty)
          ? await _apiService.fetchProducts(limit: 100)
          : await _apiService.fetchProductsByCategory(
              _selectedCategory!,
              limit: 100,
            );
      final List<Product> filtered = all.where((Product p) {
        return p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
      if (!mounted) return;
      setState(() {
        _displayedProducts
          ..clear()
          ..addAll(filtered);
      });
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyQuery() {
    if (_query.isEmpty) {
      _displayedProducts
        ..clear()
        ..addAll(_products);
    } else {
      final String q = _query.toLowerCase();
      _displayedProducts
        ..clear()
        ..addAll(
          _products.where(
            (Product p) =>
                p.title.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q),
          ),
        );
    }
  }

  void _addToCart(Product product) {
    final CartProvider cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(product);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              centerTitle: false,
              title: const Text('TH4 - Nhóm 2'),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: 'Đơn mua',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CartBadge(),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: BannerCarousel(
                  images: const [
                    'https://picsum.photos/900/400?image=1067',
                    'https://picsum.photos/900/400?image=1025',
                    'https://picsum.photos/900/400?image=1031',
                  ],
                ),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(controller: _searchController),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CategoryScroller(
                  categories: _categories,
                  activeCategory: _selectedCategory,
                  onCategorySelected: _onCategorySelected,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  if (index >= _displayedProducts.length) {
                    return const SizedBox.shrink();
                  }
                  final Product p = _displayedProducts[index];
                  return ProductCard(
                    product: p,
                    priceFormat: priceFormat,
                    onAdd: () => _addToCart(p),
                  );
                }, childCount: _displayedProducts.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.65,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : !_hasMore
                      ? const Text('Không còn sản phẩm')
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarDelegate({required this.controller});

  final TextEditingController controller;
  final double _height = 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final bool scrolled = shrinkOffset > 8.0;
    final Color bg = scrolled
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;

    return Container(
      color: bg.withOpacity(scrolled ? 1.0 : 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.center,
      child: Material(
        elevation: scrolled ? 2 : 0,
        borderRadius: BorderRadius.circular(8),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
