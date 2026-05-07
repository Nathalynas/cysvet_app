import 'package:flutter/material.dart';

import '../../../../app/theme.dart'; 

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.redirectTo = '/login',
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView( 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 260,
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(
                      width: 28, 
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
