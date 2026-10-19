import '../../domain/models/unidade.dart';
import '../repositorios.dart';
import 'conversao_postgrest.dart';
import 'supabase_servico.dart';

/// Acesso às unidades do condomínio no Supabase (Postgres).
class UnidadeRepositorioSupabase implements UnidadeRepositorio {
  static const _tabela = 'unidades';

  Map<String, dynamic> _payload(Unidade unidade) =>
      paraPostgrest(unidade.toMap(), colunasBooleanas: colunasBooleanasUnidades);

  @override
  Future<List<Unidade>> getTodas() => SupabaseServico.executar(
        () async {
          final linhas = await SupabaseServico.tabela(_tabela)
              .select()
              .order('id', ascending: true);
          return listaDoPostgrest(linhas, colunasBooleanas: colunasBooleanasUnidades)
              .map(Unidade.fromMap)
              .toList();
        },
        contexto: 'carregar as unidades',
      );

  @override
  Future<Unidade?> getPorCodigo(String codigo) => SupabaseServico.executar(
        () async {
          final linhas = await SupabaseServico.tabela(_tabela)
              .select()
              .eq('codigo', codigo)
              .limit(1);
          if (linhas.isEmpty) return null;
          return Unidade.fromMap(
            doPostgrest(linhas.first, colunasBooleanas: colunasBooleanasUnidades),
          );
        },
        contexto: 'carregar a unidade',
      );

  @override
  Future<int> atualizar(Unidade unidade) => SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_tabela)
              .update(_payload(unidade))
              .eq('codigo', unidade.codigo);
          return 1;
        },
        contexto: 'atualizar a unidade',
      );

  @override
  Future<void> definirSindico(String codigoUnidade) => SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_tabela)
              .update({'is_sindico': false})
              .neq('codigo', codigoUnidade);
          await SupabaseServico.tabela(_tabela)
              .update({'is_sindico': true})
              .eq('codigo', codigoUnidade);
        },
        contexto: 'definir o síndico',
      );

  /// Restaura as 11 unidades padrão.
  ///
  /// No Supabase a operação é um *upsert* por `codigo` (não um `delete all`):
  /// pagamentos e dívidas referenciam `unidades(codigo)` com `on delete
  /// restrict`, então apagar tudo quebraria os vínculos existentes.
  @override
  Future<void> restaurarPadrao() => SupabaseServico.executar(
        () async {
          final linhas = Unidade.unidadesPadrao
              .map((u) => paraPostgrest(
                    u.toMap(),
                    colunasBooleanas: colunasBooleanasUnidades,
                  ))
              .toList();
          await SupabaseServico.tabela(_tabela)
              .upsert(linhas, onConflict: 'codigo');
        },
        contexto: 'restaurar as unidades padrão',
      );
}
