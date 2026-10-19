import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/core/supabase_config.dart';
import 'package:projeto_sindico/data/backend.dart';
import 'package:projeto_sindico/data/database/competencia_repository.dart';
import 'package:projeto_sindico/data/database/divida_repository.dart';
import 'package:projeto_sindico/data/database/pagamento_repository.dart';
import 'package:projeto_sindico/data/database/unidade_repository.dart';
import 'package:projeto_sindico/data/supabase/supabase_servico.dart';
import 'package:projeto_sindico/domain/models/abatimento_divida.dart';
import 'package:projeto_sindico/domain/models/competencia.dart';
import 'package:projeto_sindico/domain/models/divida_anterior.dart';
import 'package:projeto_sindico/domain/models/pagamento.dart';
import 'package:projeto_sindico/domain/models/unidade.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Teste de integração real contra o projeto Supabase.
///
/// Fica desativado por padrão (não deve depender de rede no CI). Para rodar:
/// `flutter test test/supabase_live_test.dart --dart-define=SUPABASE_LIVE=true`
const bool _ativo = bool.fromEnvironment('SUPABASE_LIVE', defaultValue: false);

/// Dados exclusivos do teste, removidos ao final da execução.
const int _anoTeste = 2099;
const String _mesTeste = 'DEZEMBRO';
const String _unidadeTeste = '403';

void main() {
  if (!_ativo) {
    test(
      'integração real com o Supabase',
      () {},
      skip: 'Ative com --dart-define=SUPABASE_LIVE=true',
    );
    return;
  }

  late SupabaseClient cliente;
  final competenciaRepo = CompetenciaRepository();
  final unidadeRepo = UnidadeRepository();
  final pagamentoRepo = PagamentoRepository();
  final dividaRepo = DividaRepository();

  setUpAll(() {
    cliente = SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
    SupabaseServico.injetarCliente(cliente);
    Backend.modo = BackendModo.supabase;
  });

  tearDownAll(() async {
    for (final competencia in await competenciaRepo.getTodas()) {
      if (competencia.anoReferencia == _anoTeste &&
          competencia.mesReferencia == _mesTeste &&
          competencia.id != null) {
        await competenciaRepo.excluir(competencia.id!);
      }
    }
    await dividaRepo.removerDivida(_unidadeTeste);
    SupabaseServico.injetarCliente(null);
    Backend.modo = BackendModo.local;
    cliente.dispose();
  });

  test('unidades: lista e atualização ponta a ponta', () async {
    final unidades = await unidadeRepo.getTodas();
    expect(unidades.length, greaterThanOrEqualTo(11));

    final unidade = await unidadeRepo.getPorCodigo(_unidadeTeste);
    expect(unidade, isNotNull);
    expect(unidade!.tipo, TipoUnidade.residencial);
    expect(unidade.fracaoIdeal, greaterThan(0));

    final afetadas = await unidadeRepo.atualizar(
      unidade.copyWith(nomeMorador: unidade.nomeMorador),
    );
    expect(afetadas, 1);

    await unidadeRepo.restaurarPadrao();
    expect((await unidadeRepo.getTodas()).length, greaterThanOrEqualTo(11));
  });

  test('competências: criar, ler, atualizar e excluir', () async {
    final competencia = Competencia.exemploSetembro2026.copyWith(
      mesReferencia: _mesTeste,
      anoReferencia: _anoTeste,
      dataVencimento: DateTime(_anoTeste, 12, 15),
      observacoes: 'registro de teste automatizado',
    );

    final id = await competenciaRepo.inserir(competencia);
    expect(id, greaterThan(0));

    final carregada = await competenciaRepo.getPorId(id);
    expect(carregada, isNotNull);
    expect(carregada!.mesReferencia, _mesTeste);
    expect(carregada.anoReferencia, _anoTeste);
    expect(carregada.dataVencimento, DateTime(_anoTeste, 12, 15));
    expect(carregada.valorContaAgua, competencia.valorContaAgua);

    final atualizadas = await competenciaRepo.atualizar(
      carregada.copyWith(observacoes: 'atualizado pelo teste'),
    );
    expect(atualizadas, 1);
    expect((await competenciaRepo.getPorId(id))!.observacoes,
        'atualizado pelo teste');

    final maisRecente = await competenciaRepo.getMaisRecente();
    expect(maisRecente, isNotNull);

    await competenciaRepo.excluir(id);
    expect(await competenciaRepo.getPorId(id), isNull);
  });

  test('pagamentos: upsert pelo par competência+unidade e remoção', () async {
    final competenciaId = await competenciaRepo.inserir(
      Competencia.exemploSetembro2026.copyWith(
        mesReferencia: _mesTeste,
        anoReferencia: _anoTeste,
        dataVencimento: DateTime(_anoTeste, 12, 15),
      ),
    );

    expect(await pagamentoRepo.getPorCompetencia(competenciaId), isEmpty);

    await pagamentoRepo.salvar(Pagamento(
      competenciaId: competenciaId,
      unidadeCodigo: _unidadeTeste,
      pago: true,
      dataPagamento: DateTime(_anoTeste, 12, 10, 9, 30),
      valorPago: 10.0,
    ));

    await pagamentoRepo.salvar(Pagamento(
      competenciaId: competenciaId,
      unidadeCodigo: _unidadeTeste,
      pago: true,
      valorPago: 20.0,
    ));

    final pagamentos = await pagamentoRepo.getPorCompetencia(competenciaId);
    expect(pagamentos.length, 1);
    final pagamento = pagamentos[_unidadeTeste]!;
    expect(pagamento.pago, isTrue);
    expect(pagamento.valorPago, 20.0);

    await pagamentoRepo.remover(competenciaId, _unidadeTeste);
    expect(await pagamentoRepo.getPorCompetencia(competenciaId), isEmpty);

    await competenciaRepo.excluir(competenciaId);
  });

  test('dívidas e abatimentos: gravar, ler e remover', () async {
    await dividaRepo.salvarDivida(DividaAnterior(
      unidadeCodigo: _unidadeTeste,
      valor: 123.45,
      atualizadoEm: DateTime(_anoTeste, 1, 5),
    ));
    await dividaRepo.salvarDivida(DividaAnterior(
      unidadeCodigo: _unidadeTeste,
      valor: 200.0,
      atualizadoEm: DateTime(_anoTeste, 1, 6),
    ));

    final dividas = await dividaRepo.getDividas();
    expect(dividas[_unidadeTeste]!.valor, 200.0);

    final idAbatimento = await dividaRepo.inserirAbatimento(AbatimentoDivida(
      unidadeCodigo: _unidadeTeste,
      valor: 50.0,
      data: DateTime(_anoTeste, 1, 7),
      observacao: 'teste automatizado',
      criadoEm: DateTime(_anoTeste, 1, 7),
    ));
    expect(idAbatimento, greaterThan(0));

    final abatimentos = await dividaRepo.getAbatimentos();
    expect(
      abatimentos.any((a) => a.id == idAbatimento && a.valor == 50.0),
      isTrue,
    );

    await dividaRepo.removerAbatimento(idAbatimento);
    expect(
      (await dividaRepo.getAbatimentos()).any((a) => a.id == idAbatimento),
      isFalse,
    );

    await dividaRepo.removerDivida(_unidadeTeste);
    expect((await dividaRepo.getDividas()).containsKey(_unidadeTeste), isFalse);
  });
}
