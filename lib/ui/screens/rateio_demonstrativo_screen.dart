import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/codigo_unidade.dart';
import '../../core/currency_utils.dart';
import '../../data/database/pagamento_repository.dart';
import '../../domain/models/fechamento_rateio.dart';
import '../../domain/models/pagamento.dart';
import '../../domain/models/rateio_unidade.dart';
import '../widgets/conferencia_card.dart';
import 'competencia_form_screen.dart';
import 'recibo_detalhe_screen.dart';
import 'recibos_pdf_screen.dart';
import '../widgets/app_shell.dart';
import '../widgets/botao_tema.dart';

/// Tela do Demonstrativo Completo de Rateio das Despesas do Condomínio.
class RateioDemonstrativoScreen extends StatefulWidget {
  final FechamentoRateio fechamento;

  const RateioDemonstrativoScreen({super.key, required this.fechamento});

  @override
  State<RateioDemonstrativoScreen> createState() =>
      _RateioDemonstrativoScreenState();
}

class _RateioDemonstrativoScreenState extends State<RateioDemonstrativoScreen> {
  final PagamentoRepository _pagamentoRepo = PagamentoRepository();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _mostrarLinhasAtraso = false;
  bool _carregandoPagamentos = true;
  String? _erroPagamentos;
  Map<String, Pagamento> _pagamentos = {};

  int? get _competenciaId => widget.fechamento.competencia.id;

  @override
  void initState() {
    super.initState();
    _carregarPagamentos();
  }

  Future<void> _carregarPagamentos() async {
    final compId = _competenciaId;
    if (compId == null) {
      setState(() => _carregandoPagamentos = false);
      return;
    }
    setState(() {
      _carregandoPagamentos = true;
      _erroPagamentos = null;
    });
    try {
      final mapa = await _pagamentoRepo.getPorCompetencia(compId);
      if (!mounted) return;
      setState(() => _pagamentos = mapa);
    } catch (e) {
      debugPrint('Erro ao carregar pagamentos: $e');
      if (!mounted) return;
      setState(() => _erroPagamentos = e.toString());
    } finally {
      if (mounted) {
        setState(() => _carregandoPagamentos = false);
      }
    }
  }

  bool _estaPago(String codigoUnidade) =>
      _pagamentos[codigoUnidade]?.pago ?? false;

  double _valorHoje(RateioUnidade item) => item.valorNaData(
    widget.fechamento.competencia.dataVencimento,
    DateTime.now(),
  );

