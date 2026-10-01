import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sales_order_cubit.dart';
import '../data/sales_order_model.dart';

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
            SalesOrderDetailsLoaded(:final order) =>
                _buildOrderDetails(context, order),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildOrderDetails(
      BuildContext context,
      SalesOrder order,
      ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          order.name,
          style: Theme.of(context).textTheme.headlineSmall,
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
        _buildOrderLines(order),
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
          _buildConfirmButton(context, order.id),
        ],
      ],
    );
  }

  Widget _buildOrderLines(SalesOrder order) {
    if (order.lines.isEmpty) {
      return const Text('No products found');
    }

    return Column(
      children: [
        for (final line in order.lines) _OrderLineCard(line: line),
      ],
    );
  }

  Widget _buildConfirmButton(
      BuildContext context,
      int orderId,
      ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<SalesOrderCubit>().confirmSalesOrder(orderId);
        },
        child: const Text('Confirm Order'),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'draft' => 'Quotation',
    'sent' => 'Quotation Sent',
    'sale' => 'Confirmed',
    'cancel' => 'Cancelled',
    _ => status,
  };
}

class _OrderLineCard extends StatelessWidget {
  const _OrderLineCard({
    required this.line,
  });

  final SalesOrderLine line;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.productName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('Quantity: ${line.quantity}'),
            Text('Unit Price: ${line.unitPrice}'),
            Text('Subtotal: ${line.subtotal}'),
          ],
        ),
      ),
    );
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
    final fontWeight = isTotal
        ? FontWeight.bold
        : FontWeight.normal;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: fontWeight),
          ),
          Text(
            '${value ?? 0}',
            style: TextStyle(fontWeight: fontWeight),
          ),
        ],
      ),
    );
  }
}