//amitabha/lib/features/auth/presentation/sign_in_out_button.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../auth/application/auth_facade.dart';

class SignInOutButton extends StatelessWidget {
  final AuthFacade facade;
  const SignInOutButton({super.key, required this.facade});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: facade.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        final isAnon = user?.isAnonymous ?? true;

        if (user == null || isAnon) {
          return FloatingActionButton.extended(
            onPressed: () async {
              final cred = await facade.signInWithGoogle();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已登入：${cred.user?.email ?? cred.user?.uid}')),
              );
            },
            label: const Text('登入'),
            icon: const Icon(Icons.login),
          );
        }

        return FloatingActionButton.extended(
          onPressed: () async {
            await facade.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已登出')),
            );
          },
          label: const Text('登出'),
          icon: const Icon(Icons.logout),
          backgroundColor: Colors.redAccent,
        );
      },
    );
  }
}