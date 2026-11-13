import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme_controller.dart';
import 'data/database/app_database.dart';
import 'data/supabase/supabase_servico.dart';
import 'ui/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initializeFfiIfNeeded();
  // Conecta ao Supabase; se falhar, o app segue com o SQLite local.
  await SupabaseServico.inicializar();

  final themeController = ThemeController();
  await themeController.carregar();

  runApp(SindicoApp(themeController: themeController));
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
  final ThemeController themeController;

  const SindicoApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => ThemeScope(
        controller: themeController,
        child: MaterialApp(
          title: 'Síndico • Evaristo Lucchese',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const _AppScrollBehavior(),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: _criarTema(Brightness.light),
          darkTheme: _criarTema(Brightness.dark),
          themeMode: themeController.modo,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

ThemeData _criarTema(Brightness brightness) {
  final escuro = brightness == Brightness.dark;
  final esquema =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
        brightness: brightness,
      ).copyWith(
        primary: escuro ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
        secondary: escuro ? const Color(0xFF64B5F6) : const Color(0xFF0D47A1),
        surface: escuro ? const Color(0xFF121212) : Colors.white,
      );

  final corSuperficie = escuro ? const Color(0xFF1E1E1E) : Colors.white;
  final corSuperficieCampo = escuro ? const Color(0xFF262626) : Colors.white;
  final corBorda = escuro ? Colors.grey.shade700 : Colors.grey.shade400;
  final corBordaSuave = escuro ? Colors.grey.shade800 : Colors.grey.shade300;
  final corTextoSuave = escuro ? Colors.grey.shade400 : Colors.grey.shade700;
  final corDivisor = escuro ? Colors.grey.shade800 : Colors.grey.shade300;
  final corTitulo = escuro ? esquema.primary : const Color(0xFF0D47A1);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: esquema,
    scaffoldBackgroundColor: escuro ? const Color(0xFF121212) : null,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 1,
      backgroundColor: escuro
          ? const Color(0xFF1E1E1E)
          : const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(elevation: 1.5, color: corSuperficie),
    dialogTheme: DialogThemeData(
      backgroundColor: corSuperficie,
      surfaceTintColor: corSuperficie,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: corTitulo,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: corSuperficie,
      surfaceTintColor: corSuperficie,
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
      indicatorColor: esquema.primary.withValues(alpha: escuro ? 0.24 : 0.14),
      selectedIconTheme: IconThemeData(color: esquema.primary),
      unselectedIconTheme: IconThemeData(color: corTextoSuave),
      selectedLabelTextStyle: TextStyle(
        color: corTitulo,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: TextStyle(color: corTextoSuave),
    ),
    dividerTheme: DividerThemeData(color: corDivisor, thickness: 1, space: 1),
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
      fillColor: corSuperficieCampo,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: corBorda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: corBordaSuave),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: esquema.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
