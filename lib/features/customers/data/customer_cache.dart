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

    final decoded = _decodeList(cachedData);

    if (decoded == null) {
      return [];
    }

    return decoded
        .map(
          (customer) => Customer.fromMap(customer),
    )
        .toList();
  }

  Future<void> savePendingPhoneUpdate({
    required int customerId,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final pendingData = prefs.getString(_pendingUpdatesKey);
    final updates = _decodeList(pendingData) ?? [];

    updates.removeWhere(
          (update) => update['customerId'] == customerId,
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

    return _decodeList(pendingData) ?? [];
  }

  Future<void> clearPendingPhoneUpdate(int customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingData = prefs.getString(_pendingUpdatesKey);

    if (pendingData == null) {
      return;
    }

    final updates = _decodeList(pendingData);

    if (updates == null) {
      return;
    }

    updates.removeWhere(
          (update) => update['customerId'] == customerId,
    );

    await prefs.setString(
      _pendingUpdatesKey,
      jsonEncode(updates),
    );
  }

  List<Map<String, dynamic>>? _decodeList(String? data) {
    if (data == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(data);

      if (decoded is! List) {
        return null;
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    } on FormatException {
      return null;
    }
  }
}