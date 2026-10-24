import 'package:flutter/material.dart';
import '../../shared/screens/welcome_screen.dart';

/// Legacy login screen alias that forwards cleanly to the new animated WelcomeScreen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
