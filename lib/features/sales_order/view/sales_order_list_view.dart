import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sales_order_details_view.dart';
import '../cubit/sales_order_cubit.dart';
import '../data/sales_order_model.dart';
import '../data/sales_order_repo.dart';

class SalesOrderListView extends StatelessWidget {
  const SalesOrderListView({
    required this.salesOrderRepository,
    super.key,
  });

  final SalesOrderRepository salesOrderRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Orders'),
      ),
      body: BlocBuilder<SalesOrderCubit, SalesOrderState>(
        builder: (context, state) {
          return switch (state) {
            SalesOrderLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SalesOrderError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SalesOrderLoaded(:final orders) => _buildOrderList(
              context,
              orders,
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildOrderList(
      BuildContext context,
      List<SalesOrder> orders,
      ) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No sales orders found'),
      );
    }

    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = orders[index];

        return ListTile(
          title: Text(order.name),
          subtitle: Text(
            '${order.customerName} • ${order.orderDate}',
          ),
          trailing: _StatusChip(status: order.status),
          onTap: () => _openOrderDetails(
            context,
            order.id,
          ),
        );
      },
    );
  }

  Future<void> _openOrderDetails(
      BuildContext context,
      int orderId,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => SalesOrderCubit(
            repository: salesOrderRepository,
          ),
          child: SalesOrderDetailsView(
            orderId: orderId,
          ),
        ),
      ),
    );

    if (!context.mounted) return;

    await context.read<SalesOrderCubit>().loadSalesOrders();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  String get _label => switch (status) {
    'draft' => 'Quotation',
    'sent' => 'Quotation Sent',
    'sale' => 'Confirmed',
    'cancel' => 'Cancelled',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label),
    );
  }
}