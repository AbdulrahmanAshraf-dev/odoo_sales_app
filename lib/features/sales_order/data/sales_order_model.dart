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
      id: _toInt(map['id']),
      name: _toString(map['name']),
      customerName: _many2OneName(map['partner_id']) ?? '',
      orderDate: _toString(map['date_order']),
      status: _toString(map['state']),
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
      id: _toInt(map['id']),
      productName: _many2OneName(map['product_id']) ?? '',
      quantity: _toDouble(map['product_uom_qty']) ?? 0,
      unitPrice: _toDouble(map['price_unit']) ?? 0,
      subtotal: _toDouble(map['price_subtotal']) ?? 0,
    );
  }
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  throw FormatException(
    'Invalid integer value: $value',
  );
}

String _toString(Object? value) {
  if (value == null || value == false) {
    return '';
  }

  return value.toString().trim();
}

String? _many2OneName(Object? value) {
  if (value is! List || value.length < 2) {
    return null;
  }

  final name = value[1];

  if (name == null || name == false) {
    return null;
  }

  final stringValue = name.toString().trim();

  return stringValue.isEmpty ? null : stringValue;
}

List<int> _toIntList(Object? value) {
  if (value is! List) {
    return [];
  }

  return value
      .whereType<num>()
      .map((id) => id.toInt())
      .toList();
}

double? _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value == null || value == false) {
    return null;
  }

  return double.tryParse(value.toString().trim());
}