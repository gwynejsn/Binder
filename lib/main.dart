import 'package:binder/screens/main_navigation.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(const BinderApp());
}

class BinderApp extends StatelessWidget {
  const BinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Binder",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: MainNavigation(),
    );
  }
}
