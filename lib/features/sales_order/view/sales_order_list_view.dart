import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../sales_orders/view/sales_order_details_view.dart';
import '../cubit/sales_order_cubit.dart';
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
          if (state is SalesOrderLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is SalesOrderError) {
            return Center(
              child: Text(state.message),
            );
          }

          if (state is SalesOrderLoaded) {
            if (state.orders.isEmpty) {
              return const Center(
                child: Text('No sales orders found'),
              );
            }

            return ListView.separated(
              itemCount: state.orders.length,
              separatorBuilder: (_, _) =>
              const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = state.orders[index];

                return ListTile(
                  title: Text(order.name),
                  subtitle: Text(
                    '${order.customerName} • ${order.orderDate}',
                  ),
                  trailing: _StatusChip(
                    status: order.status,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => SalesOrderCubit(
                            repository: salesOrderRepository,
                          ),
                          child: SalesOrderDetailsView(
                            orderId: order.id,
                          ),
                        ),
                      ),
                    );

                    if (!context.mounted) {
                      return;
                    }

                    context.read<SalesOrderCubit>().loadSalesOrders();
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  String get _label {
    switch (status) {
      case 'draft':
        return 'Quotation';
      case 'sent':
        return 'Quotation Sent';
      case 'sale':
        return 'Confirmed';
      case 'cancel':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label),
    );
  }
}