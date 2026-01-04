import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisir un rôle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Vous êtes :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/patient'),
                icon: const Icon(Icons.person),
                label: const Text('Patient'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/doctor'),
                icon: const Icon(Icons.medical_services),
                label: const Text('Doctor'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
