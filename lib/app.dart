import 'package:flutter/material.dart';
import 'core/tokens.dart';
import 'features/auth/presentation/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Bienvenido',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class App extends StatelessWidget {
  final String initialRoute;
  const App({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Tokens.primary,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        filled: true, fillColor: Colors.white),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alerta Ciudadana',
      theme: base,
      initialRoute: initialRoute,
      routes: {
        '/': (_) => const LoginScreen(),
        '/home': (_) => const WelcomeScreen(),
      },
    );
  }
}
