import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'navegacao.dart';

/// Drawer de navegação principal da aplicação (telas estreitas/mobile).
class AppDrawer extends StatelessWidget {
  final DestinoApp secaoAtual;
  final ValueChanged<DestinoApp>? onSelecionar;

  const AppDrawer({super.key, required this.secaoAtual, this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            accountName: const Text(
              'Condomínio Evaristo Lucchese',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text('Gestão de Rateio e Recibos Mensais'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.apartment, size: 40, color: Colors.blueAccent),
            ),
          ),
          for (final destino in DestinoApp.values)
            ListTile(
              leading: Icon(destino.icone),
              title: Text(destino.titulo),
              subtitle: Text(destino.subtitulo),
              selected: secaoAtual == destino,
              onTap: () {
                Navigator.of(context).pop();
                if (secaoAtual != destino) {
                  onSelecionar?.call(destino);
                }
              },
            ),
          const Divider(),
          const Spacer(),
          if (AuthScope.maybeOf(context) != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                final auth = AuthScope.maybeOf(context);
                Navigator.of(context).pop();
                auth?.sair();
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Versão 1.0.0 • Offline First\nBaseado na aba DADO_RECIBOS',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
