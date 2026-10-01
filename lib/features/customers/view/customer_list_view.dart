import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/customer_cubit.dart';
import '../data/customer_model.dart';
import '../data/customer_repo.dart';
import 'customer_details_view.dart';

class CustomerListView extends StatefulWidget {
  const CustomerListView({
    required CustomerRepository customerRepository,
    super.key,
  }) : _customerRepository = customerRepository;

  final CustomerRepository _customerRepository;

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

  void _clearSearch() {
    _searchController.clear();

    context.read<CustomerCubit>().loadCustomers();

    setState(() {});
  }

  Future<void> _openCustomerDetails(int customerId) async {
    final customerCubit = context.read<CustomerCubit>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: customerCubit,
          child: CustomerDetailsView(
            customerId: customerId,
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    await customerCubit.loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, state) {
                return switch (state) {
                  CustomerLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  CustomerError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  CustomerLoaded(:final customers) =>
                      _buildCustomerList(customers),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search customers',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: _clearSearch,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear search',
          )
              : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCustomerList(List<Customer> customers) {
    if (customers.isEmpty) {
      return const Center(
        child: Text('No customers found'),
      );
    }

    return ListView.separated(
      itemCount: customers.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final customer = customers[index];

        return ListTile(
          leading: CircleAvatar(
            child: Text(_getInitial(customer.name)),
          ),
          title: Text(customer.name),
          subtitle: _buildCustomerSubtitle(customer),
          onTap: () => _openCustomerDetails(customer.id),
        );
      },
    );
  }

  Widget _buildCustomerSubtitle(Customer customer) {
    final details = [
      if (customer.phone?.isNotEmpty ?? false) customer.phone!,
      if (customer.city?.isNotEmpty ?? false) customer.city!,
    ];

    if (details.isEmpty) {
      return const Text('No contact information');
    }

    return Text(details.join(' • '));
  }

  String _getInitial(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return '?';
    }

    return trimmedName[0].toUpperCase();
  }
}