import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/currency_utils.dart';
import '../../data/database/competencia_repository.dart';
import '../../data/database/divida_repository.dart';
import '../../data/database/pagamento_repository.dart';
import '../../data/database/unidade_repository.dart';
import '../../domain/models/abatimento_divida.dart';
import '../../domain/models/competencia.dart';
import '../../domain/models/divida_anterior.dart';
import '../../domain/models/pagamento.dart';
import '../../domain/models/rateio_unidade.dart';
import '../../domain/models/unidade.dart';
import '../../domain/services/calculadora_rateio_service.dart';
import '../widgets/app_shell.dart';

/// Registro de uma competência anterior em aberto para uma unidade.
class MesEmAberto {
  final Competencia competencia;
  final double valor;

  const MesEmAberto({required this.competencia, required this.valor});
}

/// Balanço de pagamentos de uma unidade: situação do mês atual + dívidas anteriores.
class ItemBalanco {
  final Unidade unidade;
  final RateioUnidade rateioAtual;
  final double valorMesAtual;
  bool pagoMesAtual;
  DateTime? dataPagamento;
  double? valorPago;
  final List<MesEmAberto> mesesAbertos;

  /// Dívida anterior definida manualmente (substitui o cálculo quando presente).
  DividaAnterior? dividaManual;

  /// Pagamentos parciais registrados sobre a dívida anterior.
  List<AbatimentoDivida> abatimentos;

  ItemBalanco({
    required this.unidade,
    required this.rateioAtual,
    required this.valorMesAtual,
    required this.pagoMesAtual,
    this.dataPagamento,
    this.valorPago,
    required this.mesesAbertos,
    this.dividaManual,
    this.abatimentos = const [],
  });

  /// Dívida calculada automaticamente pelos meses anteriores em aberto.
  double get dividaCalculada =>
      mesesAbertos.fold(0.0, (acc, m) => acc + m.valor);

  /// Base da dívida: valor manual quando existe, senão cálculo automático.
  double get dividaBase => dividaManual?.valor ?? dividaCalculada;

  /// Soma dos pagamentos parciais (abatimentos).
  double get totalAbatimentos =>
      abatimentos.fold(0.0, (acc, a) => acc + a.valor);

  /// Dívida que ainda resta após os abatimentos.
  double get dividaRestante => dividaBase - totalAbatimentos;
}

/// Tela de Balanço de Pagamentos por unidade:
/// registra se o condomínio do mês atual foi pago e soma o que resta de meses anteriores.
///
/// Quando [embutido] é verdadeiro, a tela é exibida sem `AppBar` próprio,
/// para ser usada como aba dentro de outra tela.
class BalancoPagamentosScreen extends StatefulWidget {
  final bool embutido;

  const BalancoPagamentosScreen({super.key, this.embutido = false});

  @override
  State<BalancoPagamentosScreen> createState() => _BalancoPagamentosScreenState();
}

class _BalancoPagamentosScreenState extends State<BalancoPagamentosScreen> {
  final UnidadeRepository _unidadeRepo = UnidadeRepository();
  final CompetenciaRepository _competenciaRepo = CompetenciaRepository();
  final PagamentoRepository _pagamentoRepo = PagamentoRepository();
  final DividaRepository _dividaRepo = DividaRepository();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _carregando = true;
  String? _erro;
  Competencia? _competenciaAtual;
  List<ItemBalanco> _itens = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final unidades = await _unidadeRepo.getTodas();
      final competencias = await _competenciaRepo.getTodas();

      if (competencias.isEmpty) {
        if (!mounted) return;
        setState(() {
          _competenciaAtual = null;
          _itens = [];
          _carregando = false;
        });
        return;
      }

      // getTodas ordena da mais recente para a mais antiga
      final atual = competencias.first;
      final anteriores = competencias.skip(1).toList();

