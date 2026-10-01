import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/customers/cubit/customer_cubit.dart';
import 'features/customers/data/customer_repo.dart';
import 'features/customers/view/customer_list_view.dart';

class App extends StatelessWidget {
  const App({
    required this.odooClient,
    super.key,
  });

  final dynamic odooClient;

  @override
  Widget build(BuildContext context) {
    final customerRepository = CustomerRepository(
      odooClient: odooClient,
      database: 'sales-app-demo',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odoo Sales App',
      home: BlocProvider(
        create: (_) => CustomerCubit(
          repository: customerRepository,
        )..loadCustomers(),
        child: CustomerListView(
          customerRepository: customerRepository,
        ),
      ),
    );
  }
}