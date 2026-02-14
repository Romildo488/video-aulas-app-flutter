import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;

  Future<void> login() async {
    try {
      setState(() => carregando = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String erro = "Erro ao logar";

      if (e.code == 'user-not-found') {
        erro = "Usuário não encontrado";
      } else if (e.code == 'wrong-password') {
        erro = "Senha incorreta";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erro)));
    } finally {
      setState(() => carregando = false);
    }
  }

  Future<void> criarConta() async {
    try {
      setState(() => carregando = true);

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Erro")));
    } finally {
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login 🔐")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Senha"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: carregando ? null : login,
              child: carregando
                  ? const CircularProgressIndicator()
                  : const Text("Entrar"),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: carregando ? null : criarConta,
              child: const Text("Criar conta"),
            )
          ],
        ),
      ),
    );
  }
}
