import 'package:flutter/material.dart';

import '../../core/codigo_unidade.dart';
import '../../core/currency_utils.dart';
import '../../domain/models/fechamento_rateio.dart';
import 'competencia_form_screen.dart';
import 'recibo_detalhe_screen.dart';
import 'recibos_pdf_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/botao_tema.dart';

/// Lista com os 11 recibos individuais do condomínio.
class RecibosListScreen extends StatelessWidget {
  final FechamentoRateio fechamento;

  const RecibosListScreen({super.key, required this.fechamento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final escuro = theme.brightness == Brightness.dark;
    final comp = fechamento.competencia;

    return Scaffold(
      appBar: AppBar(
        title: Text('11 Recibos • ${comp.mesReferencia}/${comp.anoReferencia}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Lançamentos',
            onPressed: () async {
              final res = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      CompetenciaFormScreen(competenciaExistente: comp),
                ),
              );
              if (res == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Gerar Todos em PDF',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecibosPdfScreen(fechamento: fechamento),
                ),
              );
            },
          ),
          const BotaoTema(),
        ],
      ),
      body: ConteudoCentralizado(
        larguraMaxima: 900,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fechamento.itens.length,
          itemBuilder: (ctx, index) {
            final item = fechamento.itens[index];
            final u = item.unidade;
            final isSindico = mesmoCodigoUnidade(
              u.codigo,
              fechamento.codigoSindico,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSindico
                    ? const BorderSide(color: Colors.amber, width: 1.5)
                    : BorderSide.none,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: isSindico
                      ? Colors.amber.withValues(alpha: 0.25)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    u.codigo.replaceAll('APTO ', ''),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSindico
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        u.descricaoExibicao,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSindico) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Síndico',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Morador: ${u.nomeMorador}'),
                    Text(
                      u.isLoja
                          ? 'Área: ${u.areaPrivativa} m²'
                          : 'Moradores: ${u.numeroPessoas} • Área: ${u.areaPrivativa} m²',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (u.isLoja && item.valorLocatarioLoja != null)
                      Text(
                        'Locatário: ${CurrencyUtils.format(item.valorLocatarioLoja)}',
                        style: TextStyle(
                          color: escuro
                              ? Colors.tealAccent.shade200
                              : Colors.teal.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'No Vencimento',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        CurrencyUtils.format(item.totalGeralVencimento),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReciboDetalheScreen(
                        rateioItem: item,
                        fechamento: fechamento,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
