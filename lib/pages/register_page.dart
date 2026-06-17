import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nome = TextEditingController();

  final email = TextEditingController();

  final senha = TextEditingController();

  final auth = AuthService();

  void cadastrar() async {
    try {
      await auth.register(nome.text, email.text, senha.text);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Conta criada")));

      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar conta")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: nome,

              decoration: const InputDecoration(
                labelText: "Nome",

                prefixIcon: Icon(Icons.person),
              ),
            ),

            TextField(
              controller: email,

              decoration: const InputDecoration(
                labelText: "Email",

                prefixIcon: Icon(Icons.email),
              ),
            ),

            TextField(
              controller: senha,

              obscureText: true,

              decoration: const InputDecoration(
                labelText: "Senha",

                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: cadastrar,

              child: const Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );
  }
}
