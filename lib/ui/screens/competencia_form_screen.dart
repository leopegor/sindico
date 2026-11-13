import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/currency_utils.dart';
import '../../core/field_help_definitions.dart';
import '../../data/database/competencia_repository.dart';
import '../../data/database/unidade_repository.dart';
import '../../domain/models/competencia.dart';
import '../../domain/models/parametros_financeiros.dart';
import '../../domain/models/unidade.dart';
import '../../domain/services/calculadora_rateio_service.dart';
import '../widgets/conferencia_card.dart';
import '../widgets/contextual_help_field.dart';
import '../widgets/app_shell.dart';
import '../widgets/botao_tema.dart';
import 'parametros_financeiros_screen.dart';

/// Tela para criação e edição de uma competência mensal de despesas.
class CompetenciaFormScreen extends StatefulWidget {
  final Competencia? competenciaExistente;

  /// Mês (1-12) sugerido ao criar uma nova competência.
  final int? mesInicial;

  /// Ano sugerido ao criar uma nova competência.
  final int? anoInicial;

  const CompetenciaFormScreen({
    super.key,
    this.competenciaExistente,
    this.mesInicial,
    this.anoInicial,
  });

  @override
  State<CompetenciaFormScreen> createState() => _CompetenciaFormScreenState();
}