      final fechamentoAtual = CalculadoraRateioService.calcular(
        competencia: atual,
        unidades: unidades,
      );
      final pagamentosAtual = atual.id != null
          ? await _pagamentoRepo.getPorCompetencia(atual.id!)
          : <String, Pagamento>{};

      final pagamentosAnteriores = <int, Map<String, Pagamento>>{};
      for (final comp in anteriores) {
        if (comp.id == null) continue;
        pagamentosAnteriores[comp.id!] =
            await _pagamentoRepo.getPorCompetencia(comp.id!);
      }

      final dividasManuais = await _dividaRepo.getDividas();
      final abatimentos = await _dividaRepo.getAbatimentos();
      final abatimentosPorUnidade = <String, List<AbatimentoDivida>>{};
      for (final a in abatimentos) {
        abatimentosPorUnidade.putIfAbsent(a.unidadeCodigo, () => []).add(a);
      }

      // Pré-calcula o rateio de cada competência anterior uma única vez
      final agora = DateTime.now();
      final fechamentosAnteriores = [
        for (final comp in anteriores)
          (
            comp: comp,
            fechamento: CalculadoraRateioService.calcular(
              competencia: comp,
              unidades: unidades,
            ),
          ),
      ];

      final itens = <ItemBalanco>[];
      for (final rateio in fechamentoAtual.itens) {
        final codigo = rateio.unidade.codigo;
        final pagamento = pagamentosAtual[codigo];

        final mesesAbertos = <MesEmAberto>[];
        for (final entry in fechamentosAnteriores) {
          final comp = entry.comp;
          final pagamentos =
              comp.id != null ? pagamentosAnteriores[comp.id!] : null;
          if (pagamentos?[codigo]?.pago == true) continue;
          final itemAnterior = entry.fechamento.itens.firstWhere(
            (i) => i.unidade.codigo == codigo,
            orElse: () => rateio,
          );
          mesesAbertos.add(MesEmAberto(
            competencia: comp,
            valor: itemAnterior.valorNaData(comp.dataVencimento, agora),
          ));
        }

        itens.add(ItemBalanco(
          unidade: rateio.unidade,
          rateioAtual: rateio,
          valorMesAtual: rateio.valorNaData(
            atual.dataVencimento,
            DateTime.now(),
          ),
          pagoMesAtual: pagamento?.pago ?? false,
          dataPagamento: pagamento?.dataPagamento,
          valorPago: pagamento?.valorPago,
          mesesAbertos: mesesAbertos,
          dividaManual: dividasManuais[codigo],
          abatimentos: abatimentosPorUnidade[codigo] ?? const [],
        ));
      }

