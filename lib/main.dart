import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/screens/main_navigation.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() async {
  // sabi dito
  // https: //stackoverflow.com/questions/72991163/unhandled-exception-binding-has-not-yet-been-initialized
  // need daw to?
  WidgetsFlutterBinding.ensureInitialized();
  // preload sa in-memory
  // ginawa nating static yung binder and todo lists in their
  // respective controllers so that isang instance lang nila yung meron
  // na accessible everywhere
  await BinderController().loadBinders();
  await TodoController().loadTodos();
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
