import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/customer_cubit.dart';

class CustomerDetailsView extends StatefulWidget {
  const CustomerDetailsView({
    required this.customerId,
    super.key,
  });

  final int customerId;

  @override
  State<CustomerDetailsView> createState() =>
      _CustomerDetailsViewState();
}

class _CustomerDetailsViewState
    extends State<CustomerDetailsView> {
  final _phoneController = TextEditingController();

  bool _isEditingPhone = false;
  bool _isUpdatingPhone = false;

  @override
  void initState() {
    super.initState();

    context
        .read<CustomerCubit>()
        .loadCustomerDetails(widget.customerId);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing(String? phone) {
    _phoneController.text = phone ?? '';

    setState(() {
      _isEditingPhone = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditingPhone = false;
      _isUpdatingPhone = false;
    });
  }

  Future<void> _savePhone() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number cannot be empty'),
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingPhone = true;
    });

    await context.read<CustomerCubit>().updateCustomerPhone(
      customerId: widget.customerId,
      phone: phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
      ),
      body: BlocConsumer<CustomerCubit, CustomerState>(
        listener: (context, state) {
          if (state is CustomerDetailsLoaded) {
            if (_isUpdatingPhone) {
              setState(() {
                _isEditingPhone = false;
                _isUpdatingPhone = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Phone updated successfully',
                  ),
                ),
              );
            }
          }

          if (state is CustomerError) {
            if (_isUpdatingPhone) {
              setState(() {
                _isUpdatingPhone = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is CustomerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is CustomerDetailsLoaded) {
            final customer = state.customer;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(
                  title: 'Name',
                  value: customer.name,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_outlined),
                            SizedBox(width: 8),
                            Text(
                              'Phone',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_isEditingPhone)
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_isUpdatingPhone,
                            decoration:
                            const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter phone number',
                            ),
                          )
                        else
                          Text(
                            customer.phone ?? 'Not available',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            if (!_isEditingPhone)
                              OutlinedButton.icon(
                                onPressed: () {
                                  _startEditing(
                                    customer.phone,
                                  );
                                },
                                icon: const Icon(
                                  Icons.edit,
                                ),
                                label: const Text('Edit'),
                              ),

                            if (_isEditingPhone) ...[
                              ElevatedButton.icon(
                                onPressed: _isUpdatingPhone
                                    ? null
                                    : _savePhone,
                                icon: _isUpdatingPhone
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Icon(
                                  Icons.save,
                                ),
                                label: const Text('Save'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed:
                                _isUpdatingPhone
                                    ? null
                                    : _cancelEditing,
                                child:
                                const Text('Cancel'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _InfoCard(
                  title: 'Email',
                  value:
                  customer.email ?? 'Not available',
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 12),

                _InfoCard(
                  title: 'Address',
                  value: _buildAddress(customer),
                  icon: Icons.location_on_outlined,
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _buildAddress(dynamic customer) {
    final parts = <String>[
      if (customer.street != null &&
          customer.street!.isNotEmpty)
        customer.street!,
      if (customer.street2 != null &&
          customer.street2!.isNotEmpty)
        customer.street2!,
      if (customer.city != null &&
          customer.city!.isNotEmpty)
        customer.city!,
      if (customer.zip != null &&
          customer.zip!.isNotEmpty)
        customer.zip!,
      if (customer.state != null &&
          customer.state!.isNotEmpty)
        customer.state!,
      if (customer.country != null &&
          customer.country!.isNotEmpty)
        customer.country!,
    ];

    return parts.isEmpty
        ? 'Not available'
        : parts.join(', ');
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }
}