      if (!mounted) return;
      setState(() {
        _competenciaAtual = atual;
        _itens = itens;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar balanço: $e');
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<void> _alternarPagamento(ItemBalanco item, bool pago) async {
    final comp = _competenciaAtual;
    if (comp == null || comp.id == null) return;

    final codigo = item.unidade.codigo;
    try {
      if (pago) {
        final agora = DateTime.now();
        final novo = Pagamento(
          competenciaId: comp.id!,
          unidadeCodigo: codigo,
          pago: true,
          dataPagamento: agora,
          valorPago: item.valorMesAtual,
        );
        await _pagamentoRepo.salvar(novo);
        if (!mounted) return;
        setState(() {
          item.pagoMesAtual = true;
          item.dataPagamento = agora;
          item.valorPago = item.valorMesAtual;
        });
      } else {
        await _pagamentoRepo.remover(comp.id!, codigo);
        if (!mounted) return;
        setState(() {
          item.pagoMesAtual = false;
          item.dataPagamento = null;
          item.valorPago = null;
        });
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

  /// Abre diálogo para digitar o valor da dívida anterior da unidade.
  /// Permite também voltar ao cálculo automático.
  Future<void> _editarDividaManual(ItemBalanco item) async {
    final controller = TextEditingController(
      text: CurrencyUtils.formatClean(item.dividaBase),
    );

    final acao = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Dívida Anterior — ${item.unidade.descricaoExibicao}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor da dívida anterior',
                prefixText: 'R\$ ',
                helperText: 'Total devido em meses anteriores',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cálculo automático: ${CurrencyUtils.format(item.dividaCalculada)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            if (item.dividaManual != null)
              Text(
                'Valor manual atual: ${CurrencyUtils.format(item.dividaManual!.valor)}',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          if (item.dividaManual != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('auto'),
              child: const Text('Usar cálculo automático'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('salvar'),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (acao == null || !mounted) return;

    try {
      if (acao == 'auto') {
        await _dividaRepo.removerDivida(item.unidade.codigo);
        if (!mounted) return;
        setState(() => item.dividaManual = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voltando ao cálculo automático da dívida.'),
          ),
        );
      } else {
        final valor = CurrencyUtils.parse(controller.text);
        final nova = DividaAnterior(
          unidadeCodigo: item.unidade.codigo,
          valor: valor,
          atualizadoEm: DateTime.now(),
        );
        await _dividaRepo.salvarDivida(nova);
        if (!mounted) return;
        setState(() => item.dividaManual = nova);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Dívida anterior de ${item.unidade.descricaoExibicao} salva em ${CurrencyUtils.format(valor)}.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar dívida anterior: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar dívida anterior: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Abre diálogo para registrar pagamento parcial (abatimento) na dívida anterior.
  Future<void> _registrarAbatimento(ItemBalanco item) async {
    final valorController = TextEditingController();
    final obsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar Abatimento — ${item.unidade.descricaoExibicao}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: valorController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor pago parcialmente',
                  prefixText: 'R\$ ',
                  isDense: true,
                ),
                validator: (v) {
                  final valor = CurrencyUtils.parse(v);
                  if (valor <= 0) return 'Informe um valor maior que zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: obsController,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  hintText: 'Ex.: pagamento em dinheiro, 1ª parcela',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dívida atual: ${CurrencyUtils.format(item.dividaRestante)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    try {
      final agora = DateTime.now();
      final abatimento = AbatimentoDivida(
        unidadeCodigo: item.unidade.codigo,
        valor: CurrencyUtils.parse(valorController.text),
        data: agora,
        observacao: obsController.text.trim().isEmpty
            ? null
            : obsController.text.trim(),
        criadoEm: agora,
      );
      final id = await _dividaRepo.inserirAbatimento(abatimento);
      final registrado = abatimento.copyWith(id: id);
      if (!mounted) return;
      setState(() {
        item.abatimentos = [registrado, ...item.abatimentos];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Abatimento de ${CurrencyUtils.format(abatimento.valor)} registrado. '
              'Restante: ${CurrencyUtils.format(item.dividaRestante)}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao registrar abatimento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar abatimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove um abatimento após confirmação.
  Future<void> _removerAbatimento(
      ItemBalanco item, AbatimentoDivida abatimento) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Abatimento'),
        content: Text(
          'Remover o abatimento de ${CurrencyUtils.format(abatimento.valor)}'
          '${abatimento.observacao != null ? ' (${abatimento.observacao})' : ''}? '
          'O valor volta a contar na dívida da unidade.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (conf != true || abatimento.id == null || !mounted) return;

    try {
      await _dividaRepo.removerAbatimento(abatimento.id!);
      if (!mounted) return;
      setState(() {
        item.abatimentos =
            item.abatimentos.where((a) => a.id != abatimento.id).toList();
      });
    } catch (e) {
      debugPrint('Erro ao remover abatimento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover abatimento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _detalharMeses(ItemBalanco item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Meses em Aberto — ${item.unidade.descricaoExibicao}'),
        content: SizedBox(
          width: double.maxFinite,
          child: item.mesesAbertos.isEmpty
              ? const Text('Nenhum mês anterior em aberto. Em dia!')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: item.mesesAbertos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final mes = item.mesesAbertos[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        '${mes.competencia.mesReferencia}/${mes.competencia.anoReferencia}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Vencimento: ${_dateFormat.format(mes.competencia.dataVencimento)}',
                      ),
                      trailing: Text(
                        CurrencyUtils.format(mes.valor),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comp = _competenciaAtual;

    final corpo = _carregando
        ? const Center(child: CircularProgressIndicator())
        : _erro != null
            ? _buildErro()
            : comp == null
                ? _buildSemCompetencia()
                : ConteudoCentralizado(
                    larguraMaxima: 1200,
                    child: _buildConteudo(theme, comp),
                  );

    if (widget.embutido) return corpo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balanço de Pagamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _carregando ? null : _carregar,
          ),
        ],
      ),
      body: corpo,
    );
  }

  Widget _buildConteudo(ThemeData theme, Competencia comp) {
    final totalUnidades = _itens.length;
    final pagas = _itens.where((i) => i.pagoMesAtual).length;
    final totalMesAtual =
        _itens.fold(0.0, (acc, i) => acc + i.valorMesAtual);
    final totalRecebidoMesAtual = _itens
        .where((i) => i.pagoMesAtual)
        .fold(0.0, (acc, i) => acc + (i.valorPago ?? i.valorMesAtual));
    final totalDividaAnteriores =
        _itens.fold(0.0, (acc, i) => acc + i.dividaRestante);
    final totalAbatido =
        _itens.fold(0.0, (acc, i) => acc + i.totalAbatimentos);
    final unidadesDevedoras =
        _itens.where((i) => i.dividaRestante > 0.001).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLegendaBanner(),
        const SizedBox(height: 16),
        // Cabeçalho da competência corrente
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.blue.shade100, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.blue.shade50.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_month,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balanço do Mês',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${comp.mesReferencia}/${comp.anoReferencia} • Vencimento: ${_dateFormat.format(comp.dataVencimento)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: '$pagas de $totalUnidades unidades pagas',
                      child: SizedBox(
                        width: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalUnidades == 0 ? 0 : pagas / totalUnidades,
                            minHeight: 6,
                            backgroundColor: Colors.blue.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.green.shade600),
                          ),
                        ),
                      ),
                    ),
                    if (widget.embutido)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recarregar balanço',
                        visualDensity: VisualDensity.compact,
                        onPressed: _carregando ? null : _carregar,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildResumoGrid([
                      _buildResumo(Icons.check_circle_outline, 'Pagas',
                          '$pagas/$totalUnidades', Colors.green.shade800),
                      _buildResumo(Icons.savings_outlined, 'Recebido (Mês)',
                          CurrencyUtils.format(totalRecebidoMesAtual),
                          Colors.green.shade700),
                      _buildResumo(Icons.schedule_outlined, 'A Receber (Mês)',
                          CurrencyUtils.format(totalMesAtual),
                          Colors.blue.shade800),
                      _buildResumo(Icons.history, 'Dívida Anterior',
                          CurrencyUtils.format(totalDividaAnteriores),
                          Colors.red.shade700),
                      _buildResumo(Icons.payments_outlined, 'Abatido',
                          CurrencyUtils.format(totalAbatido),
                          Colors.orange.shade800),
                      _buildResumo(Icons.warning_amber_outlined, 'Com Pendência',
                          '$unidadesDevedoras/$totalUnidades',
                          Colors.red.shade700),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildUnidadesCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildUnidadesCard() {
    final theme = Theme.of(context);
    final compacto = MediaQuery.sizeOf(context).width < 600;
    final comPendencia = _itens
        .where((i) => i.dividaRestante > 0.001 || !i.pagoMesAtual)
        .length;
    final totalUnidades = _itens.length;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.blue.shade100, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.blue.shade50.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.apartment, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Situação das Unidades',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$comPendencia de $totalUnidades unidades com pendência',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalUnidades,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: compacto ? 240 : 300,
                mainAxisExtent: compacto ? 120 : 132,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (ctx, index) => _buildTileUnidade(_itens[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoGrid(List<Widget> tiles) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final colunas = constraints.maxWidth < 560 ? 2 : 3;
        const espaco = 8.0;
        final largura =
            (constraints.maxWidth - espaco * (colunas - 1)) / colunas;
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final tile in tiles) SizedBox(width: largura, child: tile),
          ],
        );
      },
    );
  }

  Widget _buildLegendaBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _buildLegendaItem(Colors.green, 'Pago'),
          _buildLegendaItem(Colors.blue, 'Pendente'),
          _buildLegendaItem(Colors.red, 'Devedor'),
          _buildLegendaItem(Colors.orange, 'Dívida manual'),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(MaterialColor cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.15),
            border: Border.all(color: cor, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
        ),
      ],
    );
  }

  Future<void> _abrirDetalhe(ItemBalanco item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DetalheBalancoSheet(
        item: item,
        onAlternarPagamento: _alternarPagamento,
        onEditarDivida: _editarDividaManual,
        onRegistrarAbatimento: _registrarAbatimento,
        onRemoverAbatimento: _removerAbatimento,
        onDetalharMeses: _detalharMeses,
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _buildTileUnidade(ItemBalanco item) {
    final temDivida = item.dividaRestante > 0.001;
    final cor = temDivida
        ? const Color(0xFFC62828)
        : item.pagoMesAtual
            ? const Color(0xFF2E7D32)
            : const Color(0xFF1565C0);
    final tag =
        temDivida ? 'Devedor' : item.pagoMesAtual ? 'Pago' : 'Pendente';
    final icone = item.unidade.isLoja ? Icons.storefront : Icons.home;

    return Material(
      color: cor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalhe(item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withValues(alpha: 0.5), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icone, size: 16, color: cor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.unidade.descricaoExibicao,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildTag(tag, cor),
                ],
              ),
              Text(
                item.unidade.nomeMorador,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 13, color: Colors.grey.shade700),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Mês: ${CurrencyUtils.format(item.valorMesAtual)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    temDivida
                        ? Icons.warning_amber_rounded
                        : Icons.verified_outlined,
                    size: 13,
                    color: temDivida ? cor : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Dívida: ${CurrencyUtils.format(item.dividaRestante)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            temDivida ? FontWeight.bold : FontWeight.normal,
                        color: temDivida ? cor : Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.tune, size: 14, color: cor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cor),
      ),
    );
  }


  Widget _buildResumo(IconData icone, String rotulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 14, color: cor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rotulo,
                  style: TextStyle(
                      fontSize: 11, color: cor, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: cor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar o balanço',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _erro ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              onPressed: _carregar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemCompetencia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma competência mensal cadastrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre o mês de referência na tela inicial para gerar o balanço de pagamentos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}


/// Painel de detalhes de uma unidade no balanço de pagamentos.
class _DetalheBalancoSheet extends StatefulWidget {
  final ItemBalanco item;
  final Future<void> Function(ItemBalanco item, bool pago) onAlternarPagamento;
  final Future<void> Function(ItemBalanco item) onEditarDivida;
  final Future<void> Function(ItemBalanco item) onRegistrarAbatimento;
  final Future<void> Function(ItemBalanco item, AbatimentoDivida abatimento)
      onRemoverAbatimento;
  final void Function(ItemBalanco item) onDetalharMeses;

  const _DetalheBalancoSheet({
    required this.item,
    required this.onAlternarPagamento,
    required this.onEditarDivida,
    required this.onRegistrarAbatimento,
    required this.onRemoverAbatimento,
    required this.onDetalharMeses,
  });

  @override
  State<_DetalheBalancoSheet> createState() => _DetalheBalancoSheetState();
}

class _DetalheBalancoSheetState extends State<_DetalheBalancoSheet> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  ItemBalanco get item => widget.item;

  Future<void> _executar(Future<void> Function() acao) async {
    await acao();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final temDivida = item.dividaRestante > 0.001;
    final corStatus = temDivida
        ? const Color(0xFFC62828)
        : item.pagoMesAtual
            ? const Color(0xFF2E7D32)
            : const Color(0xFF1565C0);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    item.unidade.isLoja ? Icons.storefront : Icons.home,
                    color: corStatus,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.unidade.descricaoExibicao,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: corStatus,
                          ),
                        ),
                        Text(
                          item.unidade.nomeMorador,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildChip(
                    temDivida
                        ? 'Devedor'
                        : item.pagoMesAtual
                            ? 'Pago'
                            : 'Pendente',
                    corStatus,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              _buildTituloSecao(Icons.event_available_outlined, 'Situação do mês'),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: (item.pagoMesAtual ? Colors.green : Colors.blue)
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (item.pagoMesAtual ? Colors.green : Colors.blue)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.pagoMesAtual
                                ? 'Condomínio do mês quitado'
                                : 'Condomínio do mês pendente',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyUtils.format(item.valorMesAtual),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: item.pagoMesAtual
                                  ? Colors.green.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                          if (item.pagoMesAtual && item.dataPagamento != null)
                            Text(
                              'Pago em ${_dateFormat.format(item.dataPagamento!)}'
                              '${item.valorPago != null ? ' • ${CurrencyUtils.format(item.valorPago)}' : ''}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.green.shade800),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.pagoMesAtual,
                      activeThumbColor: Colors.green.shade700,
                      onChanged: (val) => _executar(
                        () => widget.onAlternarPagamento(item, val),
                      ),
                    ),
                  ],
                ),
              ),

              _buildTituloSecao(
                  Icons.account_balance_wallet_outlined, 'Dívida anterior'),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Dívida anterior (base)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildChip(
                    item.dividaManual != null ? 'Manual' : 'Automática',
                    item.dividaManual != null
                        ? const Color(0xFFEF6C00)
                        : const Color(0xFF546E7A),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Digitar valor da dívida anterior',
                    onPressed: () =>
                        _executar(() => widget.onEditarDivida(item)),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.dividaManual != null
                        ? 'Valor digitado'
                        : 'Calculado pelos meses em aberto',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    CurrencyUtils.format(item.dividaBase),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              if (item.abatimentos.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTituloSecao(
                    Icons.payments_outlined, 'Abatimentos registrados'),
                ...item.abatimentos.map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_dateFormat.format(a.data)}'
                            '${a.observacao != null ? ' • ${a.observacao}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '- ${CurrencyUtils.format(a.valor)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 16, color: Colors.red.shade400),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remover abatimento',
                          onPressed: () => _executar(
                            () => widget.onRemoverAbatimento(item, a),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL ABATIDO',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      '- ${CurrencyUtils.format(item.totalAbatimentos)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Registrar abatimento'),
                  onPressed: () =>
                      _executar(() => widget.onRegistrarAbatimento(item)),
                ),
              ),

              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (temDivida ? Colors.red : Colors.green)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (temDivida ? Colors.red : Colors.green)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          temDivida
                              ? Icons.error_outline
                              : Icons.verified_outlined,
                          size: 16,
                          color: temDivida
                              ? Colors.red.shade700
                              : Colors.green.shade800,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'RESTANTE DA DÍVIDA',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyUtils.format(item.dividaRestante),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: temDivida
                            ? Colors.red.shade700
                            : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              if (item.mesesAbertos.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: Text(
                        'Detalhar meses calculados (${item.mesesAbertos.length})'),
                    onPressed: () => widget.onDetalharMeses(item),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTituloSecao(IconData icone, String titulo) {
    final cor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Icon(icone, size: 15, color: cor),
          const SizedBox(width: 6),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.blue.shade100)),
        ],
      ),
    );
  }

  Widget _buildChip(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: cor,
        ),
      ),
    );
  }
}