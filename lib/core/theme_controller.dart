import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o tema claro/escuro e persiste a escolha no dispositivo.
class ThemeController extends ChangeNotifier {
  static const _chave = 'tema_escuro';

  bool _escuro = false;

  bool get escuro => _escuro;

  ThemeMode get modo => _escuro ? ThemeMode.dark : ThemeMode.light;

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _escuro = prefs.getBool(_chave) ?? false;
    notifyListeners();
  }

  Future<void> definirEscuro(bool valor) async {
    if (_escuro == valor) return;
    _escuro = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chave, valor);
  }

  Future<void> alternar() => definirEscuro(!_escuro);
}

/// Disponibiliza o [ThemeController] para toda a árvore de widgets.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
}
