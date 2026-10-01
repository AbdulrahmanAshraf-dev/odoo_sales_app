import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/customer_cubit.dart';
import '../data/customer_model.dart';

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

    context.read<CustomerCubit>().loadCustomerDetails(
      widget.customerId,
    );
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
      _showMessage('Phone number cannot be empty');
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _handleCustomerState(CustomerState state) {
    switch (state) {
      case CustomerDetailsLoaded():
        if (!_isUpdatingPhone) {
          return;
        }

        setState(() {
          _isEditingPhone = false;
          _isUpdatingPhone = false;
        });

        _showMessage('Phone updated successfully');

      case CustomerError():
        if (!_isUpdatingPhone) {
          return;
        }

        setState(() {
          _isUpdatingPhone = false;
        });

        _showMessage(state.message);

      case CustomerInitial():
      case CustomerLoading():
      case CustomerLoaded():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
      ),
      body: BlocConsumer<CustomerCubit, CustomerState>(
        listener: (context, state) {
          if (!context.mounted) {
            return;
          }

          _handleCustomerState(state);
        },
        builder: (context, state) {
          return switch (state) {
            CustomerLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CustomerError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            CustomerDetailsLoaded(:final customer) =>
                _buildCustomerDetails(customer),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildCustomerDetails(Customer customer) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          title: 'Name',
          value: customer.name,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 12),
        _buildPhoneCard(customer),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Email',
          value: customer.email ?? 'Not available',
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

  Widget _buildPhoneCard(Customer customer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                textInputAction: TextInputAction.done,
                enabled: !_isUpdatingPhone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter phone number',
                ),
                onSubmitted: (_) {
                  if (!_isUpdatingPhone) {
                    _savePhone();
                  }
                },
              )
            else
              Text(
                customer.phone ?? 'Not available',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 12),
            _buildPhoneActions(customer.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneActions(String? phone) {
    if (!_isEditingPhone) {
      return OutlinedButton.icon(
        onPressed: () => _startEditing(phone),
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
      );
    }

    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _isUpdatingPhone ? null : _savePhone,
          icon: _isUpdatingPhone
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Icon(Icons.save),
          label: const Text('Save'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _isUpdatingPhone ? null : _cancelEditing,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _buildAddress(Customer customer) {
    final parts = <String>[
      if (customer.street?.isNotEmpty ?? false)
        customer.street!,
      if (customer.street2?.isNotEmpty ?? false)
        customer.street2!,
      if (customer.city?.isNotEmpty ?? false) customer.city!,
      if (customer.zip?.isNotEmpty ?? false) customer.zip!,
      if (customer.state?.isNotEmpty ?? false) customer.state!,
      if (customer.country?.isNotEmpty ?? false)
        customer.country!,
    ];

    return parts.isEmpty ? 'Not available' : parts.join(', ');
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