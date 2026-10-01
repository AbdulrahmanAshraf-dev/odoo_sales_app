import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/odoo_client.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/view/login_view.dart';
import 'features/customers/data/customer_repo.dart';
import 'features/sales_order/data/sales_order_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final odooClient = OdooClient(
    baseUrl: 'https://sales-app-demo.odoo.com',
  );

  final customerRepository = CustomerRepository(
    odooClient: odooClient,
    database: 'sales-app-demo',
  );

  final salesOrderRepository = SalesOrderRepository(
    odooClient: odooClient,
    database: 'sales-app-demo',
  );

  runApp(
    MyApp(
      odooClient: odooClient,
      customerRepository: customerRepository,
      salesOrderRepository: salesOrderRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.odooClient,
    required this.customerRepository,
    required this.salesOrderRepository,
    super.key,
  });

  final OdooClient odooClient;
  final CustomerRepository customerRepository;
  final SalesOrderRepository salesOrderRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odoo Sales App',
      home: BlocProvider(
        create: (_) => AuthCubit(
          odooClient: odooClient,
        ),
        child: LoginView(
          customerRepository: customerRepository,
          salesOrderRepository: salesOrderRepository,
        ),
      ),
    );
  }
}