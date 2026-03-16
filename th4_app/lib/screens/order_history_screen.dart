import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../utils/app_constants.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = const OrderService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderService.loadOrderModels();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _orderService.loadOrderModels();
    });
    await _ordersFuture;
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn mua'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Tab>[
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã giao'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (BuildContext context, AsyncSnapshot<List<Order>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Không thể tải đơn hàng: ${snapshot.error}'),
              );
            }

            final List<Order> allOrders = snapshot.data ?? <Order>[];

            return RefreshIndicator(
              onRefresh: _refreshOrders,
              child: TabBarView(
                children: <Widget>[
                  _OrderStatusList(
                    orders: _filterByStatus(allOrders, AppConstants.orderStatusPending),
                    currencyFormat: currencyFormat,
                  ),
                  _OrderStatusList(
                    orders: _filterByStatus(allOrders, AppConstants.orderStatusShipping),
                    currencyFormat: currencyFormat,
                  ),
                  _OrderStatusList(
                    orders: _filterByStatus(allOrders, AppConstants.orderStatusDelivered),
                    currencyFormat: currencyFormat,
                  ),
                  _OrderStatusList(
                    orders: _filterByStatus(allOrders, AppConstants.orderStatusCancelled),
                    currencyFormat: currencyFormat,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Order> _filterByStatus(List<Order> orders, String status) {
    return orders.where((Order order) => order.status == status).toList();
  }
}

class _OrderStatusList extends StatelessWidget {
  const _OrderStatusList({required this.orders, required this.currencyFormat});

  final List<Order> orders;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 180),
          Center(child: Text('Chưa có đơn hàng')),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (BuildContext context, int index) {
        final Order order = orders[index];
        final DateTime? createdAt = DateTime.tryParse(order.createdAt);
        final String displayTime = createdAt == null
            ? '--'
            : DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal());

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Mã đơn: ${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('Ngày đặt: $displayTime'),
                Text('Thanh toán: ${order.paymentMethod}'),
                Text(
                  'Số sản phẩm: ${order.items.fold<int>(0, (int sum, item) => sum + item.quantity)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng tiền: ${currencyFormat.format(order.totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Địa chỉ: ${order.shippingAddress}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
