import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/sales_order_model.dart';
import '../data/sales_order_repo.dart';

sealed class SalesOrderState {}

class SalesOrderInitial extends SalesOrderState {}

class SalesOrderLoading extends SalesOrderState {}

class SalesOrderLoaded extends SalesOrderState {
  SalesOrderLoaded(this.orders);

  final List<SalesOrder> orders;
}

class SalesOrderDetailsLoaded extends SalesOrderState {
  SalesOrderDetailsLoaded(this.order);

  final SalesOrder order;
}

class SalesOrderError extends SalesOrderState {
  SalesOrderError(this.message);

  final String message;
}

class SalesOrderCubit extends Cubit<SalesOrderState> {
  SalesOrderCubit({
    required this._repository,
  }) : super(SalesOrderInitial());

  final SalesOrderRepository _repository;

  Future<void> loadSalesOrders() async {
    emit(SalesOrderLoading());

    try {
      final orders = await _repository.getSalesOrders();

      emit(SalesOrderLoaded(orders));
    } catch (e) {
      emit(
        SalesOrderError(
          e.toString(),
        ),
      );
    }
  }

  Future<void> loadSalesOrderDetails(int orderId) async {
    emit(SalesOrderLoading());

    try {
      final order = await _repository.getSalesOrderDetails(
        orderId,
      );

      final lines = await _repository.getSalesOrderLines(
        order.lineIds,
      );

      emit(
        SalesOrderDetailsLoaded(
          order.copyWith(lines: lines),
        ),
      );
    } catch (e) {
      emit(
        SalesOrderError(
          e.toString(),
        ),
      );
    }
  }

  Future<void> confirmSalesOrder(int orderId) async {
    try {
      await _repository.confirmSalesOrder(orderId);

      await loadSalesOrderDetails(orderId);
    } catch (e) {
      emit(
        SalesOrderError(
          e.toString(),
        ),
      );
    }
  }
}