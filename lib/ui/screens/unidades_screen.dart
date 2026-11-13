import 'package:flutter/material.dart';

import '../../data/database/unidade_repository.dart';
import '../../domain/models/unidade.dart';
import '../widgets/app_shell.dart';
import 'balanco_pagamentos_screen.dart';

/// Tela para gerenciamento do cadastro das 11 unidades do condomínio.
class UnidadesScreen extends StatefulWidget {
  const UnidadesScreen({super.key});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  final UnidadeRepository _unidadeRepo = UnidadeRepository();
  bool _carregando = true;
  String? _erro;
  List<Unidade> _unidades = [];

  @override
  void initState() {
    super.initState();
    _carregarUnidades();
  }

  Future<void> _carregarUnidades() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _unidadeRepo.getTodas();
      if (!mounted) return;
      setState(() => _unidades = lista);
    } catch (e) {
      debugPrint('Erro ao carregar unidades: $e');
      if (!mounted) return;
      setState(() => _erro = e.toString());
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _editarUnidade(Unidade u) async {
    final nomeController = TextEditingController(text: u.nomeMorador);
    final pessoasController = TextEditingController(
      text: u.numeroPessoas.toString(),
    );
    final areaController = TextEditingController(
      text: u.areaPrivativa.toString(),
    );
    bool isSindico = u.isSindico;
    bool policiamento = u.participaPoliciamento;
    final valorPoliciamentoController = TextEditingController(
      text: u.valorPoliciamento.toStringAsFixed(2),
    );

    final formKey = GlobalKey<FormState>();

    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          constraints: const BoxConstraints(maxWidth: 460),
          title: Text('Editar ${u.descricaoExibicao}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogSecao(
                    'Dados da Unidade',
                    Icons.home_outlined,
                    children: [
                      TextFormField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Morador / Proprietário',
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Informe o nome'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (!u.isLoja) ...[
                        TextFormField(
                          controller: pessoasController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Número de Pessoas (Moradores)',
                            helperText: 'Alimenta o rateio de água por pessoa',
                            isDense: true,
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0)
                              return 'Mínimo de 1 pessoa';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: areaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Área Privativa (m²)',
                          suffixText: 'm²',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _buildDialogSecao(
                    'Configurações',
                    Icons.tune_outlined,
                    children: [
                      if (!u.isLoja)
                        _buildDialogSwitch(
                          titulo: 'É a unidade do(a) Síndico(a)?',
                          subtitulo:
                              'Garante a isenção operacional da convenção',
                          valor: isSindico,
                          onChanged: (val) =>
                              setDialogState(() => isSindico = val),
                        ),
                      _buildDialogSwitch(
                        titulo: 'Policiamento Comunitário',
                        subtitulo: 'Contribui com o policiamento comunitário',
                        valor: policiamento,
                        onChanged: (val) =>
                            setDialogState(() => policiamento = val),
                      ),
                      if (policiamento) ...[
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: valorPoliciamentoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Valor Policiamento',
                            prefixText: 'R\$ ',
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (salvo == true) {
      try {
        final novaUnidade = u.copyWith(
          nomeMorador: nomeController.text.trim(),
          numeroPessoas: u.isLoja ? 0 : int.parse(pessoasController.text),
          areaPrivativa:
              double.tryParse(areaController.text.replaceAll(',', '.')) ??
              u.areaPrivativa,
          isSindico: isSindico,
          participaPoliciamento: policiamento,
          valorPoliciamento:
              double.tryParse(
                valorPoliciamentoController.text.replaceAll(',', '.'),
              ) ??
              0.0,
        );

        if (isSindico) {
          await _unidadeRepo.definirSindico(u.codigo);
        }
        await _unidadeRepo.atualizar(novaUnidade);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unidade ${u.descricaoExibicao} atualizada.'),
            ),
          );
        }
        _carregarUnidades();
      } catch (e) {
        debugPrint('Erro ao atualizar unidade: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar unidade: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _restaurarPadrao() async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar Cadastro Original'),
        content: const Text(
          'Deseja redefinir os nomes, moradores e áreas das 11 unidades para o cadastro original da planilha do Condomínio Evaristo Lucchese?',
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

    if (conf == true) {
      try {
        await _unidadeRepo.restaurarPadrao();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro restaurado para o padrão original.'),
            ),
          );
        }
        _carregarUnidades();
      } catch (e) {
        debugPrint('Erro ao restaurar cadastro: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao restaurar cadastro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDialogSecao(
    String titulo,
    IconData icone, {
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 18, color: const Color(0xFF1565C0)),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _buildDialogSwitch({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(titulo),
      subtitle: Text(subtitulo),
      value: valor,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMoradores = _unidades.fold<int>(
      0,
      (acc, u) => acc + (u.isLoja ? 0 : u.numeroPessoas),
    );
    final totalArea = _unidades.fold<double>(
      0,
      (acc, u) => acc + u.areaPrivativa,
    );
    final comMorador = _unidades
        .where((u) => u.nomeMorador.trim().isNotEmpty)
        .length;
    final compacto = MediaQuery.sizeOf(context).width < 600;

    return DefaultTabController(
      length: 2,
      child: PainelScaffold(
        titulo: 'Unidades',
        larguraMaximaConteudo: 1200,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restaurar padrão da planilha',
            onPressed: _restaurarPadrao,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    icon: Icon(Icons.home_work_outlined),
                    text: 'Cadastro de Unidades',
                  ),
                  Tab(icon: Icon(Icons.balance), text: 'Balanço de Pagamentos'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                ? _buildErro()
                : _buildConteudo(
                    totalMoradores: totalMoradores,
                    totalArea: totalArea,
                    comMorador: comMorador,
                    compacto: compacto,
                  ),
            const BalancoPagamentosScreen(embutido: true),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo({
    required int totalMoradores,
    required double totalArea,
    required int comMorador,
    required bool compacto,
  }) {
    final theme = Theme.of(context);
    final total = _unidades.length;
    final proporcao = total == 0 ? 0.0 : comMorador / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildLegenda(),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apartment,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unidades do Condomínio',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$total unidades • $totalMoradores moradores • ${totalArea.toStringAsFixed(2)} m²',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message:
                          '$comMorador de $total unidades com morador informado',
                      child: SizedBox(
                        width: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: proporcao,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
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
                  itemCount: _unidades.length,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: compacto ? 240 : 300,
                    mainAxisExtent: compacto ? 118 : 128,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (ctx, index) =>
                      _buildUnidadeTile(_unidades[index]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegenda() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _buildLegendaItem(const Color(0xFF1565C0), 'Apartamento'),
          _buildLegendaItem(const Color(0xFF6A1B9A), 'Loja (comercial)'),
          _buildLegendaItem(const Color(0xFFB26A00), 'Unidade do Síndico'),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(Color cor, String texto) {
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildUnidadeTile(Unidade u) {
    final theme = Theme.of(context);
    final escuro = theme.brightness == Brightness.dark;
    final cor = u.isSindico
        ? (escuro ? Colors.amberAccent.shade200 : const Color(0xFFB26A00))
        : u.isLoja
        ? (escuro ? Colors.purpleAccent.shade100 : const Color(0xFF6A1B9A))
        : theme.colorScheme.primary;
    final icone = u.isLoja ? Icons.storefront : Icons.home;

    return Material(
      color: cor.withValues(alpha: escuro ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editarUnidade(u),
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
                      u.descricaoExibicao,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (u.isSindico)
                    _buildTag('Síndico', cor)
                  else if (u.isLoja)
                    _buildTag('Comercial', cor),
                ],
              ),
              Text(
                u.nomeMorador.trim().isEmpty
                    ? 'Sem morador cadastrado'
                    : u.nomeMorador,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  if (!u.isLoja) ...[
                    Icon(
                      Icons.people_outline,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${u.numeroPessoas}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Icon(
                    Icons.square_foot,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${u.areaPrivativa.toStringAsFixed(2)} m²',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Fração ideal: ${(u.fracaoIdeal * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 14, color: cor),
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

  Widget _buildErro() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar as unidades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _erro ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              onPressed: _carregarUnidades,
            ),
          ],
        ),
      ),
    );
  }
}
