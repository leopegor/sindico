import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/database/backup_service.dart';
import '../widgets/app_shell.dart';

/// Tela para gerenciamento de cópias de segurança (Backup) e restauração de dados.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _processando = false;
  final TextEditingController _importJsonController = TextEditingController();

  @override
  void dispose() {
    _importJsonController.dispose();
    super.dispose();
  }

  Future<void> _exportarBackup() async {
    setState(() => _processando = true);
    try {
      await _backupService.exportarBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Backup baixado pelo navegador. Guarde o arquivo em local seguro.'
                  : 'Backup gerado e pronto para compartilhamento/salvamento.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  Future<void> _copiarJsonParaAreaTransferencia() async {
    setState(() => _processando = true);
    try {
      final json = await _backupService.gerarJsonBackup();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conteúdo do backup copiado para a Área de Transferência.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao copiar backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  Future<void> _restaurarBackup() async {
    final texto = _importJsonController.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cole o conteúdo JSON do backup no campo abaixo antes de restaurar.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Restauração de Dados'),
        content: const Text(
          'A restauração importará as unidades e competências contidas no arquivo de backup.\n\nDeseja prosseguir com a restauração?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _processando = true);
    try {
      final resultado = await _backupService.restaurarDeJson(texto);
      if (mounted) {
        if (resultado.sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${resultado.mensagem} (${resultado.unidadesImportadas} unidades, ${resultado.competenciasImportadas} competências)',
              ),
              backgroundColor: Colors.green.shade800,
            ),
          );
          _importJsonController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.mensagem),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PainelScaffold(
      titulo: 'Backup e Segurança',
      body: _processando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Alerta explicativo de armazenamento local
                Card(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Armazenamento Local e Seguro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kIsWeb
                              ? 'Todos os registros são gravados de forma persistente no armazenamento local deste navegador (IndexedDB).\n\n'
                                    'Para não perder os dados, use sempre o mesmo navegador e dispositivo. Recomendamos exportar o backup mensalmente e guardá-lo no Google Drive, e-mail ou computador.'
                              : 'Todos os registros são gravados de forma persistente na memória segura deste dispositivo.\n\n'
                                    'Recomendamos realizar o backup mensalmente e salvá-lo no Google Drive, e-mail ou computador pessoal para prevenir perdas em caso de troca ou avaria do aparelho.',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Card de Exportação de Backup
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Exportar Backup do Condomínio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Gera um arquivo JSON completo com validação de integridade criptográfica SHA-256 contendo todo o cadastro das 11 unidades e as competências cadastradas.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                icon: Icon(
                                  kIsWeb ? Icons.download : Icons.share,
                                ),
                                label: Text(
                                  kIsWeb
                                      ? 'Baixar Arquivo'
                                      : 'Compartilhar Arquivo',
                                ),
                                onPressed: _exportarBackup,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('Copiar JSON'),
                              onPressed: _copiarJsonParaAreaTransferencia,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Card de Restauração de Backup
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restaurar Backup Existente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cole abaixo o texto JSON exportado anteriormente para recuperar unidades e competências com verificação automática de integridade.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _importJsonController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Cole aqui o texto do backup JSON...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.restore_page),
                            label: const Text('Restaurar Dados'),
                            onPressed: _restaurarBackup,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