class _CompetenciaFormScreenState extends State<CompetenciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _competenciaRepo = CompetenciaRepository();
  final _unidadeRepo = UnidadeRepository();

  // Controladores de texto
  late TextEditingController _mesRefController;
  late TextEditingController _anoRefController;
  late TextEditingController _dataVencController;
  late TextEditingController _nomeSindicoController;
  late TextEditingController _aptoSindicoController;
  late TextEditingController _periodoMandatoController;

  // Água
  late TextEditingController _valorContaAguaController;
  late TextEditingController _valorEsgotoTotalController;
  late TextEditingController _taxaMinimaAguaController;
  late TextEditingController _consumoAguaM3Controller;
  late TextEditingController _fmrhController;

  // Luz
  late TextEditingController _valorContaEnergiaController;
  late TextEditingController _consumoEnergiaKwhController;

  // Limpeza
  late TextEditingController _servicosLimpezaController;
  late TextEditingController _materiaisLimpezaController;

  // Outros
  late TextEditingController _limpezaCaixasAguaController;
  late TextEditingController _discriminacaoOutrasDespesasController;
  late TextEditingController _fundoManutencaoController;
  late TextEditingController _discriminacaoFundoManutencaoController;

  // Seguro
  late TextEditingController _valorApoliceController;
  late TextEditingController _numeroParcelasController;

  // Juros e Multa
  late TextEditingController _jurosMoraController;
  late TextEditingController _multaMoraController;

  DateTime _dataVencimentoSelecionada = DateTime.now().add(
    const Duration(days: 15),
  );
  int _divisorRateioSindico = 11;
  double _fatorAtraso = 0.95;
  List<Unidade> _unidades = [];
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _inicializarValores();
    _carregarDadosIniciais();
  }

  int get _divisorNormalizado => (_divisorRateioSindico == 10) ? 10 : 11;

  void _inicializarValores() {
    final comp = widget.competenciaExistente ?? Competencia.exemploSetembro2026;
    final mesInicial = widget.mesInicial;
    final anoInicial = widget.anoInicial;

    if (widget.competenciaExistente != null) {
      _dataVencimentoSelecionada = comp.dataVencimento;
    } else if (mesInicial != null && anoInicial != null) {
      // Novo lançamento a partir de um mês específico (ex.: tile vazio do ano)
      _dataVencimentoSelecionada = DateTime(anoInicial, mesInicial + 1, 15);
    } else {
      // Se for novo, sugere o dia 15 do próximo mês
      final proximoMes = DateTime.now();
      _dataVencimentoSelecionada = DateTime(
        proximoMes.year,
        proximoMes.month,
        15,
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    _mesRefController = TextEditingController(
      text:
          widget.competenciaExistente?.mesReferencia ??
          (mesInicial != null
              ? _nomeMesPorIndice(mesInicial)
              : _obterNomeMesPadrao(_dataVencimentoSelecionada)),
    );
    _anoRefController = TextEditingController(
      text:
          widget.competenciaExistente?.anoReferencia.toString() ??
          (anoInicial?.toString() ??
              _dataVencimentoSelecionada.year.toString()),
    );
    _dataVencController = TextEditingController(
      text: dateFormat.format(_dataVencimentoSelecionada),
    );
    _nomeSindicoController = TextEditingController(text: comp.nomeSindico);
    _aptoSindicoController = TextEditingController(text: comp.aptoSindico);
    _periodoMandatoController = TextEditingController(
      text: comp.periodoMandato,
    );

    // Água
    _valorContaAguaController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.valorContaAgua),
    );
    _valorEsgotoTotalController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.valorEsgotoTotal),
    );
    _taxaMinimaAguaController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.taxaMinimaAgua),
    );
    _consumoAguaM3Controller = TextEditingController(
      text: comp.consumoAguaM3 != null
          ? comp.consumoAguaM3!.toStringAsFixed(0)
          : '',
    );
    _fmrhController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.fmrh),
    );

    // Luz
    _valorContaEnergiaController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.valorContaEnergia),
    );
    _consumoEnergiaKwhController = TextEditingController(
      text: comp.consumoEnergiaKwh != null
          ? comp.consumoEnergiaKwh!.toStringAsFixed(0)
          : '',
    );

    // Limpeza
    _servicosLimpezaController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.servicosLimpeza),
    );
    _materiaisLimpezaController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.materiaisLimpeza),
    );

    // Outros
    _limpezaCaixasAguaController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.limpezaCaixasAgua),
    );
    _discriminacaoOutrasDespesasController = TextEditingController(
      text: comp.discriminacaoOutrasDespesas ?? '',
    );
    _fundoManutencaoController = TextEditingController(
      text: CurrencyUtils.formatClean(comp.fundoManutencaoMensal),
    );
    _discriminacaoFundoManutencaoController = TextEditingController(
      text: comp.discriminacaoFundoManutencao ?? '',
    );

    // Seguro
    _valorApoliceController = TextEditingController(
      text: comp.valorApolice != null
          ? CurrencyUtils.formatClean(comp.valorApolice!)
          : '',
    );
    _numeroParcelasController = TextEditingController(
      text: comp.numeroParcelas != null ? comp.numeroParcelas!.toString() : '',
    );

    // Juros e Multa
    _jurosMoraController = TextEditingController(
      text: (comp.jurosMoraMensal * 100)
          .toStringAsFixed(2)
          .replaceAll('.', ','),
    );
    _multaMoraController = TextEditingController(
      text: (comp.multaMora * 100).toStringAsFixed(2).replaceAll('.', ','),
    );

    _divisorRateioSindico = comp.divisorRateioSindico == 10 ? 10 : 11;
    _fatorAtraso = comp.fatorAtraso > 0 ? comp.fatorAtraso : 0.95;
  }

  static const List<String> _nomesMeses = [
    'JANEIRO',
    'FEVEREIRO',
    'MARÇO',
    'ABRIL',
    'MAIO',
    'JUNHO',
    'JULHO',
    'AGOSTO',
    'SETEMBRO',
    'OUTUBRO',
    'NOVEMBRO',
    'DEZEMBRO',
  ];

  String _nomeMesPorIndice(int mes) => _nomesMeses[(mes - 1).clamp(0, 11)];

  String _obterNomeMesPadrao(DateTime date) {
    // Se vencimento é no dia 10 ou 15, o mês de referência é o anterior
    final mesRefIndex = (date.month - 2 + 12) % 12;
    return _nomesMeses[mesRefIndex];
  }

  String _obterProximoMesNome(String mesAtual) {
    final idx = _nomesMeses.indexOf(mesAtual.toUpperCase().trim());
    if (idx >= 0) {
      return _nomesMeses[(idx + 1) % 12];
    }
    return 'JANEIRO';
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final unidades = await _unidadeRepo.getTodas();
      if (mounted) {
        setState(() => _unidades = unidades);
      }
    } catch (e) {
      debugPrint('Erro ao carregar unidades: $e');
    }

    // Se estiver criando uma nova competência, sugere com base na última cadastrada
    if (widget.competenciaExistente == null) {
      try {
        final maisRecente = await _competenciaRepo.getMaisRecente();
        if (maisRecente != null && mounted) {
          final definirData =
              widget.mesInicial == null || widget.anoInicial == null;
          final proximoMesNome = _obterProximoMesNome(
            maisRecente.mesReferencia,
          );
          final novoAno = maisRecente.mesReferencia.toUpperCase() == 'DEZEMBRO'
              ? maisRecente.anoReferencia + 1
              : maisRecente.anoReferencia;
          final novoVenc = DateTime(
            maisRecente.dataVencimento.year,
            maisRecente.dataVencimento.month + 1,
            maisRecente.dataVencimento.day,
          );

          setState(() {
            if (definirData) {
              _mesRefController.text = proximoMesNome;
              _anoRefController.text = novoAno.toString();
              _dataVencimentoSelecionada = novoVenc;
              _dataVencController.text = DateFormat('dd/MM/yyyy')
                  .format(novoVenc);
            }
            _nomeSindicoController.text = maisRecente.nomeSindico;
            _aptoSindicoController.text = maisRecente.aptoSindico;
            _periodoMandatoController.text = maisRecente.periodoMandato;
            _divisorRateioSindico = maisRecente.divisorRateioSindico == 10
                ? 10
                : 11;
            _fatorAtraso = maisRecente.fatorAtraso > 0
                ? maisRecente.fatorAtraso
                : 0.95;
            _jurosMoraController.text = (maisRecente.jurosMoraMensal * 100)
                .toStringAsFixed(2)
                .replaceAll('.', ',');
            _multaMoraController.text = (maisRecente.multaMora * 100)
                .toStringAsFixed(2)
                .replaceAll('.', ',');
          });
        }
      } catch (e) {
        debugPrint('Erro ao buscar competência mais recente: $e');
      }
    }

    // Em uma nova competência, captura o síndico atual do cadastro de unidades.
    // Competências antigas mantêm o aptoSindico gravado no momento do preenchimento.
    if (widget.competenciaExistente == null && _unidades.isNotEmpty) {
      Unidade? sindicoCadastro;
      for (final u in _unidades) {
        if (u.isSindico) {
          sindicoCadastro = u;
          break;
        }
      }
      final sindico = sindicoCadastro;
      if (sindico != null && mounted) {
        setState(() {
          _aptoSindicoController.text = sindico.codigo;
          final nome = sindico.nomeMorador.trim();
          if (nome.isNotEmpty) {
            _nomeSindicoController.text = nome;
          }
        });
      }
    }
  }

  void _zerarValoresContas() {
    setState(() {
      _valorContaAguaController.text = '0,00';
      _valorEsgotoTotalController.text = '0,00';
      _taxaMinimaAguaController.text = '38,60';
      _consumoAguaM3Controller.text = '';
      _fmrhController.text = '0,00';
      _valorContaEnergiaController.text = '0,00';
      _consumoEnergiaKwhController.text = '';
      _servicosLimpezaController.text = '0,00';
      _materiaisLimpezaController.text = '0,00';
      _limpezaCaixasAguaController.text = '0,00';
      _discriminacaoOutrasDespesasController.text = '';
      _fundoManutencaoController.text = '100,00';
      _discriminacaoFundoManutencaoController.text = '';
      _valorApoliceController.text = '';
      _numeroParcelasController.text = '';
    });
  }

  void _carregarValoresExemplo() {
    final comp = Competencia.exemploSetembro2026;
    setState(() {
      _valorContaAguaController.text = CurrencyUtils.formatClean(
        comp.valorContaAgua,
      );
      _valorEsgotoTotalController.text = CurrencyUtils.formatClean(
        comp.valorEsgotoTotal,
      );
      _taxaMinimaAguaController.text = CurrencyUtils.formatClean(
        comp.taxaMinimaAgua,
      );
      _consumoAguaM3Controller.text =
          comp.consumoAguaM3?.toStringAsFixed(0) ?? '';
      _fmrhController.text = CurrencyUtils.formatClean(comp.fmrh);
      _valorContaEnergiaController.text = CurrencyUtils.formatClean(
        comp.valorContaEnergia,
      );
      _consumoEnergiaKwhController.text =
          comp.consumoEnergiaKwh?.toStringAsFixed(0) ?? '';
      _servicosLimpezaController.text = CurrencyUtils.formatClean(
        comp.servicosLimpeza,
      );
      _materiaisLimpezaController.text = CurrencyUtils.formatClean(
        comp.materiaisLimpeza,
      );
      _limpezaCaixasAguaController.text = CurrencyUtils.formatClean(
        comp.limpezaCaixasAgua,
      );
      _discriminacaoOutrasDespesasController.text =
          comp.discriminacaoOutrasDespesas ?? '';
      _fundoManutencaoController.text = CurrencyUtils.formatClean(
        comp.fundoManutencaoMensal,
      );
      _discriminacaoFundoManutencaoController.text =
          comp.discriminacaoFundoManutencao ?? '';
    });
  }

  @override
  void dispose() {
    _mesRefController.dispose();
    _anoRefController.dispose();
    _dataVencController.dispose();
    _nomeSindicoController.dispose();
    _aptoSindicoController.dispose();
    _periodoMandatoController.dispose();
    _valorContaAguaController.dispose();
    _valorEsgotoTotalController.dispose();
    _taxaMinimaAguaController.dispose();
    _consumoAguaM3Controller.dispose();
    _fmrhController.dispose();
    _valorContaEnergiaController.dispose();
    _consumoEnergiaKwhController.dispose();
    _servicosLimpezaController.dispose();
    _materiaisLimpezaController.dispose();
    _limpezaCaixasAguaController.dispose();
    _discriminacaoOutrasDespesasController.dispose();
    _fundoManutencaoController.dispose();
    _discriminacaoFundoManutencaoController.dispose();
    _valorApoliceController.dispose();
    _numeroParcelasController.dispose();
    _jurosMoraController.dispose();
    _multaMoraController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataVencimento() async {
    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: _dataVencimentoSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida != null) {
      setState(() {
        _dataVencimentoSelecionada = escolhida;
        _dataVencController.text = DateFormat('dd/MM/yyyy').format(escolhida);
      });
    }
  }

  Future<void> _abrirParametrosFinanceiros() async {
    final parametros = await Navigator.of(context).push<ParametrosFinanceiros>(
      MaterialPageRoute(
        builder: (_) => ParametrosFinanceirosScreen(
          iniciais: ParametrosFinanceiros(
            jurosMoraMensal:
                CurrencyUtils.parse(_jurosMoraController.text) / 100.0,
            multaMora: CurrencyUtils.parse(_multaMoraController.text) / 100.0,
            fatorAtraso: _fatorAtraso,
            divisorRateioSindico: _divisorNormalizado,
          ),
          competenciaRotulo:
              '${_mesRefController.text.trim()}/${_anoRefController.text.trim()}',
        ),
      ),
    );

    if (parametros == null || !mounted) return;
    setState(() {
      _jurosMoraController.text = (parametros.jurosMoraMensal * 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _multaMoraController.text = (parametros.multaMora * 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _fatorAtraso = parametros.fatorAtraso;
      _divisorRateioSindico = parametros.divisorRateioSindico;
    });
  }

  Competencia _construirCompetenciaFormulario() {
    return Competencia(
      id: widget.competenciaExistente?.id,
      mesReferencia: _mesRefController.text.trim().toUpperCase(),
      anoReferencia:
          int.tryParse(_anoRefController.text.trim()) ?? DateTime.now().year,
      dataVencimento: _dataVencimentoSelecionada,
      nomeSindico: _nomeSindicoController.text.trim(),
      aptoSindico: _aptoSindicoController.text.trim(),
      periodoMandato: _periodoMandatoController.text.trim(),
      valorContaAgua: CurrencyUtils.parse(_valorContaAguaController.text),
      valorEsgotoTotal: CurrencyUtils.parse(_valorEsgotoTotalController.text),
      taxaMinimaAgua: CurrencyUtils.parse(_taxaMinimaAguaController.text),
      consumoAguaM3: double.tryParse(
        _consumoAguaM3Controller.text.replaceAll(',', '.'),
      ),
      fmrh: CurrencyUtils.parse(_fmrhController.text),
      consumoEnergiaKwh: double.tryParse(
        _consumoEnergiaKwhController.text.replaceAll(',', '.'),
      ),
      valorContaEnergia: CurrencyUtils.parse(_valorContaEnergiaController.text),
      servicosLimpeza: CurrencyUtils.parse(_servicosLimpezaController.text),
      materiaisLimpeza: CurrencyUtils.parse(_materiaisLimpezaController.text),
      limpezaCaixasAgua: CurrencyUtils.parse(_limpezaCaixasAguaController.text),
      discriminacaoOutrasDespesas:
          _discriminacaoOutrasDespesasController.text.trim().isEmpty
          ? null
          : _discriminacaoOutrasDespesasController.text.trim(),
      fundoManutencaoMensal: CurrencyUtils.parse(
        _fundoManutencaoController.text,
      ),
      discriminacaoFundoManutencao:
          _discriminacaoFundoManutencaoController.text.trim().isEmpty
          ? null
          : _discriminacaoFundoManutencaoController.text.trim(),
      valorApolice: _valorApoliceController.text.trim().isNotEmpty
          ? CurrencyUtils.parse(_valorApoliceController.text)
          : null,
      numeroParcelas: int.tryParse(_numeroParcelasController.text.trim()),
      jurosMoraMensal: (CurrencyUtils.parse(_jurosMoraController.text)) / 100.0,
      multaMora: (CurrencyUtils.parse(_multaMoraController.text)) / 100.0,
      divisorRateioSindico: _divisorNormalizado,
      fatorAtraso: _fatorAtraso,
      criadoEm: widget.competenciaExistente?.criadoEm ?? DateTime.now(),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, corrija os campos inválidos antes de salvar.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final competencia = _construirCompetenciaFormulario();

      if (competencia.id != null) {
        await _competenciaRepo.atualizar(competencia);
      } else {
        await _competenciaRepo.inserir(competencia);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Competência ${competencia.mesReferencia}/${competencia.anoReferencia} salva com sucesso!',
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar competência: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compAtual = _construirCompetenciaFormulario();
    final theme = Theme.of(context);
    final fechamentoAtual = _unidades.isNotEmpty
        ? CalculadoraRateioService.calcular(
            competencia: compAtual,
            unidades: _unidades,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.competenciaExistente != null
              ? 'Editar Competência (${widget.competenciaExistente!.mesReferencia}/${widget.competenciaExistente!.anoReferencia})'
              : 'Novo Mês de Rateio',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Salvar',
            onPressed: _salvando ? null : _salvar,
          ),
          const BotaoTema(),
        ],
      ),
      body: _salvando
          ? const Center(child: CircularProgressIndicator())
          : ConteudoCentralizado(
              larguraMaxima: 1100,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Checklist de conferência em tempo real
                    if (fechamentoAtual != null) ...[
                      ConferenciaCard(fechamento: fechamentoAtual),
                      const SizedBox(height: 24),
                    ],

                    // Barra de Ações Rápidas de Preenchimento
                    Card(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.competenciaExistente != null
                                  ? Icons.edit_note
                                  : Icons.auto_awesome,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.competenciaExistente != null
                                    ? 'Editando mês existente'
                                    : 'Ações rápidas de preenchimento:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text(
                                'Zerar Contas',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: _zerarValoresContas,
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.history, size: 16),
                              label: const Text(
                                'Exemplo',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: _carregarValoresExemplo,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. Identificação
                    _buildSecaoCard(
                      titulo: '1. Identificação da Competência',
                      subtitulo: 'Mês de referência, vencimento e dados da administração',
                      icone: Icons.calendar_month,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.mesReferencia,
                                controller: _mesRefController,
                                onChanged: (_) => setState(() {}),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Informe o mês'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _anoRefController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Ano',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Obrigatório';
                                  final ano = int.tryParse(v.trim());
                                  if (ano == null || ano < 2000 || ano > 2100)
                                    return 'Ano inválido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        ContextualHelpField(
                          helpInfo: FieldHelpCatalog.dataVencimento,
                          controller: _dataVencController,
                          readOnly: true,
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                          onTap: _selecionarDataVencimento,
                        ),
                        ContextualHelpField(
                          helpInfo: FieldHelpCatalog.nomeSindico,
                          controller: _nomeSindicoController,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Informe o nome do síndico'
                              : null,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.aptoSindico,
                                controller: _aptoSindicoController,
                                onChanged: (_) => setState(() {}),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Informe o apto'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.periodoMandato,
                                controller: _periodoMandatoController,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 2. Água (CORSAN)
                    _buildSecaoCard(
                      titulo: '2. Conta de Água (CORSAN)',
                      subtitulo: 'Esgoto por unidade, taxa mínima da Loja e rateio por pessoas',
                      icone: Icons.water_drop,
                      corDestaque: Colors.blue.shade700,
                      children: [
                        ContextualHelpField(
                          helpInfo: FieldHelpCatalog.valorContaAgua,
                          controller: _valorContaAguaController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixText: 'R\$ ',
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = CurrencyUtils.parse(v);
                            if (val <= 0)
                              return 'Informe o valor total da conta d\'água';
                            return null;
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.valorEsgotoTotal,
                                controller: _valorEsgotoTotalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'R\$ ',
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  final val = CurrencyUtils.parse(v);
                                  if (val < 0) return 'Não pode ser negativo';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.taxaMinimaAgua,
                                controller: _taxaMinimaAguaController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'R\$ ',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.consumoAguaM3,
                                controller: _consumoAguaM3Controller,
                                keyboardType: TextInputType.number,
                                suffixText: 'm³',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.fmrh,
                                controller: _fmrhController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'R\$ ',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 3. Energia Elétrica (RGE)
                    _buildSecaoCard(
                      titulo: '3. Energia Elétrica (RGE)',
                      subtitulo: 'Áreas comuns divididas entre os 10 apartamentos (Loja isenta)',
                      icone: Icons.bolt,
                      corDestaque: Colors.amber.shade800,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.valorContaEnergia,
                                controller: _valorContaEnergiaController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'R\$ ',
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  final val = CurrencyUtils.parse(v);
                                  if (val <= 0)
                                    return 'Informe o valor da conta de energia';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.consumoEnergiaKwh,
                                controller: _consumoEnergiaKwhController,
                                keyboardType: TextInputType.number,
                                suffixText: 'KWh',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 4. Limpeza
                    _buildSecaoCard(
                      titulo: '4. Serviços de Limpeza',
                      subtitulo:
                          'Mão de obra e materiais divididos por 11 unidades',
                      icone: Icons.cleaning_services,
                      corDestaque: Colors.teal.shade700,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.servicosLimpeza,
                                controller: _servicosLimpezaController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'R\$ ',
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  final val = CurrencyUtils.parse(v);
                                  if (val < 0)
                                    return 'Valor não pode ser negativo';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.materiaisLimpeza,
                                controller: _materiaisLimpezaController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'R\$ ',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 5. Outras Despesas e Fundo
                    _buildSecaoCard(
                      titulo: '5. Outras Despesas e Fundo Emergencial',
                      subtitulo:
                          'Limpeza de caixas d\'água e fundo mensal preventivo',
                      icone: Icons.build_outlined,
                      children: [
                        ContextualHelpField(
                          helpInfo: FieldHelpCatalog.limpezaCaixasAgua,
                          controller: _limpezaCaixasAguaController,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          prefixText: 'R\$ ',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _discriminacaoOutrasDespesasController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 2,
                          minLines: 1,
                          decoration: InputDecoration(
                            labelText: 'Discriminação das Outras Despesas',
                            hintText: 'Ex.: Limpeza de caixas d\'água, dedetização, reparos...',
                            helperText: 'Descreva quais despesas compõem os Outros/Extraordinários',
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.edit_note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ContextualHelpField(
                          helpInfo: FieldHelpCatalog.fundoManutencaoMensal,
                          controller: _fundoManutencaoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixText: 'R\$ ',
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = CurrencyUtils.parse(v);
                            if (val < 0) return 'O fundo não pode ser negativo';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _discriminacaoFundoManutencaoController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 2,
                          minLines: 1,
                          decoration: InputDecoration(
                            labelText: 'Discriminação do Fundo Emergencial',
                            hintText:
                                'Ex.: Reserva para manutenções emergenciais',
                            helperText:
                                'Descreva a finalidade do fundo de manutenção',
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.edit_note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 6. Seguro Obrigatório
                    _buildSecaoCard(
                      titulo: '6. Seguro Predial Obrigatório',
                      subtitulo: 'Deixe vazio caso não haja apólice no mês',
                      icone: Icons.shield_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.valorApoliceSeguro,
                                controller: _valorApoliceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'R\$ ',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: ContextualHelpField(
                                helpInfo: FieldHelpCatalog.numeroParcelasSeguro,
                                controller: _numeroParcelasController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 7. Parâmetros Legais e Financeiros
                    _buildSecaoCard(
                      titulo: '7. Juros, Multa e Percentuais',
                      subtitulo:
                          'Configurações financeiras exclusivas deste mês',
                      icone: Icons.percent,
                      children: [
                        _buildResumoParametro(
                          'Juros de mora',
                          '${CurrencyUtils.formatPercent(CurrencyUtils.parse(_jurosMoraController.text) / 100.0)} ao mês',
                        ),
                        const SizedBox(height: 8),
                        _buildResumoParametro(
                          'Multa de mora',
                          CurrencyUtils.formatPercent(
                            CurrencyUtils.parse(_multaMoraController.text) /
                                100.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildResumoParametro(
                          'Acréscimo até 30 dias',
                          CurrencyUtils.formatPercent(
                            _fatorAtraso > 0 ? (1 / _fatorAtraso) - 1 : 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildResumoParametro(
                          'Divisor do rateio do síndico',
                          '$_divisorNormalizado unidades',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.tune),
                            label: const Text('Configurar juros e percentuais'),
                            onPressed: _abrirParametrosFinanceiros,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botão Salvar
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(
                          widget.competenciaExistente != null
                              ? 'Salvar Alterações'
                              : 'Salvar e Gerar Recibos',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _salvando ? null : _salvar,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecaoCard({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    Color? corDestaque,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final cor = corDestaque ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da seção com destaque de cor
          Container(
            color: cor.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                  child: Icon(icone, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Corpo da seção
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoParametro(String rotulo, String valor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: const TextStyle(fontSize: 13))),
          Text(
            valor,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
