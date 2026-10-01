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
      id: map['id'] as int,
      name: _toString(map['name']),
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

  static String _toString(dynamic value) {
    if (value == null || value == false) {
      return '';
    }

    return value.toString();
  }

  static String? _toNullableString(dynamic value) {
    if (value == null || value == false) {
      return null;
    }

    final stringValue = value.toString().trim();

    if (stringValue.isEmpty) {
      return null;
    }

    return stringValue;
  }

  static String? _many2OneName(dynamic value) {
    if (value is List && value.length > 1) {
      final name = value[1];

      if (name == null || name == false) {
        return null;
      }

      return name.toString();
    }

    return null;
  }
}