import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/field_help_definitions.dart';

/// Campo de entrada com botão integrado de Ajuda Contextual completa e validação detalhada.
class ContextualHelpField extends StatelessWidget {
  final FieldHelpInfo helpInfo;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final String? prefixText;
  final String? suffixText;

  const ContextualHelpField({
    super.key,
    required this.helpInfo,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.prefixIcon,
    this.prefixText,
    this.suffixText,
  });

  void _mostrarAjuda(BuildContext context) {
    mostrarAjuda(context, helpInfo);
  }

  /// Exibe o modal bottom sheet explicativo de ajuda contextual
  static void mostrarAjuda(BuildContext context, FieldHelpInfo helpInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.help_outline,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          helpInfo.nome,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHelpItem(
                    context,
                    icon: Icons.flag_outlined,
                    title: 'Finalidade',
                    content: helpInfo.finalidade,
                  ),
                  _buildHelpItem(
                    context,
                    icon: Icons.edit_note_outlined,
                    title: 'Como preencher',
                    content: helpInfo.instrucao,
                  ),
                  _buildHelpItem(
                    context,
                    icon: Icons.search_outlined,
                    title: 'Onde encontrar',
                    content: helpInfo.origem,
                    highlight: true,
                  ),
                  _buildHelpItem(
                    context,
                    icon: Icons.lightbulb_outline,
                    title: 'Exemplo prático',
                    content: helpInfo.exemplo,
                  ),
                  _buildHelpItem(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Obrigatoriedade e Formato',
                    content:
                        '${helpInfo.obrigatorio ? 'Obrigatório' : 'Opcional'} • Formato: ${helpInfo.formato}',
                  ),
                  _buildHelpItem(
                    context,
                    icon: Icons.rule_outlined,
                    title: 'Regras de validação',
                    content: helpInfo.validacao,
                  ),
                  _buildHelpItem(
                    context,
                    icon: Icons.trending_up_outlined,
                    title: 'Efeito no cálculo e recibos',
                    content: helpInfo.efeito,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Entendi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: highlight ? theme.colorScheme.primary : Colors.black87,
                    fontWeight: highlight ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                helpInfo.nome,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'Ver ajuda de "${helpInfo.nome}"',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => _mostrarAjuda(context),
            ),
          ],
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Ex: ${helpInfo.exemplo}',
            prefixIcon: prefixIcon,
            prefixText: prefixText,
            suffixText: suffixText,
            helperText: helpInfo.instrucao,
            helperMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
