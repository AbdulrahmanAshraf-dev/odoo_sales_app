import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/sales_order_model.dart';
import '../data/sales_order_repo.dart';

sealed class SalesOrderState {
  const SalesOrderState();
}

class SalesOrderInitial extends SalesOrderState {
  const SalesOrderInitial();
}

class SalesOrderLoading extends SalesOrderState {
  const SalesOrderLoading();
}

class SalesOrderLoaded extends SalesOrderState {
  const SalesOrderLoaded(this.orders);

  final List<SalesOrder> orders;
}

class SalesOrderDetailsLoaded extends SalesOrderState {
  const SalesOrderDetailsLoaded(this.order);

  final SalesOrder order;
}

class SalesOrderError extends SalesOrderState {
  const SalesOrderError(this.message);

  final String message;
}

class SalesOrderCubit extends Cubit<SalesOrderState> {
  SalesOrderCubit({
    required SalesOrderRepository repository,
  })  : _repository = repository,
        super(const SalesOrderInitial());

  final SalesOrderRepository _repository;

  Future<void> loadSalesOrders() async {
    emit(const SalesOrderLoading());

    try {
      final orders = await _repository.getSalesOrders();

      emit(SalesOrderLoaded(orders));
    } catch (error) {
      emit(
        SalesOrderError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> loadSalesOrderDetails(int orderId) async {
    emit(const SalesOrderLoading());

    try {
      final order = await _repository.getSalesOrderDetails(
        orderId,
      );

      final lines = await _repository.getSalesOrderLines(
        order.lineIds,
      );

      final orderWithLines = order.copyWith(
        lines: lines,
      );

      emit(
        SalesOrderDetailsLoaded(
          orderWithLines,
        ),
      );
    } catch (error) {
      emit(
        SalesOrderError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> confirmSalesOrder(int orderId) async {
    try {
      await _repository.confirmSalesOrder(orderId);

      await loadSalesOrderDetails(orderId);
    } catch (error) {
      emit(
        SalesOrderError(
          error.toString(),
        ),
      );
    }
  }
}