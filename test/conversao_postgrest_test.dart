import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/data/backend.dart';
import 'package:projeto_sindico/data/erro_persistencia.dart';
import 'package:projeto_sindico/data/supabase/conversao_postgrest.dart';
import 'package:projeto_sindico/domain/models/competencia.dart';
import 'package:projeto_sindico/domain/models/pagamento.dart';
import 'package:projeto_sindico/domain/models/unidade.dart';

void main() {
  group('doPostgrest', () {
    test('converte booleanos do Postgres para 0/1 do modelo', () {
      final linha = <String, dynamic>{
        'id': 7,
        'codigo': '301',
        'nome_morador': 'Ben Hur Luchese',
        'numero_pessoas': 2,
        'area_privativa': 42.46,
        'fracao_ideal': 0.0807,
        'valor_policiamento': 0,
        'tipo': 'residencial',
        'is_sindico': true,
        'participa_policiamento': false,
      };

      final convertida = doPostgrest(
        linha,
        colunasBooleanas: colunasBooleanasUnidades,
      );

      expect(convertida['is_sindico'], 1);
      expect(convertida['participa_policiamento'], 0);

      final unidade = Unidade.fromMap(convertida);
      expect(unidade.id, 7);
      expect(unidade.isSindico, isTrue);
      expect(unidade.participaPoliciamento, isFalse);
    });

    test('não altera colunas fora da lista de booleanas', () {
      final convertida = doPostgrest(
        {'pago': false, 'valor_pago': 12.5},
        colunasBooleanas: colunasBooleanasPagamentos,
      );
      expect(convertida['pago'], 0);
      expect(convertida['valor_pago'], 12.5);
    });

    test('mantém nulos e a lista de linhas é convertida em ordem', () {
      final linhas = listaDoPostgrest(
        [
          {'unidade_codigo': '101', 'pago': true},
          {'unidade_codigo': '102', 'pago': false},
        ],
        colunasBooleanas: colunasBooleanasPagamentos,
      );

      expect(linhas.map((l) => l['pago']).toList(), [1, 0]);
      final pagamento = Pagamento.fromMap({
        'competencia_id': 1,
        ...linhas.first,
      });
      expect(pagamento.pago, isTrue);
      expect(pagamento.unidadeCodigo, '101');
    });
  });

  group('paraPostgrest', () {
    test('remove o id (identity do Postgres) e converte 0/1 em booleano', () {
      const unidade = Unidade(
        id: 3,
        codigo: '302',
        nomeMorador: 'Laura',
        numeroPessoas: 2,
        areaPrivativa: 37.2,
        fracaoIdeal: 0.0707,
        isSindico: true,
        tipo: TipoUnidade.residencial,
      );

      final payload = paraPostgrest(
        unidade.toMap(),
        colunasBooleanas: colunasBooleanasUnidades,
      );

      expect(payload.containsKey('id'), isFalse);
      expect(payload['is_sindico'], isTrue);
      expect(payload['participa_policiamento'], isFalse);
      expect(payload['tipo'], 'residencial');
    });

    test('trunca colunas date para YYYY-MM-DD', () {
      final map = <String, dynamic>{
        'id': 9,
        'data_vencimento': '2026-10-15T00:00:00.000',
      };

      final payload = paraPostgrest(map, colunasData: {'data_vencimento'});
      expect(payload['data_vencimento'], '2026-10-15');
      expect(payload.containsKey('id'), isFalse);
    });

    test('mantém o id quando solicitado (upsert por chave própria)', () {
      final payload = paraPostgrest(
        {'id': 4, 'codigo': 'LOJA'},
        removerId: false,
      );
      expect(payload['id'], 4);
    });

    test('payload de competência volta a virar modelo com a data correta', () {
      final competencia = Competencia.exemploSetembro2026;
      final payload = paraPostgrest(
        competencia.toMap(),
        colunasData: {'data_vencimento'},
      );

      expect(payload['data_vencimento'], '2026-10-15');
      expect(payload['consumo_agua_m3'], competencia.consumoAguaM3);

      final idaEVolta = Competencia.fromMap({
        'id': 1,
        ...payload,
      });
      expect(idaEVolta.dataVencimento, DateTime(2026, 10, 15));
      expect(idaEVolta.mesReferencia, competencia.mesReferencia);
    });
  });

  group('Backend e erros', () {
    test('o modo padrão é local e usaSupabase acompanha o modo', () {
      final original = Backend.modo;
      addTearDown(() => Backend.modo = original);

      Backend.modo = BackendModo.local;
      expect(Backend.usaSupabase, isFalse);

      Backend.modo = BackendModo.supabase;
      expect(Backend.usaSupabase, isTrue);
    });

    test('ErroPersistencia expõe a mensagem amigável no toString', () {
      final erro = ErroPersistencia('Sem conexão com o servidor.');
      expect(erro.toString(), 'Sem conexão com o servidor.');
      expect(erro.toString().contains('Exception'), isFalse);
    });
  });
}
