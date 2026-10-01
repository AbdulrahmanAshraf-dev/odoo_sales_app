import '../../../core/network/odoo_client.dart';
import 'customer_model.dart';

class CustomerRepository {
  CustomerRepository({
    required this._odooClient,
    required this._database,
  });

  final OdooClient _odooClient;
  final String _database;

  Future<List<Customer>> getCustomers({
    String? search,
  }) async {
    final domain = <dynamic>[
      ['customer_rank', '>', 0],
    ];

    if (search != null && search.trim().isNotEmpty) {
      domain.add(
        ['name', 'ilike', search.trim()],
      );
    }

    final result = await _odooClient.executeKw(
      database: _database,
      model: 'res.partner',
      method: 'search_read',
      args: [domain],
      kwargs: {
        'fields': [
          'id',
          'name',
          'phone',
          'city',
        ],
      },
    );

    if (result is! List) {
      throw Exception('Invalid customers response');
    }

    return result
        .whereType<Map>()
        .map(
          (customer) => Customer.fromMap(
        Map<String, dynamic>.from(customer),
      ),
    )
        .toList();
  }

  Future<Customer> getCustomerDetails(int customerId) async {
    final result = await _odooClient.executeKw(
      database: _database,
      model: 'res.partner',
      method: 'read',
      args: [
        [customerId],
      ],
      kwargs: {
        'fields': [
          'id',
          'name',
          'phone',
          'email',
          'street',
          'street2',
          'city',
          'zip',
          'state_id',
          'country_id',
        ],
      },
    );

    if (result is! List || result.isEmpty) {
      throw Exception('Customer not found');
    }

    final customer = result.first;

    if (customer is! Map) {
      throw Exception('Invalid customer response');
    }

    return Customer.fromMap(
      Map<String, dynamic>.from(customer),
    );
  }

  Future<void> updateCustomerPhone({
    required int customerId,
    required String phone,
  }) async {
    final result = await _odooClient.executeKw(
      database: _database,
      model: 'res.partner',
      method: 'write',
      args: [
        [customerId],
        {
          'phone': phone,
        },
      ],
    );

    if (result != true) {
      throw Exception('Failed to update customer phone');
    }
  }
}