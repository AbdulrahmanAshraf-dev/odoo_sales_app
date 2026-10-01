import '../../../core/network/odoo_client.dart';
import 'sales_order_model.dart';

class SalesOrderRepository {
  SalesOrderRepository({
    required OdooClient odooClient,
    required String database,
  })  : _odooClient = odooClient,
        _database = database;

  static const _salesOrderFields = [
    'id',
    'name',
    'partner_id',
    'date_order',
    'state',
  ];

  static const _salesOrderDetailsFields = [
    'id',
    'name',
    'partner_id',
    'date_order',
    'state',
    'order_line',
    'amount_untaxed',
    'amount_tax',
    'amount_total',
  ];

  static const _salesOrderLineFields = [
    'id',
    'order_id',
    'product_id',
    'product_uom_qty',
    'price_unit',
    'price_subtotal',
  ];

  final OdooClient _odooClient;
  final String _database;

  Future<List<SalesOrder>> getSalesOrders() async {
    final result = await _odooClient.executeKw(
      database: _database,
      model: 'sale.order',
      method: 'search_read',
      args: [
        [],
      ],
      kwargs: {
        'fields': _salesOrderFields,
      },
    );

    if (result is! List) {
      throw Exception('Invalid sales orders response');
    }

    return result
        .whereType<Map>()
        .map(
          (order) => SalesOrder.fromMap(
        Map<String, dynamic>.from(order),
      ),
    )
        .toList();
  }

  Future<SalesOrder> getSalesOrderDetails(int orderId) async {
    final result = await _odooClient.executeKw(
      database: _database,
      model: 'sale.order',
      method: 'read',
      args: [
        [orderId],
      ],
      kwargs: {
        'fields': _salesOrderDetailsFields,
      },
    );

    if (result is! List || result.isEmpty) {
      throw Exception('Sales order not found');
    }

    final order = result.first;

    if (order is! Map) {
      throw Exception('Invalid sales order response');
    }

    return SalesOrder.fromMap(
      Map<String, dynamic>.from(order),
    );
  }

  Future<List<SalesOrderLine>> getSalesOrderLines(
      List<int> lineIds,
      ) async {
    if (lineIds.isEmpty) {
      return [];
    }

    final result = await _odooClient.executeKw(
      database: _database,
      model: 'sale.order.line',
      method: 'read',
      args: [
        lineIds,
      ],
      kwargs: {
        'fields': _salesOrderLineFields,
      },
    );

    if (result is! List) {
      throw Exception('Invalid sales order lines response');
    }

    return result
        .whereType<Map>()
        .map(
          (line) => SalesOrderLine.fromMap(
        Map<String, dynamic>.from(line),
      ),
    )
        .toList();
  }

  Future<void> confirmSalesOrder(int orderId) async {
    final result = await _odooClient.executeKw(
      database: _database,
      model: 'sale.order',
      method: 'action_confirm',
      args: [
        [orderId],
      ],
      kwargs: const {},
    );

    if (result != true) {
      throw Exception('Failed to confirm sales order');
    }
  }
}