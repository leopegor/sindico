import 'package:flutter/material.dart';

import '../../core/theme_controller.dart';
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
    final themeController = ThemeScope.maybeOf(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            accountName: const Text(
              'Condomínio Evaristo Lucchese',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text('Gestão de Rateio e Recibos Mensais'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: Icon(
                Icons.apartment,
                size: 40,
                color: theme.colorScheme.primary,
              ),
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
          if (themeController != null)
            SwitchListTile(
              secondary: Icon(
                themeController.escuro
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Tema escuro'),
              value: themeController.escuro,
              onChanged: (valor) => themeController.definirEscuro(valor),
            ),
          const Spacer(),
          if (AuthScope.maybeOf(context) != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                final auth = AuthScope.maybeOf(context);
                Navigator.of(context).pop();
                if (auth != null) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => auth.sair(),
                  );
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Versão 1.0.0 • Offline First\nBaseado na aba DADO_RECIBOS',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
