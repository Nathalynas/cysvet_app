import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class VisitsPage extends StatelessWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Fluxo de visitas técnicas em campo.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
