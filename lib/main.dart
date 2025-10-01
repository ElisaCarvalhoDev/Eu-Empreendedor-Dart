import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'tela_login.dart';
import 'firebase_options.dart';

// Localizações para o DatePicker funcionar
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase inicializado com sucesso.");
  } catch (e) {
    print("Erro ao inicializar Firebase: $e");
    return; // Evita que o app rode sem inicialização
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oportunidades',

      // Delegates necessários para o calendário funcionar
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('pt', 'BR'), // português Brasil
        Locale('en', 'US'), // inglês
      ],

      home: TelaLogin(),
    );
  }
}
