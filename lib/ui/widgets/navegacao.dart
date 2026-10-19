import 'package:flutter/material.dart';
import '../screens/backup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/unidades_screen.dart';

/// Destinos principais de navegação da aplicação.
enum DestinoApp {
  competencias(
    chave: 'home',
    titulo: 'Competências Mensais',
    subtitulo: 'Lançamentos e histórico',
    icone: Icons.dashboard_outlined,
  ),
  unidades(
    chave: 'unidades',
    titulo: 'Unidades',
    subtitulo: 'Cadastro e balanço de pagamentos',
    icone: Icons.people_outline,
  ),
  backup(
    chave: 'backup',
    titulo: 'Backup e Restauração',
    subtitulo: 'Segurança e integridade de dados',
    icone: Icons.backup_outlined,
  );

  final String chave;
  final String titulo;
  final String subtitulo;
  final IconData icone;

  const DestinoApp({
    required this.chave,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
  });

  /// Constrói a tela correspondente a este destino.
  Widget criarTela() => switch (this) {
        DestinoApp.competencias => const HomeScreen(),
        DestinoApp.unidades => const UnidadesScreen(),
        DestinoApp.backup => const BackupScreen(),
      };
}
