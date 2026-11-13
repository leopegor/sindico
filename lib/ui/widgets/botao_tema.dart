import 'package:flutter/material.dart';

import '../../core/theme_controller.dart';

/// Botão de alternância entre tema claro e escuro.
class BotaoTema extends StatelessWidget {
  const BotaoTema({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    final escuro = controller.escuro;
    return IconButton(
      tooltip: escuro ? 'Usar tema claro' : 'Usar tema escuro',
      icon: Icon(escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => controller.alternar(),
    );
  }
}
