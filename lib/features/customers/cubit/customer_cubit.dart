import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/customer_model.dart';
import '../data/customer_repo.dart';

sealed class CustomerState {}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  CustomerLoaded(this.customers);

  final List<Customer> customers;
}

class CustomerDetailsLoaded extends CustomerState {
  CustomerDetailsLoaded(this.customer);

  final Customer customer;
}

class CustomerError extends CustomerState {
  CustomerError(this.message);

  final String message;
}

class CustomerCubit extends Cubit<CustomerState> {
  CustomerCubit({
    required this._repository,
  }) : super(CustomerInitial());

  final CustomerRepository _repository;

  Future<void> loadCustomers() async {
    emit(CustomerLoading());

    try {
      final customers = await _repository.getCustomers();

      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(
        CustomerError(
          e.toString(),
        ),
      );
    }
  }

  Future<void> searchCustomers(String query) async {
    try {
      final customers = await _repository.getCustomers(
        search: query,
      );

      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(
        CustomerError(
          e.toString(),
        ),
      );
    }
  }

  Future<void> loadCustomerDetails(int customerId) async {
    emit(CustomerLoading());

    try {
      final customer = await _repository.getCustomerDetails(
        customerId,
      );

      emit(CustomerDetailsLoaded(customer));
    } catch (e) {
      emit(
        CustomerError(
          e.toString(),
        ),
      );
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
    } catch (e) {
      emit(
        CustomerError(
          e.toString(),
        ),
      );
    }
  }
}