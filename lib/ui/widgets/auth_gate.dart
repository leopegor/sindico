import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import 'app_shell.dart';
import 'navegacao.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _chaveSessao = 'sessao_autenticada';

  bool? _autenticado;

  @override
  void initState() {
    super.initState();
    _carregarSessao();
  }

  Future<void> _carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _autenticado = prefs.getBool(_chaveSessao) ?? false);
  }

  Future<void> _entrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveSessao, true);
    if (!mounted) return;
    setState(() => _autenticado = true);
  }

  Future<void> _sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveSessao);
    if (!mounted) return;
    setState(() => _autenticado = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_autenticado == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_autenticado!) {
      return LoginScreen(onEntrar: _entrar);
    }

    return AuthScope(
      sair: _sair,
      child: const AppLayout(secaoInicial: DestinoApp.competencias),
    );
  }
}

class AuthScope extends InheritedWidget {
  final VoidCallback sair;

  const AuthScope({
    super.key,
    required this.sair,
    required super.child,
  });

  static AuthScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>();

  @override
  bool updateShouldNotify(AuthScope oldWidget) => sair != oldWidget.sair;
}
