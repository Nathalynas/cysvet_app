
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class AnimalsPage extends StatelessWidget {
  const AnimalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Text('Animais'),
        ),
      ),
    );
  }
}