import 'package:flutter/material.dart';
import '../services/api.dart';
import 'user_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final email = TextEditingController(text: "admin@gmail.com");
  final password = TextEditingController(text: "123456");
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text("Admin Login", style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: email,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (v) => v == null || v.isEmpty ? "Email is required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password"),
                      validator: (v) => v == null || v.isEmpty ? "Password is required" : null,
                    ),
                    const SizedBox(height: 12),
                    if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 4),
                    FilledButton(
                      onPressed: loading ? null : () async {
                        if (!_form.currentState!.validate()) return;
                        setState(() { loading = true; error = null; });
                        final result = await Api.login(email.text.trim(), password.text.trim());
                        if (result.$1) {
                          if (!mounted) return;
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UserListScreen()));
                        } else {
                          setState(() => error = result.$2);
                        }
                        setState(() => loading = false);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(loading ? "Signing in..." : "Sign in"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
