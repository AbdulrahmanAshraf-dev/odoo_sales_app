import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/odoo_client.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  AuthSuccess({
    required this.isInternalUser,
  });

  final bool isInternalUser;
}

class AuthError extends AuthState {
  AuthError(this.message);

  final String message;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this.odooClient,
  }) : super(AuthInitial());

  final OdooClient odooClient;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      await odooClient.authenticate(
        database: 'sales-app-demo',
        username: username,
        password: password,
      );

      final result = await odooClient.executeKw(
        database: 'sales-app-demo',
        model: 'res.users',
        method: 'read',
        args: [
          [odooClient.uid],
        ],
        kwargs: {
          'fields': ['group_ids'],
        },
      );

      if (result is! List || result.isEmpty) {
        throw Exception('Failed to load user permissions');
      }

      final user = result.first;

      if (user is! Map) {
        throw Exception('Invalid user response');
      }

      final groups = user['group_ids'];

      final groupIds = groups is List
          ? groups.whereType<num>().map((id) => id.toInt()).toList()
          : <int>[];

      final isInternalUser = groupIds.isNotEmpty;

      emit(
        AuthSuccess(
          isInternalUser: isInternalUser,
        ),
      );
    } catch (e) {
      emit(
        AuthError(
          e.toString(),
        ),
      );
    }
  }
}