import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/customer_cubit.dart';
import '../data/customer_repo.dart';
import 'customer_details_view.dart';

class CustomerListView extends StatefulWidget {
  const CustomerListView({
    required this.customerRepository,
    super.key,
  });

  final CustomerRepository customerRepository;

  @override
  State<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends State<CustomerListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    context.read<CustomerCubit>().loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    context.read<CustomerCubit>().searchCustomers(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search customers',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<CustomerCubit>()
                        .loadCustomers();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is CustomerError) {
                  return Center(
                    child: Text(state.message),
                  );
                }

                if (state is CustomerLoaded) {
                  if (state.customers.isEmpty) {
                    return const Center(
                      child: Text('No customers found'),
                    );
                  }

                  return ListView.separated(
                    itemCount: state.customers.length,
                    separatorBuilder: (_, _) =>
                    const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer = state.customers[index];

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(
                          [
                            if (customer.phone != null &&
                                customer.phone!.isNotEmpty)
                              customer.phone!,
                            if (customer.city != null &&
                                customer.city!.isNotEmpty)
                              customer.city!,
                          ].join(' • '),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => CustomerCubit(
                                  repository:
                                  widget.customerRepository,
                                ),
                                child: CustomerDetailsView(
                                  customerId: customer.id,
                                ),
                              ),
                            ),
                          );

                          if (!context.mounted) {
                            return;
                          }

                          context
                              .read<CustomerCubit>()
                              .loadCustomers();
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}