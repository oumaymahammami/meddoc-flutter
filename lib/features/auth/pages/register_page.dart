import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Nom complet')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Téléphone')),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/role'),
                child: const Text("S'inscrire"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
