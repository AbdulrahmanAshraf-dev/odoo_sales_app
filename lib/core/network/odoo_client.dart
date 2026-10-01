import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

class OdooClient {
  OdooClient({
    required String baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _dio = dio ?? Dio();

  static const _commonEndpoint = '/xmlrpc/2/common';
  static const _objectEndpoint = '/xmlrpc/2/object';

  final String _baseUrl;
  final Dio _dio;

  int? _uid;
  String? _password;

  int? get uid => _uid;

  bool get isAuthenticated => _uid != null && _password != null;

  Future<int> authenticate({
    required String database,
    required String username,
    required String password,
  }) async {
    final requestXml = _buildMethodCall(
      method: 'authenticate',
      params: [
        database,
        username,
        password,
        <String, dynamic>{},
      ],
    );

    final responseXml = await _post(
      endpoint: _commonEndpoint,
      body: requestXml,
    );

    final result = _extractResponseValue(responseXml);

    if (result is int && result > 0) {
      _uid = result;
      _password = password;

      return result;
    }

    if (result == false || result == 0 || result == null) {
      throw Exception('Invalid Odoo credentials');
    }

    throw Exception('Odoo authentication failed');
  }

  Future<Object?> executeKw({
    required String database,
    required String model,
    required String method,
    List<Object?> args = const [],
    Map<String, Object?> kwargs = const {},
  }) async {
    final uid = _uid;
    final password = _password;

    if (uid == null || password == null) {
      throw Exception('User is not authenticated');
    }

    final requestXml = _buildMethodCall(
      method: 'execute_kw',
      params: [
        database,
        uid,
        password,
        model,
        method,
        args,
        kwargs,
      ],
    );

    final responseXml = await _post(
      endpoint: _objectEndpoint,
      body: requestXml,
    );

    return _extractResponseValue(responseXml);
  }

  Future<String> _post({
    required String endpoint,
    required String body,
  }) async {
    final response = await _dio.post<String>(
      '$_baseUrl$endpoint',
      data: body,
      options: Options(
        contentType: 'text/xml',
        responseType: ResponseType.plain,
      ),
    );

    final responseBody = response.data;

    if (responseBody == null || responseBody.isEmpty) {
      throw Exception('Empty response from Odoo');
    }

    return responseBody;
  }

  static String _buildMethodCall({
    required String method,
    required List<Object?> params,
  }) {
    final paramsXml = params
        .map(
          (param) => '''
<param>
  <value>${_buildValue(param)}</value>
</param>
''',
    )
        .join();

    return '''
<?xml version="1.0"?>
<methodCall>
  <methodName>${_escapeXml(method)}</methodName>
  <params>
    $paramsXml
  </params>
</methodCall>
''';
  }

  static String _buildValue(Object? value) {
    switch (value) {
      case null:
        return '<nil/>';

      case String():
        return '<string>${_escapeXml(value)}</string>';

      case bool():
        return '<boolean>${value ? '1' : '0'}</boolean>';

      case int():
        return '<int>$value</int>';

      case double():
        return '<double>$value</double>';

      case List<Object?>():
        return _buildArray(value);

      case Map<String, Object?>():
        return _buildStruct(value);

      default:
        throw ArgumentError(
          'Unsupported XML-RPC value: ${value.runtimeType}',
        );
    }
  }

  static String _buildArray(List<Object?> values) {
    final items = values
        .map(
          (value) => '<value>${_buildValue(value)}</value>',
    )
        .join();

    return '''
<array>
  <data>
    $items
  </data>
</array>
''';
  }

  static String _buildStruct(Map<String, Object?> values) {
    final members = values.entries
        .map(
          (entry) => '''
<member>
  <name>${_escapeXml(entry.key)}</name>
  <value>${_buildValue(entry.value)}</value>
</member>
''',
    )
        .join();

    return '''
<struct>
  $members
</struct>
''';
  }

  static Object? _extractResponseValue(String responseBody) {
    final document = XmlDocument.parse(responseBody);

    final faults = document.findAllElements('fault');

    if (faults.isNotEmpty) {
      throw Exception(
        'Odoo RPC error: ${faults.first.innerText.trim()}',
      );
    }

    final params = document.findAllElements('params');

    if (params.isEmpty) {
      throw Exception('Invalid Odoo response');
    }

    final param = params.first.findElements('param');

    if (param.isEmpty) {
      throw Exception('Invalid Odoo response');
    }

    final value = param.first.findElements('value');

    if (value.isEmpty) {
      throw Exception('Invalid Odoo response');
    }

    return _parseValue(value.first);
  }

  static Object? _parseValue(XmlElement value) {
    final element = value.children.whereType<XmlElement>().firstOrNull;

    if (element == null) {
      return null;
    }

    switch (element.name.local) {
      case 'string':
        return element.innerText;

      case 'int':
      case 'i4':
        return int.tryParse(element.innerText.trim());

      case 'boolean':
        return element.innerText.trim() == '1';

      case 'double':
        return double.tryParse(element.innerText.trim());

      case 'array':
        return _parseArray(element);

      case 'struct':
        return _parseStruct(element);

      case 'nil':
        return null;

      default:
        return element.innerText;
    }
  }

  static List<Object?> _parseArray(XmlElement element) {
    final data = element.findElements('data').firstOrNull;

    if (data == null) {
      return [];
    }

    return data
        .findElements('value')
        .map(_parseValue)
        .toList();
  }

  static Map<String, Object?> _parseStruct(XmlElement element) {
    final result = <String, Object?>{};

    for (final member in element.findElements('member')) {
      final name = member.findElements('name').firstOrNull;
      final value = member.findElements('value').firstOrNull;

      if (name == null || value == null) {
        continue;
      }

      result[name.innerText] = _parseValue(value);
    }

    return result;
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}