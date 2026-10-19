import '../../domain/models/competencia.dart';
import '../../domain/services/validacao_competencia.dart';
import '../repositorios.dart';
import 'conversao_postgrest.dart';
import 'supabase_servico.dart';

/// Acesso às competências mensais no Supabase (Postgres).
///
/// Espelha 1:1 a API de [CompetenciaRepositoryLocal] mantendo as mesmas
/// regras de validação e ordenação.
class CompetenciaRepositorioSupabase implements CompetenciaRepositorio {
  static const _tabela = 'competencias';

  Map<String, dynamic> _payload(Competencia comp) =>
      paraPostgrest(comp.toMap(), colunasData: {'data_vencimento'});

  @override
  Future<List<Competencia>> getTodas() => SupabaseServico.executar(
        () async {
          final linhas = await SupabaseServico.tabela(_tabela)
              .select()
              .order('ano_referencia', ascending: false)
              .order('data_vencimento', ascending: false)
              .order('id', ascending: false);
          return listaDoPostgrest(linhas).map(Competencia.fromMap).toList();
        },
        contexto: 'carregar as competências',
      );

  @override
  Future<Competencia?> getPorId(int id) => SupabaseServico.executar(
        () async {
          final linhas = await SupabaseServico.tabela(_tabela)
              .select()
              .eq('id', id)
              .limit(1);
          if (linhas.isEmpty) return null;
          return Competencia.fromMap(doPostgrest(linhas.first));
        },
        contexto: 'carregar a competência',
      );

  @override
  Future<Competencia?> getMaisRecente() => SupabaseServico.executar(
        () async {
          final linhas = await SupabaseServico.tabela(_tabela)
              .select()
              .order('ano_referencia', ascending: false)
              .order('data_vencimento', ascending: false)
              .order('id', ascending: false)
              .limit(1);
          if (linhas.isEmpty) return null;
          return Competencia.fromMap(doPostgrest(linhas.first));
        },
        contexto: 'carregar a competência mais recente',
      );

  @override
  Future<int> inserir(Competencia competencia) {
    validarCompetencia(competencia);
    return SupabaseServico.executar(
      () async {
        final linha = await SupabaseServico.tabela(_tabela)
            .insert(_payload(competencia))
            .select('id')
            .single();
        return (linha['id'] as num).toInt();
      },
      contexto: 'criar a competência',
    );
  }

  @override
  Future<int> atualizar(Competencia competencia) {
    if (competencia.id == null) {
      throw ArgumentError('Competência precisa de um ID para ser atualizada.');
    }
    validarCompetencia(competencia);
    return SupabaseServico.executar(
      () async {
        await SupabaseServico.tabela(_tabela)
            .update(_payload(competencia))
            .eq('id', competencia.id!);
        return 1;
      },
      contexto: 'atualizar a competência',
    );
  }

  @override
  Future<int> excluir(int id) => SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_tabela).delete().eq('id', id);
          return 1;
        },
        contexto: 'excluir a competência',
      );
}
