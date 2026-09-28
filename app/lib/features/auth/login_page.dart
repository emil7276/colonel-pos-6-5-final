import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../models/models.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();

  Future<void> login() async {
    try {
      final u = await DB.login(
        user.text.trim(),
        pass.text,
      );

      if (!mounted) return;

      if (u == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Username atau password salah.',
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            username: u['username'] as String,
            role: u['role'] as String,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login gagal: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 70,
                      color: red,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'COLONEL FRIED CHICKEN',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text('POS V6.5 • Professional'),
                    const SizedBox(height: 25),
                    TextField(
                      controller: user,
                      decoration:
                          const InputDecoration(
                        labelText: 'Username',
                        prefixIcon:
                            Icon(Icons.person),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pass,
                      obscureText: true,
                      decoration:
                          const InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                            Icon(Icons.lock),
                        border:
                            OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => login(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: login,
                        style:
                            FilledButton.styleFrom(
                          backgroundColor: red,
                        ),
                        child:
                            const Text('MASUK'),
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
