import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();

  final senha = TextEditingController();

  final auth = AuthService();

  void entrar() async {
    try {
      await auth.login(email.text, senha.text);

      Navigator.pushReplacementNamed(context, "/produtos");
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login inválido")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),

      body: Padding(
        padding: EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: email,

              decoration: InputDecoration(labelText: "Email"),
            ),

            TextField(
              controller: senha,

              obscureText: true,

              decoration: InputDecoration(labelText: "Senha"),
            ),

            ElevatedButton(onPressed: entrar, child: Text("Entrar")),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },

              child: const Text("Criar conta"),
            ),
          ],
        ),
      ),
    );
  }
}
