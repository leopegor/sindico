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
    final tudoOk = fechamento.isFechamentoConsistente;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tudoOk ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      color: tudoOk ? Colors.green.shade50 : Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  tudoOk ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: tudoOk ? Colors.green.shade800 : Colors.orange.shade900,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tudoOk ? 'Conferência Contábil: 100% Fechada' : 'Atenção aos Fechamentos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tudoOk ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLinhaItem(
              rotulo: 'Água (CORSAN)',
              calculado: fechamento.totalAgua,
              esperado: fechamento.competencia.valorContaAgua,
              ok: fechamento.isAguaFechada,
            ),
            _buildLinhaItem(
              rotulo: 'Energia Elétrica (RGE)',
              calculado: fechamento.totalLuz,
              esperado: fechamento.competencia.valorContaEnergia,
              ok: fechamento.isLuzFechada,
            ),
            _buildLinhaItem(
              rotulo: 'Limpeza e Conservação',
              calculado: fechamento.totalLimpeza,
              esperado: fechamento.competencia.custoTotalLimpeza,
              ok: fechamento.isLimpezaFechada,
            ),
            _buildLinhaItem(
              rotulo: 'Outras Despesas (Caixas)',
              calculado: fechamento.totalOutros,
              esperado: fechamento.competencia.limpezaCaixasAgua,
              ok: fechamento.isOutrosFechada,
            ),
            _buildLinhaItem(
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
    required String rotulo,
    required double calculado,
    required double esperado,
    required bool ok,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check : Icons.close,
            size: 16,
            color: ok ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rotulo,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Text(
            CurrencyUtils.format(calculado),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ok ? Colors.black87 : Colors.red.shade900,
            ),
          ),
          if (!ok) ...[
            const SizedBox(width: 4),
            Text(
              '(Esperado: ${CurrencyUtils.format(esperado)})',
              style: TextStyle(fontSize: 11, color: Colors.red.shade800),
            ),
          ],
        ],
      ),
    );
  }
}
