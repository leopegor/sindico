import 'package:flutter/material.dart';
import '../../core/currency_utils.dart';
import '../../core/field_help_definitions.dart';
import '../../domain/models/parametros_financeiros.dart';
import '../widgets/app_shell.dart';
import '../widgets/contextual_help_field.dart';

class ParametrosFinanceirosScreen extends StatefulWidget {
  final ParametrosFinanceiros iniciais;
  final String competenciaRotulo;

  const ParametrosFinanceirosScreen({
    super.key,
    required this.iniciais,
    required this.competenciaRotulo,
  });

  @override
  State<ParametrosFinanceirosScreen> createState() =>
      _ParametrosFinanceirosScreenState();
}

class _ParametrosFinanceirosScreenState
    extends State<ParametrosFinanceirosScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _jurosController;
  late final TextEditingController _multaController;
  late final TextEditingController _fatorController;
  late int _divisor;

  @override
  void initState() {
    super.initState();
    _jurosController = TextEditingController(
      text: _formatPercentual(widget.iniciais.jurosMoraMensal),
    );
    _multaController = TextEditingController(
      text: _formatPercentual(widget.iniciais.multaMora),
    );
    _fatorController = TextEditingController(
      text: widget.iniciais.fatorAtraso.toStringAsFixed(2).replaceAll('.', ','),
    );
    _divisor =
        widget.iniciais.divisorRateioSindico == 10 ? 10 : 11;
  }

  @override
  void dispose() {
    _jurosController.dispose();
    _multaController.dispose();
    _fatorController.dispose();
    super.dispose();
  }

  String _formatPercentual(double fracao) =>
      (fracao * 100).toStringAsFixed(2).replaceAll('.', ',');

  double get _juros => CurrencyUtils.parse(_jurosController.text) / 100.0;
  double get _multa => CurrencyUtils.parse(_multaController.text) / 100.0;
  double get _fator => CurrencyUtils.parse(_fatorController.text);

  double get _acrescimoAte30Dias {
    final fator = _fator;
    if (fator <= 0) return 0;
    return (1 / fator) - 1;
  }

  void _aplicar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ParametrosFinanceiros(
        jurosMoraMensal: _juros,
        multaMora: _multa,
        fatorAtraso: _fator,
        divisorRateioSindico: _divisor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juros e Percentuais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Aplicar ao mês',
            onPressed: _aplicar,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ConteudoCentralizado(
          larguraMaxima: 900,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildCabecalho(),
              const SizedBox(height: 16),
              _buildSecao(
                titulo: 'Juros e multa de mora',
                subtitulo: 'Aplicados aos pagamentos após o vencimento',
                icone: Icons.percent,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ContextualHelpField(
                          helpInfo: FieldHelpCatalog.jurosMoraMensal,
                          controller: _jurosController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '% a.m.',
                          onChanged: (_) => setState(() {}),
                          validator: (valor) {
                            final juros = CurrencyUtils.parse(valor);
                            if (juros < 0 || juros > 20) {
                              return 'Informe entre 0% e 20%.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ContextualHelpField(
                          helpInfo: FieldHelpCatalog.multaMora,
                          controller: _multaController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '%',
                          onChanged: (_) => setState(() {}),
                          validator: (valor) {
                            final multa = CurrencyUtils.parse(valor);
                            if (multa < 0 || multa > 2) {
                              return 'Informe entre 0% e 2%.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSecao(
                titulo: 'Faixas de atraso',
                subtitulo: 'Acréscimo aplicado a partir do 1º dia de atraso',
                icone: Icons.trending_up,
                children: [
                  ContextualHelpField(
                    helpInfo: FieldHelpCatalog.fatorAtraso,
                    controller: _fatorController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (valor) {
                      final fator = CurrencyUtils.parse(valor);
                      if (fator <= 0 || fator > 1) {
                        return 'Informe um fator entre 0,01 e 1,00.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Acréscimo efetivo até 30 dias: '
                            '${CurrencyUtils.formatPercent(_acrescimoAte30Dias)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSimulacaoFaixas(),
                ],
              ),
              const SizedBox(height: 16),
              _buildSecao(
                titulo: 'Rateio do síndico',
                subtitulo: 'Divisor usado para distribuir a isenção operacional',
                icone: Icons.account_balance,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _divisor,
                          decoration: InputDecoration(
                            labelText: 'Divisor do Rateio do Síndico',
                            helperText: _divisor == 11
                                ? 'Divide por 11 unidades (fórmula da planilha original)'
                                : 'Divide por 10 pagantes (fechamento exato de 100% do consumo)',
                            helperMaxLines: 2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 11,
                              child: Text('11 unidades (Planilha Original)'),
                            ),
                            DropdownMenuItem(
                              value: 10,
                              child: Text('10 unidades (Fechamento Exato 100%)'),
                            ),
                          ],
                          onChanged: (valor) {
                            if (valor != null) {
                              setState(() => _divisor = valor);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, size: 20),
                        color: Theme.of(context).colorScheme.primary,
                        tooltip: 'Ver ajuda do divisor do rateio',
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: () => ContextualHelpField.mostrarAjuda(
                          context,
                          FieldHelpCatalog.divisorRateioSindico,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Aplicar ao mês',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _aplicar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.tune,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Competência ${widget.competenciaRotulo}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Estes parâmetros valem apenas para este mês.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecao({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icone, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulacaoFaixas() {
    const base = 1000.0;
    final fator = _fator > 0 ? _fator : 0.95;
    final ate30 = base / fator;
    final multa = ate30 * _multa;
    final f30a60 = ate30 * (1 + _juros) + multa;
    final f60a90 = f30a60 * (1 + _juros);
    final f90a120 = f60a90 * (1 + _juros);
    final f120a150 = f90a120 * (1 + _juros);
    final f150a180 = f120a150 * (1 + _juros);

    final linhas = <(String, double)>[
      ('Até o vencimento', base),
      ('Até 30 dias', ate30),
      ('30 a 60 dias', f30a60),
      ('60 a 90 dias', f60a90),
      ('90 a 120 dias', f90a120),
      ('120 a 150 dias', f120a150),
      ('150 a 180 dias', f150a180),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Simulação sobre R\$ 1.000,00',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'Valor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < linhas.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: i < linhas.length - 1
                    ? Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      linhas[i].$1,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    CurrencyUtils.format(linhas[i].$2),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
