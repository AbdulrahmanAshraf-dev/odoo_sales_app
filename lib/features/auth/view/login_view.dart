import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../customers/data/customer_repo.dart';
import '../../home/view/home_view.dart';
import '../../sales_order/data/sales_order_repo.dart';
import '../cubit/auth_cubit.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    required CustomerRepository customerRepository,
    required SalesOrderRepository salesOrderRepository,
    super.key,
  })  : _customerRepository = customerRepository,
        _salesOrderRepository = salesOrderRepository;

  final CustomerRepository _customerRepository;
  final SalesOrderRepository _salesOrderRepository;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthCubit>().login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  void _handleAuthSuccess(AuthSuccess state) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeView(
          customerRepository: widget._customerRepository,
          salesOrderRepository: widget._salesOrderRepository,
          isInternalUser: state.isInternalUser,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (!context.mounted) {
              return;
            }

            switch (state) {
              case AuthSuccess():
                _handleAuthSuccess(state);

              case AuthError():
                _showError(state.message);

              case AuthInitial():
              case AuthLoading():
                break;
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) {
                      if (!isLoading) {
                        _login();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      child: isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}