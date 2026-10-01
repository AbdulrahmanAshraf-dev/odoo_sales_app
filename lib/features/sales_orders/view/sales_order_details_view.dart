import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../sales_order/cubit/sales_order_cubit.dart';


class SalesOrderDetailsView extends StatefulWidget {
  const SalesOrderDetailsView({
    required this.orderId,
    super.key,
  });

  final int orderId;

  @override
  State<SalesOrderDetailsView> createState() =>
      _SalesOrderDetailsViewState();
}

class _SalesOrderDetailsViewState
    extends State<SalesOrderDetailsView> {
  @override
  void initState() {
    super.initState();

    context.read<SalesOrderCubit>().loadSalesOrderDetails(
      widget.orderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Order Details'),
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

          if (state is SalesOrderDetailsLoaded) {
            final order = state.order;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  order.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),

                const SizedBox(height: 16),

                _InfoRow(
                  label: 'Customer',
                  value: order.customerName,
                ),

                _InfoRow(
                  label: 'Order Date',
                  value: order.orderDate,
                ),

                _InfoRow(
                  label: 'Status',
                  value: _statusLabel(order.status),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (order.lines.isEmpty)
                  const Text('No products found')
                else
                  ...order.lines.map(
                        (line) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Quantity: ${line.quantity}',
                            ),
                            Text(
                              'Unit Price: ${line.unitPrice}',
                            ),
                            Text(
                              'Subtotal: ${line.subtotal}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                const Divider(),

                _TotalRow(
                  label: 'Untaxed',
                  value: order.amountUntaxed,
                ),

                _TotalRow(
                  label: 'Tax',
                  value: order.amountTax,
                ),

                _TotalRow(
                  label: 'Total',
                  value: order.amountTotal,
                  isTotal: true,
                ),

                if (order.status == 'draft') ...[
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .read<SalesOrderCubit>()
                            .confirmSalesOrder(order.id);
                      },
                      child: const Text('Confirm Order'),
                    ),
                  ),
                ],
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _statusLabel(String status) {
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double? value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight:
              isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${value ?? 0}',
            style: TextStyle(
              fontWeight:
              isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}