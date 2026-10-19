import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/currency_utils.dart';
import '../../domain/models/fechamento_rateio.dart';
import '../../domain/models/rateio_unidade.dart';
import 'recibos_pdf_screen.dart';
import '../widgets/app_shell.dart';

/// Exibição detalhada de um recibo individual de unidade.
class ReciboDetalheScreen extends StatelessWidget {
  final RateioUnidade rateioItem;
  final FechamentoRateio fechamento;

  const ReciboDetalheScreen({
    super.key,
    required this.rateioItem,
    required this.fechamento,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comp = fechamento.competencia;
    final u = rateioItem.unidade;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isSindico = u.isSindico || u.codigo.trim() == comp.aptoSindico.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text('Recibo • ${u.descricaoExibicao}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Gerar PDF deste Recibo',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecibosPdfScreen(
                    fechamento: fechamento,
                    unidadeFiltro: u.codigo,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ConteudoCentralizado(
        larguraMaxima: 900,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          // Cabeçalho do Recibo
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.blue.shade900,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEMONSTRATIVO DE DESPESAS DO CONDOMÍNIO EVARISTO LUCCHESE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          u.descricaoExibicao,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Mês: ${comp.mesReferencia}/${comp.anoReferencia}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Morador(a): ${u.nomeMorador}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'VENCIMENTO: ${dateFormat.format(comp.dataVencimento)}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quadro de Itens de Rateio
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Composição da Cota Condominial (No Vencimento)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Divider(),
                  _buildLinhaDespesa(
                    '1. Água e Esgoto',
                    rateioItem.aguaVencimento,
                    subtitulo: u.isLoja
                        ? 'Taxa mínima (R\$ ${CurrencyUtils.formatClean(comp.taxaMinimaAgua)}) + Esgoto'
                        : '${u.numeroPessoas} pessoa(s) no rateio',
                  ),
                  _buildLinhaDespesa(
                    '2. Energia Elétrica',
                    rateioItem.luzVencimento,
                    subtitulo: u.isLoja ? 'Loja isenta' : 'Cota de área comum (1/10)',
                  ),
                  _buildLinhaDespesa(
                    '3. Limpeza e Conservação',
                    rateioItem.limpezaVencimento,
                    subtitulo: 'Serviços e materiais (1/11)',
                  ),
                  _buildLinhaDespesa(
                    '4. Seguro Obrigatório',
                    rateioItem.seguroVencimento,
                    subtitulo: comp.valorApolice == null ? 'Sem cobrança no mês' : null,
                  ),
                  _buildLinhaDespesa(
                    '5. Limpeza de Caixas d\'Água / Outros',
                    rateioItem.outrosVencimento,
                    subtitulo: _combinarSubtitulo(
                      isSindico ? 'Síndico isento' : 'Rateio de despesas extraordinárias (1/10)',
                      comp.discriminacaoOutrasDespesas,
                    ),
                  ),
                  _buildLinhaDespesa(
                    '6. Fundo Manutenções Emergenciais',
                    rateioItem.fundoVencimento,
                    subtitulo: _combinarSubtitulo(
                      u.isLoja
                          ? 'Isenta mensalmente'
                          : 'Reserva patrimonial aprovada em assembleia',
                      comp.discriminacaoFundoManutencao,
                    ),
                  ),
                  _buildLinhaDespesa(
                    '7. Rateio do Síndico',
                    rateioItem.rateioSindicoVencimento,
                    subtitulo: isSindico
                        ? 'Unidade isenta da cota operacional'
                        : 'Rateio do consumo operacional da adm.',
                  ),
                  if (rateioItem.policiamentoVencimento > 0)
                    _buildLinhaDespesa(
                      '8. Policiamento Comunitário',
                      rateioItem.policiamentoVencimento,
                    ),
                  const Divider(thickness: 1.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'TOTAL A PAGAR NO VENCIMENTO',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyUtils.format(rateioItem.totalGeralVencimento),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (u.isLoja && rateioItem.valorLocatarioLoja != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Valor a ser pago pelo locatário:',
                              style: TextStyle(color: Colors.teal.shade900, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyUtils.format(rateioItem.valorLocatarioLoja),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabela das 7 Faixas de Cobrança e Atraso
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escala de Vencimento e Faixas de Atraso',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valores calculados com acréscimo de atraso, juros (${(comp.jurosMoraMensal * 100).toStringAsFixed(1)}% a.m.) e multa legal (${(comp.multaMora * 100).toStringAsFixed(1)}%):',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const Divider(),
                  _buildFaixaItem('1. Até o Vencimento', rateioItem.faixaNoVencimento, isVencimento: true),
                  _buildFaixaItem('2. Até 30 dias do vencimento', rateioItem.faixaAte30Dias),
                  _buildFaixaItem('3. De 30 a 60 dias (com juros e multa)', rateioItem.faixa30a60Dias),
                  _buildFaixaItem('4. De 60 a 90 dias', rateioItem.faixa60a90Dias),
                  _buildFaixaItem('5. De 90 a 120 dias', rateioItem.faixa90a120Dias),
                  _buildFaixaItem('6. De 120 a 150 dias', rateioItem.faixa120a150Dias),
                  _buildFaixaItem('7. De 150 a 180 dias', rateioItem.faixa150a180Dias),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dados utilizados para os cálculos (Transparência)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados Utilizados para os Cálculos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Divider(),
                  _buildInfoDado('Total de moradores no prédio:', '${fechamento.totalPessoas} pessoas'),
                  _buildInfoDado('Moradores desta unidade:', u.isLoja ? '0 (Comercial)' : '${u.numeroPessoas} pessoa(s)'),
                  _buildInfoDado('Área Privativa / Fração Ideal:', '${u.areaPrivativa} m² (${(u.fracaoIdeal * 100).toStringAsFixed(2)}%)'),
                  _buildInfoDado('Valor total da conta d\'água:', CurrencyUtils.format(comp.valorContaAgua)),
                  _buildInfoDado('Valor total da energia comum:', CurrencyUtils.format(comp.valorContaEnergia)),
                  _buildInfoDado('Total serviços de limpeza:', CurrencyUtils.format(comp.custoTotalLimpeza)),
                  if ((comp.discriminacaoOutrasDespesas ?? '').trim().isNotEmpty)
                    _buildInfoDado('Outras despesas:', comp.discriminacaoOutrasDespesas!.trim()),
                  if ((comp.discriminacaoFundoManutencao ?? '').trim().isNotEmpty)
                    _buildInfoDado('Fundo emergencial:', comp.discriminacaoFundoManutencao!.trim()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Observações e Instruções de Pagamento
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instruções e Observações',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Divider(),
                  Text(
                    '• Efetuar o pagamento com o(a) síndico(a) ${comp.nomeSindico} no Apto ${comp.aptoSindico}.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Por decisão da Assembléia de Condomínio, os pagamentos em atraso terão acréscimo de juros. A partir do 30º dia também serão cobrados ${(comp.multaMora * 100).toStringAsFixed(0)}% de multa. Até 30 dias de atraso permanece a metodologia até hoje utilizada.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  if (u.isLoja) ...[
                    const SizedBox(height: 6),
                    const Text(
                      '• O fundo de manutenções e o valor do seguro obrigatório são de responsabilidade do proprietário.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
        ),
      ),
    );
  }

  String? _combinarSubtitulo(String? base, String? discriminacao) {
    final disc = discriminacao?.trim();
    if (disc == null || disc.isEmpty) return base;
    if (base == null || base.isEmpty) return 'Discriminação: $disc';
    return '$base\nDiscriminação: $disc';
  }

  Widget _buildLinhaDespesa(String titulo, double valor, {String? subtitulo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitulo != null)
                  Text(subtitulo, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            CurrencyUtils.format(valor),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFaixaItem(String titulo, double valor, {bool isVencimento = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isVencimento ? FontWeight.bold : FontWeight.normal,
                color: isVencimento ? Colors.blue.shade900 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyUtils.format(valor),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isVencimento ? Colors.blue.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDado(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(rotulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
