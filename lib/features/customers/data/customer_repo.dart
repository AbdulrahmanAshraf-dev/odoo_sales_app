import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/network/odoo_client.dart';
import 'customer_cache.dart';
import 'customer_model.dart';

class CustomerRepository {
  CustomerRepository({
    required this._odooClient,
    required this._database,
  }) {
    _startConnectivitySync();
  }

  final OdooClient _odooClient;
  final String _database;

  final CustomerCache _cache = CustomerCache();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();

    return results.any(
          (result) => result != ConnectivityResult.none,
    );
  }

  void _startConnectivitySync() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
          (results) {
        final isOnline = results.any(
              (result) => result != ConnectivityResult.none,
        );

        if (isOnline) {
          syncPendingPhoneUpdates();
        }
      },
    );
  }

  Future<List<Customer>> getCustomers({String? search}) async {
    final isOnline = await _isOnline();

    if (!isOnline) {
      return _getFromCache(search: search);
    }

    try {
      final customers = await _getFromOdoo(search: search);

      // Cache the complete customer list only.
      if (search == null || search.trim().isEmpty) {
        await _cache.saveCustomers(customers);
      }

      return customers;
    } catch (_) {
      // If Odoo is unavailable, fallback to cached data.
      final cachedCustomers = await _getFromCache(search: search);

      if (cachedCustomers.isNotEmpty) {
        return cachedCustomers;
      }

      rethrow;
    }
  }

  Future<List<Customer>> _getFromOdoo({
    String? search,
  }) async {
    final domain = <dynamic>[
      ['customer_rank', '>', 0],
    ];

    if (search != null && search.trim().isNotEmpty) {
      domain.add([
        'name',
        'ilike',
        search.trim(),
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

    if (search == null || search.trim().isEmpty) {
      return customers;
    }

    final query = search.trim().toLowerCase();

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
    final isOnline = await _isOnline();

    if (!isOnline) {
      final customers = await _cache.getCachedCustomers();

      final cachedCustomer = customers.where(
            (customer) => customer.id == customerId,
      );

      if (cachedCustomer.isNotEmpty) {
        return cachedCustomer.first;
      }

      throw Exception(
        'Customer not available offline',
      );
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
        throw Exception(
          'Invalid customer response',
        );
      }

      final customerModel = Customer.fromMap(
        Map<String, dynamic>.from(customer),
      );

      return customerModel;
    } catch (_) {
      final customers = await _cache.getCachedCustomers();

      final cachedCustomer = customers.where(
            (customer) => customer.id == customerId,
      );

      if (cachedCustomer.isNotEmpty) {
        return cachedCustomer.first;
      }

      rethrow;
    }
  }

  Future<void> updateCustomerPhone({
    required int customerId,
    required String phone,
  }) async {
    final isOnline = await _isOnline();

    if (!isOnline) {
      // Update local cache immediately.
      await _updateCachePhone(
        customerId: customerId,
        phone: phone,
      );

      await _cache.savePendingPhoneUpdate(
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

      // Remove any old pending update.
      await _cache.clearPendingPhoneUpdate(
        customerId,
      );
    } catch (_) {
      // If the request fails, keep the update locally.
      await _updateCachePhone(
        customerId: customerId,
        phone: phone,
      );

      await _cache.savePendingPhoneUpdate(
        customerId: customerId,
        phone: phone,
      );

      rethrow;
    }
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
        {
          'phone': phone,
        },
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

    await _cache.saveCustomers(
      updatedCustomers,
    );
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

      try {
        await _updatePhoneOnOdoo(
          customerId: customerId.toInt(),
          phone: phone,
        );

        await _cache.clearPendingPhoneUpdate(
          customerId.toInt(),
        );
      } catch (_) {
      }
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
  }
}