import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'customer_model.dart';

class CustomerCache {
  static const _customersKey = 'cached_customers';
  static const _pendingUpdatesKey = 'pending_customer_updates';

  Future<void> saveCustomers(List<Customer> customers) async {
    final prefs = await SharedPreferences.getInstance();

    final data = customers
        .map(
          (customer) => {
        'id': customer.id,
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'street': customer.street,
        'street2': customer.street2,
        'city': customer.city,
        'zip': customer.zip,
        'state': customer.state,
        'country': customer.country,
      },
    )
        .toList();

    await prefs.setString(
      _customersKey,
      jsonEncode(data),
    );
  }

  Future<List<Customer>> getCachedCustomers() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(_customersKey);

    if (cachedData == null) {
      return [];
    }

    final decoded = jsonDecode(cachedData);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (customer) => Customer.fromMap(
        Map<String, dynamic>.from(customer),
      ),
    )
        .toList();
  }

  Future<void> savePendingPhoneUpdate({
    required int customerId,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final pendingData = prefs.getString(_pendingUpdatesKey);

    List<dynamic> updates = [];

    if (pendingData != null) {
      final decoded = jsonDecode(pendingData);

      if (decoded is List) {
        updates = decoded;
      }
    }

    updates.removeWhere(
          (update) =>
      update is Map &&
          update['customerId'] == customerId,
    );

    updates.add({
      'customerId': customerId,
      'phone': phone,
    });

    await prefs.setString(
      _pendingUpdatesKey,
      jsonEncode(updates),
    );
  }

  Future<List<Map<String, dynamic>>> getPendingPhoneUpdates() async {
    final prefs = await SharedPreferences.getInstance();

    final pendingData = prefs.getString(_pendingUpdatesKey);

    if (pendingData == null) {
      return [];
    }

    final decoded = jsonDecode(pendingData);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (update) => Map<String, dynamic>.from(update),
    )
        .toList();
  }

  Future<void> clearPendingPhoneUpdate(int customerId) async {
    final prefs = await SharedPreferences.getInstance();

    final pendingData = prefs.getString(_pendingUpdatesKey);

    if (pendingData == null) {
      return;
    }

    final decoded = jsonDecode(pendingData);

    if (decoded is! List) {
      return;
    }

    decoded.removeWhere(
          (update) =>
      update is Map &&
          update['customerId'] == customerId,
    );

    await prefs.setString(
      _pendingUpdatesKey,
      jsonEncode(decoded),
    );
  }
}