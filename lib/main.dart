import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/database/app_database.dart';
import 'data/supabase/supabase_servico.dart';
import 'ui/widgets/app_shell.dart';
import 'ui/widgets/navegacao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initializeFfiIfNeeded();
  // Conecta ao Supabase; se falhar, o app segue com o SQLite local.
  await SupabaseServico.inicializar();
  runApp(const SindicoApp());
}

/// Comportamento de rolagem com suporte a mouse/trackpad (web e desktop).
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// Aplicação Flutter para Síndicos do Condomínio Evaristo Lucchese.
class SindicoApp extends StatelessWidget {
  const SindicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Síndico • Evaristo Lucchese',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Azul formal e profissional
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFF0D47A1),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 1,
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 1.5,
          color: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          insetPadding: const EdgeInsets.all(16),
        ),
        tooltipTheme: TooltipThemeData(
          waitDuration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        navigationRailTheme: NavigationRailThemeData(
          indicatorColor: const Color(0xFF1565C0).withValues(alpha: 0.14),
          selectedIconTheme: const IconThemeData(color: Color(0xFF1565C0)),
          unselectedIconTheme: IconThemeData(color: Colors.grey.shade700),
          selectedLabelTextStyle: const TextStyle(
            color: Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade700),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade300,
          thickness: 1,
          space: 1,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const AppLayout(secaoInicial: DestinoApp.competencias),
    );
  }
}
