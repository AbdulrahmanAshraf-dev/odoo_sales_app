import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

class OdooClient {
  OdooClient({
    required this._baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String _baseUrl;
  final Dio _dio;

  int? _uid;
  String? _password;

  int? get uid => _uid;

  Future<int> authenticate({
    required String database,
    required String username,
    required String password,
  }) async {
    final document = XmlDocument.parse('''
<?xml version="1.0"?>
<methodCall>
  <methodName>authenticate</methodName>
  <params>
    <param>
      <value>
        <string>${_escapeXml(database)}</string>
      </value>
    </param>
    <param>
      <value>
        <string>${_escapeXml(username)}</string>
      </value>
    </param>
    <param>
      <value>
        <string>${_escapeXml(password)}</string>
      </value>
    </param>
    <param>
      <value>
        <struct/>
      </value>
    </param>
  </params>
</methodCall>
''');

    final response = await _dio.post<String>(
      '$_baseUrl/xmlrpc/2/common',
      data: document.toXmlString(),
      options: Options(
        contentType: 'text/xml',
        responseType: ResponseType.plain,
      ),
    );

    final responseXml = XmlDocument.parse(response.data!);

    final intNodes = responseXml.findAllElements('int');

    if (intNodes.isNotEmpty) {
      final authenticatedUid =
      int.tryParse(intNodes.first.innerText);

      if (authenticatedUid != null && authenticatedUid > 0) {
        _uid = authenticatedUid;
        _password = password;

        return authenticatedUid;
      }
    }

    final booleanNodes = responseXml.findAllElements('boolean');

    if (booleanNodes.isNotEmpty &&
        booleanNodes.first.innerText.trim() == '0') {
      throw Exception('Invalid Odoo credentials');
    }

    throw Exception('Odoo authentication failed');
  }

  Future<dynamic> executeKw({
    required String database,
    required String model,
    required String method,
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    if (_uid == null || _password == null) {
      throw Exception('User is not authenticated');
    }

    final argsXml = _buildArray(args);
    final kwargsXml = _buildStruct(kwargs);

    final requestXml = '''
<?xml version="1.0"?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>

    <param>
      <value>
        <string>${_escapeXml(database)}</string>
      </value>
    </param>

    <param>
      <value>
        <int>$_uid</int>
      </value>
    </param>

    <param>
      <value>
        <string>${_escapeXml(_password!)}</string>
      </value>
    </param>

    <param>
      <value>
        <string>${_escapeXml(model)}</string>
      </value>
    </param>

    <param>
      <value>
        <string>${_escapeXml(method)}</string>
      </value>
    </param>

    <param>
      <value>
        $argsXml
      </value>
    </param>

    <param>
      <value>
        $kwargsXml
      </value>
    </param>

  </params>
</methodCall>
''';

    final response = await _dio.post<String>(
      '$_baseUrl/xmlrpc/2/object',
      data: requestXml,
      options: Options(
        contentType: 'text/xml',
        responseType: ResponseType.plain,
      ),
    );

    final responseXml = XmlDocument.parse(response.data!);

    final faults = responseXml.findAllElements('fault');

    if (faults.isNotEmpty) {
      throw Exception(faults.first.innerText.trim());
    }

    final params = responseXml.findAllElements('params');

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

  Future<bool> hasGroup({
    required String database,
    required String group,
  }) async {
    final result = await executeKw(
      database: database,
      model: 'res.users',
      method: 'has_group',
      args: [group],
      kwargs: {},
    );

    return result == true;
  }

  static String _buildArray(List<dynamic> values) {
    final items = values.map((value) {
      return '<value>${_buildValue(value)}</value>';
    }).join();

    return '''
<array>
  <data>
    $items
  </data>
</array>
''';
  }

  static String _buildStruct(Map<String, dynamic> values) {
    final members = values.entries.map((entry) {
      return '''
<member>
  <name>${_escapeXml(entry.key)}</name>
  <value>${_buildValue(entry.value)}</value>
</member>
''';
    }).join();

    return '''
<struct>
  $members
</struct>
''';
  }

  static String _buildValue(dynamic value) {
    if (value is String) {
      return '<string>${_escapeXml(value)}</string>';
    }

    if (value is int) {
      return '<int>$value</int>';
    }

    if (value is bool) {
      return '<boolean>${value ? '1' : '0'}</boolean>';
    }

    if (value is double) {
      return '<double>$value</double>';
    }

    if (value is List) {
      return _buildArray(value);
    }

    if (value is Map<String, dynamic>) {
      return _buildStruct(value);
    }

    throw ArgumentError(
      'Unsupported XML-RPC value: ${value.runtimeType}',
    );
  }

  static dynamic _parseValue(XmlElement value) {
    final elements = value.children.whereType<XmlElement>();

    if (elements.isEmpty) {
      return null;
    }

    final element = elements.first;

    switch (element.name.local) {
      case 'string':
        return element.innerText;

      case 'int':
      case 'i4':
        return int.tryParse(element.innerText);

      case 'boolean':
        return element.innerText.trim() == '1';

      case 'double':
        return double.tryParse(element.innerText);

      case 'array':
        final data = element.findElements('data');

        if (data.isEmpty) {
          return <dynamic>[];
        }

        return data.first
            .findElements('value')
            .map(_parseValue)
            .toList();

      case 'struct':
        final result = <String, dynamic>{};

        for (final member in element.findElements('member')) {
          final names = member.findElements('name');
          final values = member.findElements('value');

          if (names.isEmpty || values.isEmpty) {
            continue;
          }

          result[names.first.innerText] =
              _parseValue(values.first);
        }

        return result;

      default:
        return element.innerText;
    }
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