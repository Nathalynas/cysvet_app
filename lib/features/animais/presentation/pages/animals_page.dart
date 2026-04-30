import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AnimalsPage extends StatelessWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Lista de animais com busca e filtros.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