  Future<void> _alternarPagamento(RateioUnidade item, bool pago) async {
    final compId = _competenciaId;
    if (compId == null) return;

    final codigo = item.unidade.codigo;
    try {
      if (pago) {
        final novo = Pagamento(
          competenciaId: compId,
          unidadeCodigo: codigo,
          pago: true,
          dataPagamento: DateTime.now(),
          valorPago: _valorHoje(item),
        );
        await _pagamentoRepo.salvar(novo);
        if (!mounted) return;
        setState(() => _pagamentos[codigo] = novo);
      } else {
        await _pagamentoRepo.remover(compId, codigo);
        if (!mounted) return;
        setState(() => _pagamentos.remove(codigo));
      }
    } catch (e) {
      debugPrint('Erro ao atualizar pagamento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar pagamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editarCompetencia() async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompetenciaFormScreen(
          competenciaExistente: widget.fechamento.competencia,
        ),
      ),
    );
    if (res == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final escuro = theme.brightness == Brightness.dark;
    final comp = widget.fechamento.competencia;

    // Totais do controle de pagamento (valores considerando a data de hoje)
    double totalAReceberHoje = 0.0;
    double totalRecebido = 0.0;
    int unidadesPagas = 0;
    for (final item in widget.fechamento.itens) {
      final valorHoje = _valorHoje(item);
      totalAReceberHoje += valorHoje;
      final pagamento = _pagamentos[item.unidade.codigo];
      if (pagamento?.pago == true) {
        unidadesPagas++;
        totalRecebido += pagamento?.valorPago ?? valorHoje;
      }
    }
    final totalPendente = totalAReceberHoje - totalRecebido;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rateio • ${comp.mesReferencia}/${comp.anoReferencia}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar Lançamentos',
            onPressed: _editarCompetencia,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Gerar PDF dos Recibos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      RecibosPdfScreen(fechamento: widget.fechamento),
                ),
              );
            },
          ),
          const BotaoTema(),
        ],
      ),
      body: ConteudoCentralizado(
        larguraMaxima: 1100,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card de conferência
            ConferenciaCard(fechamento: widget.fechamento),
            const SizedBox(height: 16),

            // Controle de Pagamentos
            _buildControlePagamentos(
              theme: theme,
              totalAReceberHoje: totalAReceberHoje,
              totalRecebido: totalRecebido,
              totalPendente: totalPendente,
              unidadesPagas: unidadesPagas,
              totalUnidades: widget.fechamento.itens.length,
            ),
            const SizedBox(height: 16),

            // Cabeçalho e filtro
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tabela de Rateio Geral (${widget.fechamento.itens.length} Unidades)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Total de Moradores: ${widget.fechamento.totalPessoas} pessoas • Síndico: ${comp.nomeSindico} (Apto ${widget.fechamento.codigoSindico})',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Vencimento: ${_dateFormat.format(comp.dataVencimento)} • Valores "A Pagar (Hoje)" já incluem juros/multa quando em atraso',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Ver Atrasos',
                          style: TextStyle(fontSize: 12),
                        ),
                        Switch(
                          value: _mostrarLinhasAtraso,
                          onChanged: (val) =>
                              setState(() => _mostrarLinhasAtraso = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tabela horizontal rolável
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Unidade',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Morador',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Pessoas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Água',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Energia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Limpeza',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Outros',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Fundo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Rateio Síndico',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'TOTAL Venc.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'A Pagar (Hoje)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Até 30 dias',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        '30–60 dias',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Situação',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Ações',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: [
                    ...widget.fechamento.itens.map((item) {
                      final isSindico = mesmoCodigoUnidade(
                        item.unidade.codigo,
                        widget.fechamento.codigoSindico,
                      );
                      final pago = _estaPago(item.unidade.codigo);
                      final valorHoje = _valorHoje(item);
                      final emAtraso =
                          valorHoje > item.faixaNoVencimento + 0.001;

                      Color? rowColor;
                      if (pago) {
                        rowColor = Colors.green.withValues(alpha: 0.12);
                      } else if (isSindico) {
                        rowColor = Colors.amber.withValues(alpha: 0.16);
                      }

                      return DataRow(
                        color: rowColor == null
                            ? null
                            : WidgetStateProperty.all(rowColor),
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                Text(
                                  item.unidade.descricaoExibicao,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isSindico) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          DataCell(Text(item.unidade.nomeMorador)),
                          DataCell(
                            Text(
                              item.unidade.isLoja
                                  ? '-'
                                  : '${item.unidade.numeroPessoas}',
                            ),
                          ),
                          DataCell(
                            Text(CurrencyUtils.format(item.aguaVencimento)),
                          ),
                          DataCell(
                            Text(CurrencyUtils.format(item.luzVencimento)),
                          ),
                          DataCell(
                            Text(CurrencyUtils.format(item.limpezaVencimento)),
                          ),
                          DataCell(
                            Text(CurrencyUtils.format(item.outrosVencimento)),
                          ),
                          DataCell(
                            Text(CurrencyUtils.format(item.fundoVencimento)),
                          ),
                          DataCell(
                            Text(
                              CurrencyUtils.format(
                                item.rateioSindicoVencimento,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CurrencyUtils.format(item.totalGeralVencimento),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              CurrencyUtils.format(valorHoje),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: emAtraso
                                    ? (escuro
                                          ? Colors.redAccent.shade100
                                          : Colors.red.shade700)
                                    : (escuro
                                          ? Colors.greenAccent.shade200
                                          : Colors.green.shade800),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(CurrencyUtils.format(item.faixaAte30Dias)),
                          ),
                          DataCell(
                            Text(CurrencyUtils.format(item.faixa30a60Dias)),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: pago,
                                  activeColor: escuro
                                      ? Colors.greenAccent.shade700
                                      : Colors.green.shade700,
                                  onChanged: comp.id == null
                                      ? null
                                      : (val) => _alternarPagamento(
                                          item,
                                          val ?? false,
                                        ),
                                ),
                                Text(
                                  pago ? 'Pago' : 'Pendente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: pago
                                        ? (escuro
                                              ? Colors.greenAccent.shade200
                                              : Colors.green.shade800)
                                        : (escuro
                                              ? Colors.redAccent.shade100
                                              : Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.receipt, size: 18),
                              tooltip: 'Ver Recibo Individual',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReciboDetalheScreen(
                                      rateioItem: item,
                                      fechamento: widget.fechamento,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                    // Linha de Totais da Linha 67
                    DataRow(
                      color: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                      cells: [
                        const DataCell(
                          Text(
                            'TOTAIS',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataCell(Text('-')),
                        DataCell(
                          Text(
                            '${widget.fechamento.totalPessoas}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(widget.fechamento.totalAgua),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(widget.fechamento.totalLuz),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(
                              widget.fechamento.totalLimpeza,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(widget.fechamento.totalOutros),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(widget.fechamento.totalFundo),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(
                              widget.fechamento.totalRateioSindicoCobrado,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(
                              widget.fechamento.totalGeralVencimento,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            CurrencyUtils.format(totalAReceberHoje),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataCell(Text('-')),
                        const DataCell(Text('-')),
                        DataCell(
                          Text(
                            '$unidadesPagas/${widget.fechamento.itens.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataCell(Text('-')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Notas informativas e rodapé da aba DADO_RECIBOS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas Informativas e Critérios do Rateio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNotaItem(
                      'Água:',
                      'A taxa mínima (R\$ ${CurrencyUtils.formatClean(comp.taxaMinimaAgua)}) fica com a Loja. O esgoto é dividido pelas 11 unidades (R\$ ${CurrencyUtils.formatClean(comp.taxaEsgotoPorUnidade)}/unid). O excedente é rateado por morador (${CurrencyUtils.formatClean(comp.valorRateioAguaPessoas / widget.fechamento.totalPessoas)}/pessoa).',
                    ),
                    _buildNotaItem(
                      'Energia:',
                      'Dividida igualmente pelos 10 apartamentos. A Loja não utiliza as dependências comuns internas.',
                    ),
                    _buildNotaItem(
                      'Limpeza:',
                      'Custo total de serviços e materiais dividido pelas 11 unidades.',
                    ),
                    _buildNotaItem(
                      'Outras Despesas:',
                      'Limpeza de caixas d\'água dividida por 10 unidades (síndico isento).',
                    ),
                    _buildNotaItem(
                      'Fundo Emergencial:',
                      'R\$ 100,00 por apartamento. A Loja não contribui no fundo preventivo regular.',
                    ),
                    _buildNotaItem(
                      'Síndico (Apto ${widget.fechamento.codigoSindico}):',
                      'Despesas operacionais (água, luz e limpeza) cobertas pelo rateio das demais unidades. Paga apenas o fundo de reserva.',
                    ),
                    _buildNotaItem(
                      'Atrasos:',
                      'Até 30 dias aplica fator 0,95 (+5,26%). Acima de 30 dias acresce juros de 1,5% a.m. e multa legal de 2,0%.',
                    ),
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

  Widget _buildControlePagamentos({
    required ThemeData theme,
    required double totalAReceberHoje,
    required double totalRecebido,
    required double totalPendente,
    required int unidadesPagas,
    required int totalUnidades,
  }) {
    final progresso = totalAReceberHoje > 0
        ? (totalRecebido / totalAReceberHoje).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Controle de Pagamentos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  '$unidadesPagas de $totalUnidades pagas',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (_erroPagamentos != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Não foi possível carregar os pagamentos: $_erroPagamentos',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _carregarPagamentos,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ] else if (_carregandoPagamentos) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildResumoValor(
                  'A Receber (Hoje)',
                  totalAReceberHoje,
                  theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _buildResumoValor(
                  'Recebido',
                  totalRecebido,
                  theme.brightness == Brightness.dark
                      ? Colors.greenAccent.shade200
                      : Colors.green.shade800,
                ),
                const SizedBox(width: 8),
                _buildResumoValor(
                  'Pendente',
                  totalPendente,
                  theme.brightness == Brightness.dark
                      ? Colors.redAccent.shade100
                      : Colors.red.shade700,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 8,
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progresso * 100).toStringAsFixed(1)}% do previsto já recebido',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoValor(String rotulo, double valor, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: TextStyle(
                fontSize: 11,
                color: cor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyUtils.format(valor),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: cor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotaItem(String titulo, String descricao) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              descricao,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
