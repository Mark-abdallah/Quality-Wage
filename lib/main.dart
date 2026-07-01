import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_state.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const QualityApp(),
    ),
  );
}

class QualityApp extends StatelessWidget {
  const QualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    const seed = Color(0xFF0D47A1);
    return MaterialApp(
      title: 'Quality',
      debugShowCheckedModeBanner: false,
      locale: state.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        appBarTheme: const AppBarTheme(centerTitle: false),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: state.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const HomeShell(),
    );
  }
}
