class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.street,
    this.street2,
    this.city,
    this.zip,
    this.state,
    this.country,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? street;
  final String? street2;
  final String? city;
  final String? zip;
  final String? state;
  final String? country;

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: _toInt(map['id']),
      name: _toRequiredString(map['name']),
      phone: _toNullableString(map['phone']),
      email: _toNullableString(map['email']),
      street: _toNullableString(map['street']),
      street2: _toNullableString(map['street2']),
      city: _toNullableString(map['city']),
      zip: _toNullableString(map['zip']),
      state: _many2OneName(map['state_id']),
      country: _many2OneName(map['country_id']),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    throw FormatException(
      'Invalid customer ID: $value',
    );
  }

  static String _toRequiredString(Object? value) {
    if (value == null || value == false) {
      return '';
    }

    return value.toString().trim();
  }

  static String? _toNullableString(Object? value) {
    if (value == null || value == false) {
      return null;
    }

    final stringValue = value.toString().trim();

    return stringValue.isEmpty ? null : stringValue;
  }

  static String? _many2OneName(Object? value) {
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
}