import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/network/odoo_client.dart';
import 'customer_cache.dart';
import 'customer_model.dart';

class CustomerRepository {
  CustomerRepository({
    required OdooClient odooClient,
    required String database,
    CustomerCache? cache,
    Connectivity? connectivity,
  })  : _odooClient = odooClient,
        _database = database,
        _cache = cache ?? CustomerCache(),
        _connectivity = connectivity ?? Connectivity() {
    _startConnectivitySync();
  }

  final OdooClient _odooClient;
  final String _database;
  final CustomerCache _cache;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();

    return results.any(
          (result) => result != ConnectivityResult.none,
    );
  }

  void _startConnectivitySync() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
              (results) {
            final isOnline = results.any(
                  (result) => result != ConnectivityResult.none,
            );

            if (isOnline) {
              unawaited(syncPendingPhoneUpdates());
            }
          },
        );
  }

  Future<List<Customer>> getCustomers({
    String? search,
  }) async {
    final query = search?.trim();

    if (!await _isOnline()) {
      return _getFromCache(search: query);
    }

    try {
      final customers = await _getFromOdoo(
        search: query,
      );

      if (query == null || query.isEmpty) {
        await _cache.saveCustomers(customers);
      }

      return customers;
    } catch (_) {
      final cachedCustomers = await _getFromCache(
        search: query,
      );

      if (cachedCustomers.isNotEmpty) {
        return cachedCustomers;
      }

      rethrow;
    }
  }

  Future<List<Customer>> _getFromOdoo({
    String? search,
  }) async {
    final domain = <Object?>[
      ['customer_rank', '>', 0],
    ];

    if (search != null && search.isNotEmpty) {
      domain.add([
        'name',
        'ilike',
        search,
      ]);
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

  Future<List<Customer>> _getFromCache({
    String? search,
  }) async {
    final customers = await _cache.getCachedCustomers();

    if (search == null || search.isEmpty) {
      return customers;
    }

    final query = search.toLowerCase();

    return customers
        .where(
          (customer) =>
          customer.name.toLowerCase().contains(query),
    )
        .toList();
  }

  Future<Customer> getCustomerDetails(
      int customerId,
      ) async {
    if (!await _isOnline()) {
      return _getCachedCustomer(customerId);
    }

    try {
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

      final customerModel = Customer.fromMap(
        Map<String, dynamic>.from(customer),
      );

      await _updateCachedCustomer(customerModel);

      return customerModel;
    } catch (_) {
      return _getCachedCustomer(customerId);
    }
  }

  Future<Customer> _getCachedCustomer(
      int customerId,
      ) async {
    final customers = await _cache.getCachedCustomers();

    for (final customer in customers) {
      if (customer.id == customerId) {
        return customer;
      }
    }

    throw Exception('Customer not available offline');
  }

  Future<void> updateCustomerPhone({
    required int customerId,
    required String phone,
  }) async {
    if (!await _isOnline()) {
      await _saveOfflinePhoneUpdate(
        customerId: customerId,
        phone: phone,
      );
      return;
    }

    try {
      await _updatePhoneOnOdoo(
        customerId: customerId,
        phone: phone,
      );

      await _updateCachePhone(
        customerId: customerId,
        phone: phone,
      );

      await _cache.clearPendingPhoneUpdate(customerId);
    } catch (_) {
      await _saveOfflinePhoneUpdate(
        customerId: customerId,
        phone: phone,
      );

      rethrow;
    }
  }

  Future<void> _saveOfflinePhoneUpdate({
    required int customerId,
    required String phone,
  }) async {
    await _updateCachePhone(
      customerId: customerId,
      phone: phone,
    );

    await _cache.savePendingPhoneUpdate(
      customerId: customerId,
      phone: phone,
    );
  }

  Future<void> _updatePhoneOnOdoo({
    required int customerId,
    required String phone,
  }) async {
    final result = await _odooClient.executeKw(
      database: _database,
      model: 'res.partner',
      method: 'write',
      args: [
        [customerId],
        {'phone': phone},
      ],
    );

    if (result != true) {
      throw Exception(
        'Failed to update customer phone',
      );
    }
  }

  Future<void> _updateCachePhone({
    required int customerId,
    required String phone,
  }) async {
    final customers = await _cache.getCachedCustomers();

    final updatedCustomers = customers.map(
          (customer) {
        if (customer.id != customerId) {
          return customer;
        }

        return Customer(
          id: customer.id,
          name: customer.name,
          phone: phone,
          email: customer.email,
          street: customer.street,
          street2: customer.street2,
          city: customer.city,
          zip: customer.zip,
          state: customer.state,
          country: customer.country,
        );
      },
    ).toList();

    await _cache.saveCustomers(updatedCustomers);
  }

  Future<void> _updateCachedCustomer(
      Customer updatedCustomer,
      ) async {
    final customers = await _cache.getCachedCustomers();

    final exists = customers.any(
          (customer) => customer.id == updatedCustomer.id,
    );

    if (!exists) {
      return;
    }

    final updatedCustomers = customers.map(
          (customer) {
        if (customer.id != updatedCustomer.id) {
          return customer;
        }

        return updatedCustomer;
      },
    ).toList();

    await _cache.saveCustomers(updatedCustomers);
  }

  Future<void> syncPendingPhoneUpdates() async {
    if (!await _isOnline()) {
      return;
    }

    final pendingUpdates =
    await _cache.getPendingPhoneUpdates();

    for (final update in pendingUpdates) {
      final customerId = update['customerId'];
      final phone = update['phone'];

      if (customerId is! num || phone is! String) {
        continue;
      }

      final id = customerId.toInt();

      try {
        await _updatePhoneOnOdoo(
          customerId: id,
          phone: phone,
        );

        await _cache.clearPendingPhoneUpdate(id);
      } catch (_) {
      }
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
  }
}