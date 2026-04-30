import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Informações do usuário e status da sincronização.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
