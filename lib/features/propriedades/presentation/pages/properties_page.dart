import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Lista de propriedades atendidas.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
