import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/odoo_client.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess({
    required this.isInternalUser,
  });

  final bool isInternalUser;
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required OdooClient odooClient,
  })  : _odooClient = odooClient,
        super(const AuthInitial());

  static const _database = 'sales-app-demo';

  final OdooClient _odooClient;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      await _odooClient.authenticate(
        database: _database,
        username: username,
        password: password,
      );

      final uid = _odooClient.uid;

      if (uid == null) {
        throw Exception('Failed to get Odoo user ID');
      }

      final result = await _odooClient.executeKw(
        database: _database,
        model: 'res.users',
        method: 'read',
        args: [
          [uid],
        ],
        kwargs: {
          'fields': ['group_ids'],
        },
      );

      final isInternalUser = _isInternalUser(result);

      emit(
        AuthSuccess(
          isInternalUser: isInternalUser,
        ),
      );
    } catch (error) {
      emit(
        AuthError(
          error.toString(),
        ),
      );
    }
  }

  bool _isInternalUser(Object? result) {
    if (result is! List || result.isEmpty) {
      throw Exception('Failed to load user permissions');
    }

    final user = result.first;

    if (user is! Map) {
      throw Exception('Invalid user response');
    }

    final groups = user['group_ids'];

    if (groups is! List) {
      return false;
    }

    return groups.whereType<num>().isNotEmpty;
  }
}