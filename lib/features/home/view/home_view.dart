import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../customers/cubit/customer_cubit.dart';
import '../../customers/data/customer_repo.dart';
import '../../customers/view/customer_list_view.dart';
import '../../sales_order/cubit/sales_order_cubit.dart';
import '../../sales_order/data/sales_order_repo.dart';
import '../../sales_order/view/sales_order_list_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    required CustomerRepository customerRepository,
    required SalesOrderRepository salesOrderRepository,
    required this.isInternalUser,
    super.key,
  })  : _customerRepository = customerRepository,
        _salesOrderRepository = salesOrderRepository;

  final CustomerRepository _customerRepository;
  final SalesOrderRepository _salesOrderRepository;
  final bool isInternalUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Sales App'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCustomersCard(context),
          if (isInternalUser) ...[
            const SizedBox(height: 12),
            _buildSalesOrdersCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomersCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.people),
        title: const Text('Customers'),
        subtitle: const Text('View and manage customers'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => CustomerCubit(
                  repository: _customerRepository,
                ),
                child: CustomerListView(
                  customerRepository: _customerRepository,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesOrdersCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: const Text('Sales Orders'),
        subtitle: const Text('View and manage sales orders'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => SalesOrderCubit(
                  repository: _salesOrderRepository,
                )..loadSalesOrders(),
                child: SalesOrderListView(
                  salesOrderRepository: _salesOrderRepository,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}