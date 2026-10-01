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
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> {
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

  void _startEditingPhone(String? phone) {
    _phoneController.text = phone ?? '';

    setState(() {
      _isEditingPhone = true;
    });
  }

  void _cancelEditingPhone() {
    setState(() {
      _isEditingPhone = false;
    });
  }

  void _savePhone() {
    final phone = _phoneController.text.trim();

    setState(() {
      _isUpdatingPhone = true;
    });

    context.read<CustomerCubit>().updateCustomerPhone(
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
            setState(() {
              _isEditingPhone = false;
            });

            if (_isUpdatingPhone) {
              setState(() {
                _isUpdatingPhone = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone updated successfully'),
                ),
              );
            }
          }

          if (state is CustomerError) {
            setState(() {
              _isUpdatingPhone = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
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
              child: Text(state.message),
            );
          }

          if (state is CustomerDetailsLoaded) {
            final customer = state.customer;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoTile(
                  title: 'Name',
                  value: customer.name,
                ),
                _PhoneTile(
                  phone: customer.phone,
                  isEditing: _isEditingPhone,
                  isSaving: _isUpdatingPhone,
                  controller: _phoneController,
                  onEdit: () {
                    _startEditingPhone(customer.phone);
                  },
                  onSave: _savePhone,
                  onCancel: _cancelEditingPhone,
                ),
                _InfoTile(
                  title: 'Email',
                  value: customer.email,
                ),
                _InfoTile(
                  title: 'Address',
                  value: [
                    customer.street,
                    customer.street2,
                    customer.city,
                    customer.state,
                    customer.zip,
                    customer.country,
                  ]
                      .where(
                        (value) =>
                    value != null && value.isNotEmpty,
                  )
                      .join(', '),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        value == null || value!.isEmpty
            ? 'Not available'
            : value!,
      ),
    );
  }
}

class _PhoneTile extends StatelessWidget {
  const _PhoneTile({
    required this.phone,
    required this.isEditing,
    required this.isSaving,
    required this.controller,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
  });

  final String? phone;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController controller;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Phone'),
        subtitle: Text(
          phone == null || phone!.isEmpty
              ? 'Not available'
              : phone!,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            enabled: !isSaving,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isSaving ? null : onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}