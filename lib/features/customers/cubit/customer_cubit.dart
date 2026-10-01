import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/customer_model.dart';
import '../data/customer_repo.dart';

sealed class CustomerState {
  const CustomerState();
}

class CustomerInitial extends CustomerState {
  const CustomerInitial();
}

class CustomerLoading extends CustomerState {
  const CustomerLoading();
}

class CustomerLoaded extends CustomerState {
  const CustomerLoaded(this.customers);

  final List<Customer> customers;
}

class CustomerDetailsLoaded extends CustomerState {
  const CustomerDetailsLoaded(this.customer);

  final Customer customer;
}

class CustomerError extends CustomerState {
  const CustomerError(this.message);

  final String message;
}

class CustomerCubit extends Cubit<CustomerState> {
  CustomerCubit({
    required CustomerRepository repository,
  })  : _repository = repository,
        super(const CustomerInitial());

  final CustomerRepository _repository;

  Future<void> loadCustomers() async {
    emit(const CustomerLoading());

    try {
      final customers = await _repository.getCustomers();

      emit(CustomerLoaded(customers));
    } catch (error) {
      emit(CustomerError(error.toString()));
    }
  }

  Future<void> searchCustomers(String query) async {
    try {
      final customers = await _repository.getCustomers(
        search: query,
      );

      emit(CustomerLoaded(customers));
    } catch (error) {
      emit(CustomerError(error.toString()));
    }
  }

  Future<void> loadCustomerDetails(int customerId) async {
    emit(const CustomerLoading());

    try {
      final customer = await _repository.getCustomerDetails(
        customerId,
      );

      emit(CustomerDetailsLoaded(customer));
    } catch (error) {
      emit(CustomerError(error.toString()));
    }
  }

  Future<void> updateCustomerPhone({
    required int customerId,
    required String phone,
  }) async {
    try {
      await _repository.updateCustomerPhone(
        customerId: customerId,
        phone: phone,
      );

      final customer = await _repository.getCustomerDetails(
        customerId,
      );

      emit(CustomerDetailsLoaded(customer));
    } catch (error) {
      emit(CustomerError(error.toString()));
    }
  }
}