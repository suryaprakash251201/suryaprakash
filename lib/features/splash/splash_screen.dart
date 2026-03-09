import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/navigation/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or whatever matches your theme
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 250, // Adjust size as needed
          height: 250,
        ),
      ),
    );
  }
}
