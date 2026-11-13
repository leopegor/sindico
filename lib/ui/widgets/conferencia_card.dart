import 'package:flutter/material.dart';

import '../../core/currency_utils.dart';
import '../../domain/models/fechamento_rateio.dart';

/// Card de conferência contábil em tempo real (Checklist da Linha 67 da planilha).
class ConferenciaCard extends StatelessWidget {
  final FechamentoRateio fechamento;

  const ConferenciaCard({super.key, required this.fechamento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final escuro = theme.brightness == Brightness.dark;
    final tudoOk = fechamento.isFechamentoConsistente;

    final corSucessoFundo = escuro
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.green.shade50;
    final corAlertaFundo = escuro
        ? Colors.amber.withValues(alpha: 0.15)
        : Colors.amber.shade50;
    final corBorda = tudoOk
        ? (escuro ? Colors.green.withValues(alpha: 0.4) : Colors.green.shade300)
        : (escuro
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.orange.shade300);
    final corIcone = tudoOk
        ? (escuro ? Colors.greenAccent.shade200 : Colors.green.shade800)
        : (escuro ? Colors.orangeAccent.shade200 : Colors.orange.shade900);
    final corTitulo = tudoOk
        ? (escuro ? Colors.greenAccent.shade100 : Colors.green.shade900)
        : (escuro ? Colors.orangeAccent.shade100 : Colors.orange.shade900);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: corBorda, width: 1.5),
      ),
      color: tudoOk ? corSucessoFundo : corAlertaFundo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  tudoOk ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: corIcone,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tudoOk
                        ? 'Conferência Contábil: 100% Fechada'
                        : 'Atenção aos Fechamentos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: corTitulo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLinhaItem(
              theme: theme,
              rotulo: 'Água (CORSAN)',
              calculado: fechamento.totalAgua,
              esperado: fechamento.competencia.valorContaAgua,
              ok: fechamento.isAguaFechada,
            ),
            _buildLinhaItem(
              theme: theme,
              rotulo: 'Energia Elétrica (RGE)',
              calculado: fechamento.totalLuz,
              esperado: fechamento.competencia.valorContaEnergia,
              ok: fechamento.isLuzFechada,
            ),
            _buildLinhaItem(
              theme: theme,
              rotulo: 'Limpeza e Conservação',
              calculado: fechamento.totalLimpeza,
              esperado: fechamento.competencia.custoTotalLimpeza,
              ok: fechamento.isLimpezaFechada,
            ),
            _buildLinhaItem(
              theme: theme,
              rotulo: 'Outras Despesas (Caixas)',
              calculado: fechamento.totalOutros,
              esperado: fechamento.competencia.limpezaCaixasAgua,
              ok: fechamento.isOutrosFechada,
            ),
            _buildLinhaItem(
              theme: theme,
              rotulo: 'Fundo Manutenções (10 aptos)',
              calculado: fechamento.totalFundo,
              esperado: fechamento.competencia.fundoManutencaoMensal * 10,
              ok: true,
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Previsão de Arrecadação (Total)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyUtils.format(fechamento.previsaoArrecadacao),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaItem({
    required ThemeData theme,
    required String rotulo,
    required double calculado,
    required double esperado,
    required bool ok,
  }) {
    final escuro = theme.brightness == Brightness.dark;
    final corOk = escuro ? Colors.greenAccent.shade200 : Colors.green.shade700;
    final corErro = escuro ? Colors.redAccent.shade200 : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check : Icons.close,
            size: 16,
            color: ok ? corOk : corErro,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rotulo,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            CurrencyUtils.format(calculado),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ok
                  ? theme.colorScheme.onSurface
                  : (escuro ? Colors.redAccent.shade100 : Colors.red.shade900),
            ),
          ),
          if (!ok) ...[
            const SizedBox(width: 4),
            Text(
              '(Esperado: ${CurrencyUtils.format(esperado)})',
              style: TextStyle(
                fontSize: 11,
                color: escuro ? Colors.redAccent.shade100 : Colors.red.shade800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
