class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.name,
    required this.customerName,
    required this.orderDate,
    required this.status,
    this.amountUntaxed,
    this.amountTax,
    this.amountTotal,
    this.lines = const [],
    this.lineIds = const [],
  });

  final int id;
  final String name;
  final String customerName;
  final String orderDate;
  final String status;
  final double? amountUntaxed;
  final double? amountTax;
  final double? amountTotal;
  final List<SalesOrderLine> lines;
  final List<int> lineIds;

  factory SalesOrder.fromMap(Map<String, dynamic> map) {
    return SalesOrder(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      customerName: _many2OneName(map['partner_id']) ?? '',
      orderDate: map['date_order'] as String? ?? '',
      status: map['state'] as String? ?? '',
      amountUntaxed: _toDouble(map['amount_untaxed']),
      amountTax: _toDouble(map['amount_tax']),
      amountTotal: _toDouble(map['amount_total']),
      lineIds: _toIntList(map['order_line']),
    );
  }

  SalesOrder copyWith({
    List<SalesOrderLine>? lines,
  }) {
    return SalesOrder(
      id: id,
      name: name,
      customerName: customerName,
      orderDate: orderDate,
      status: status,
      amountUntaxed: amountUntaxed,
      amountTax: amountTax,
      amountTotal: amountTotal,
      lines: lines ?? this.lines,
      lineIds: lineIds,
    );
  }

  static String? _many2OneName(dynamic value) {
    if (value is List && value.length > 1) {
      return value[1]?.toString();
    }

    return null;
  }

  static List<int> _toIntList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<num>()
        .map((id) => id.toInt())
        .toList();
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}

class SalesOrderLine {
  const SalesOrderLine({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final int id;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  factory SalesOrderLine.fromMap(Map<String, dynamic> map) {
    return SalesOrderLine(
      id: map['id'] as int,
      productName: _many2OneName(map['product_id']) ?? '',
      quantity: _toDouble(map['product_uom_qty']) ?? 0,
      unitPrice: _toDouble(map['price_unit']) ?? 0,
      subtotal: _toDouble(map['price_subtotal']) ?? 0,
    );
  }

  static String? _many2OneName(dynamic value) {
    if (value is List && value.length > 1) {
      return value[1]?.toString();
    }

    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}