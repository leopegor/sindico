import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/currency_utils.dart';
import '../../core/meses.dart';
import '../../data/database/competencia_repository.dart';
import '../../data/database/unidade_repository.dart';
import '../../domain/models/competencia.dart';
import '../../domain/services/calculadora_rateio_service.dart';
import '../widgets/app_shell.dart';
import 'competencia_form_screen.dart';
import 'rateio_demonstrativo_screen.dart';
import 'recibos_list_screen.dart';
import 'recibos_pdf_screen.dart';

/// Tela inicial com o histórico de competências mensais do condomínio.
///
/// As competências são organizadas por ano e exibidas em uma grade com os
/// 12 meses. Meses lançados recebem destaque colorido; meses pendentes
/// aparecem destacados em cinza com atalho para lançamento.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CompetenciaRepository _competenciaRepo = CompetenciaRepository();
  final UnidadeRepository _unidadeRepo = UnidadeRepository();

  bool _carregando = true;
  String? _erro;
  List<Competencia> _competencias = [];
  final Set<int> _anosExtras = {};

  @override
  void initState() {
    super.initState();
    _carregarCompetencias();
  }

  Future<void> _carregarCompetencias() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _competenciaRepo.getTodas();
      if (!mounted) return;
      setState(() => _competencias = lista);
    } catch (e) {
      debugPrint('Erro ao carregar competências: $e');
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Size get _tela => MediaQuery.sizeOf(context);

  Future<void> _abrirEdicao(Competencia comp) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompetenciaFormScreen(competenciaExistente: comp),
      ),
    );
    if (res == true) {
      _carregarCompetencias();
    }
  }

  Future<void> _novoMes(int mes, int ano) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompetenciaFormScreen(mesInicial: mes, anoInicial: ano),
      ),
    );
    if (res == true) {
      _carregarCompetencias();
    }
  }

  Future<void> _abrirDemonstrativo(Competencia comp) async {
    final unidades = await _unidadeRepo.getTodas();
    final fechamento = CalculadoraRateioService.calcular(
      competencia: comp,
      unidades: unidades,
    );
    if (!mounted) return;
    final editado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RateioDemonstrativoScreen(fechamento: fechamento),
      ),
    );
    if (editado == true) _carregarCompetencias();
  }

  Future<void> _abrirRecibos(Competencia comp) async {
    final unidades = await _unidadeRepo.getTodas();
    final fechamento = CalculadoraRateioService.calcular(
      competencia: comp,
      unidades: unidades,
    );
    if (!mounted) return;
    final editado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecibosListScreen(fechamento: fechamento),
      ),
    );
    if (editado == true) _carregarCompetencias();
  }

  Future<void> _abrirPdf(Competencia comp) async {
    final unidades = await _unidadeRepo.getTodas();
    final fechamento = CalculadoraRateioService.calcular(
      competencia: comp,
      unidades: unidades,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecibosPdfScreen(fechamento: fechamento),
      ),
    );
  }

  Future<void> _excluirCompetencia(Competencia comp) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Competência'),
        content: Text(
          'Deseja realmente excluir os lançamentos de ${comp.mesReferencia}/${comp.anoReferencia}?\nEsta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && comp.id != null) {
      try {
        await _competenciaRepo.excluir(comp.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Competência ${comp.mesReferencia}/${comp.anoReferencia} excluída.'),
            ),
          );
        }
        _carregarCompetencias();
      } catch (e) {
        debugPrint('Erro ao excluir competência: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir competência: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirAcoesMes(Competencia comp) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${comp.mesReferencia} / ${comp.anoReferencia}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vencimento: ${dateFormat.format(comp.dataVencimento)} • Síndico(a): ${comp.nomeSindico}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildAcaoTile(ctx, Icons.edit_outlined, 'Editar Lançamentos', 'editar'),
            _buildAcaoTile(ctx, Icons.table_chart_outlined, 'Demonstrativo de Rateio', 'demonstrativo'),
            _buildAcaoTile(ctx, Icons.receipt_long_outlined, '11 Recibos', 'recibos'),
            _buildAcaoTile(ctx, Icons.picture_as_pdf_outlined, 'Gerar PDF', 'pdf'),
            _buildAcaoTile(ctx, Icons.delete_outline, 'Excluir Competência', 'excluir', vermelho: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || acao == null) return;
    switch (acao) {
      case 'editar':
        await _abrirEdicao(comp);
      case 'demonstrativo':
        await _abrirDemonstrativo(comp);
      case 'recibos':
        await _abrirRecibos(comp);
      case 'pdf':
        await _abrirPdf(comp);
      case 'excluir':
        await _excluirCompetencia(comp);
    }
  }

  Widget _buildAcaoTile(
    BuildContext ctx,
    IconData icone,
    String titulo,
    String valor, {
    bool vermelho = false,
  }) {
    final cor = vermelho ? Colors.red : Theme.of(ctx).colorScheme.primary;
    return ListTile(
      leading: Icon(icone, color: cor),
      title: Text(
        titulo,
        style: TextStyle(color: vermelho ? Colors.red : Colors.black87),
      ),
      onTap: () => Navigator.of(ctx).pop(valor),
    );
  }

  /// Mapa ano -> (mês 1-12) -> competência
  Map<int, Map<int, Competencia>> _agruparPorAno() {
    final agrupado = <int, Map<int, Competencia>>{};
    for (final comp in _competencias) {
      final mes = indiceMesPorNome(comp.mesReferencia) ?? comp.dataVencimento.month;
      agrupado.putIfAbsent(comp.anoReferencia, () => {})[mes] = comp;
    }
    return agrupado;
  }

  List<int> _anosVisiveis(Map<int, Map<int, Competencia>> agrupado) {
    final anos = <int>{DateTime.now().year, ...agrupado.keys, ..._anosExtras};
    final lista = anos.toList()..sort((a, b) => b.compareTo(a));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return PainelScaffold(
      titulo: 'Competências Mensais',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Recarregar',
          onPressed: _carregarCompetencias,
        ),
      ],
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? _buildErro()
              : _buildConteudo(),
    );
  }

  Widget _buildConteudo() {
    final agrupado = _agruparPorAno();
    final anos = _anosVisiveis(agrupado);
    final menoAno = anos.last;
    final compacto = _tela.width < 600;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _buildLegenda(),
        const SizedBox(height: 16),
        for (final ano in anos) ...[
          _buildAnoSection(ano, agrupado[ano] ?? const {}, compacto: compacto),
          const SizedBox(height: 20),
        ],
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: Text('Adicionar ano ${menoAno - 1}'),
            onPressed: () => setState(() => _anosExtras.add(menoAno - 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildLegenda() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          _buildLegendaItem(const Color(0xFF1565C0), 'Mês lançado — clique para editar ou use ⋮ para recibos e demonstrativos'),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(Color cor, String texto) {
    return Expanded(
      child: Row(
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
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnoSection(
    int ano,
    Map<int, Competencia> competenciasDoAno, {
    required bool compacto,
  }) {
    final theme = Theme.of(context);
    final total = competenciasDoAno.length;
    final proporcao = total / 12;

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
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ano $ano',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$total de 12 meses lançados',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: proporcao,
                      minHeight: 6,
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
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
              itemCount: 12,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: compacto ? 220 : 260,
                mainAxisExtent: compacto ? 108 : 116,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (ctx, index) {
                final mes = index + 1;
                return _buildMesTile(ano, mes, competenciasDoAno[mes]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesTile(int ano, int mes, Competencia? comp) {
    return comp == null ? _buildMesVazio(ano, mes) : _buildMesLancado(comp);
  }

  Widget _buildMesVazio(int ano, int mes) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _novoMes(mes, ano),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nomeMesTitulo(mes),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.add_circle_outline, size: 18, color: Colors.grey.shade400),
                ],
              ),
              Text(
                'Não lançado',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                'Clique para lançar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMesLancado(Competencia comp) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM');
    final totalContas = comp.valorContaAgua + comp.valorContaEnergia + comp.custoTotalLimpeza;

    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirEdicao(comp),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.55), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nomeMesTitulo(indiceMesPorNome(comp.mesReferencia) ?? comp.dataVencimento.month),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Mais opções',
                    color: theme.colorScheme.primary,
                    onPressed: () => _abrirAcoesMes(comp),
                  ),
                ],
              ),
              Text(
                'Venc. ${dateFormat.format(comp.dataVencimento)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              ),
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 13, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      CurrencyUtils.format(totalContas),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              'Não foi possível carregar as competências',
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
              onPressed: _carregarCompetencias,
            ),
          ],
        ),
      ),
    );
  }
}
