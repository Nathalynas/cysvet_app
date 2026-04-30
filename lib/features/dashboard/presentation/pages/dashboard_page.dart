import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Visão geral dos indicadores reprodutivos.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
