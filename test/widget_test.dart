import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_sales_app/core/network/odoo_client.dart';
import 'package:odoo_sales_app/features/customers/cubit/customer_cubit.dart';
import 'package:odoo_sales_app/features/customers/data/customer_repo.dart';
import 'package:odoo_sales_app/features/customers/view/customer_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  testWidgets('Customer list screen builds', (tester) async {
    final odooClient = OdooClient(
      baseUrl: 'https://sales-app-demo.odoo.com',
    );

    final customerRepository = CustomerRepository(
      odooClient: odooClient,
      database: 'sales-app-demo',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => CustomerCubit(
            repository: customerRepository,
          ),
          child: CustomerListView(
            customerRepository: customerRepository,
          ),
        ),
      ),
    );

    expect(find.text('Customers'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}