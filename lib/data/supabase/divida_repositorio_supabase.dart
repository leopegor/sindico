import '../../domain/models/abatimento_divida.dart';
import '../repositorios.dart';
import '../../domain/models/divida_anterior.dart';
import 'conversao_postgrest.dart';
import 'supabase_servico.dart';

/// Acesso a dívidas anteriores e abatimentos no Supabase (Postgres).
class DividaRepositorioSupabase implements DividaRepositorio {
  static const _dividas = 'dividas_anteriores';
  static const _abatimentos = 'abatimentos_divida';

  // ---------- Dívida anterior (valor manual) ----------

  @override
  Future<Map<String, DividaAnterior>> getDividas() => SupabaseServico.executar(
        () async {
          final linhas =
              await SupabaseServico.tabela(_dividas).select().order('unidade_codigo');
          return {
            for (final linha in listaDoPostgrest(linhas))
              (linha['unidade_codigo'] as String): DividaAnterior.fromMap(linha),
          };
        },
        contexto: 'carregar as dívidas anteriores',
      );

  @override
  Future<void> salvarDivida(DividaAnterior divida) => SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_dividas).upsert(
            paraPostgrest(divida.toMap()),
            onConflict: 'unidade_codigo',
          );
        },
        contexto: 'salvar a dívida anterior',
      );

  @override
  Future<void> removerDivida(String unidadeCodigo) => SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_dividas)
              .delete()
              .eq('unidade_codigo', unidadeCodigo);
        },
        contexto: 'remover a dívida anterior',
      );

  // ---------- Abatimentos (pagamentos parciais) ----------

  @override
  Future<List<AbatimentoDivida>> getAbatimentos() => SupabaseServico.executar(
        () async {
          final linhas = await SupabaseServico.tabela(_abatimentos)
              .select()
              .order('data', ascending: false)
              .order('id', ascending: false);
          return listaDoPostgrest(linhas).map(AbatimentoDivida.fromMap).toList();
        },
        contexto: 'carregar os abatimentos',
      );

  @override
  Future<int> inserirAbatimento(AbatimentoDivida abatimento) =>
      SupabaseServico.executar(
        () async {
          final linha = await SupabaseServico.tabela(_abatimentos)
              .insert(paraPostgrest(abatimento.toMap()))
              .select('id')
              .single();
          return (linha['id'] as num).toInt();
        },
        contexto: 'registrar o abatimento',
      );

  @override
  Future<void> removerAbatimento(int id) => SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_abatimentos).delete().eq('id', id);
        },
        contexto: 'remover o abatimento',
      );

  // ---------- Restauração de backup ----------

  @override
  Future<void> substituirDividas(List<DividaAnterior> dividas) =>
      SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_dividas).delete();
          if (dividas.isEmpty) return;
          await SupabaseServico.tabela(_dividas)
              .insert([for (final d in dividas) paraPostgrest(d.toMap())]);
        },
        contexto: 'restaurar as dívidas anteriores',
      );

  @override
  Future<void> substituirAbatimentos(List<AbatimentoDivida> abatimentos) =>
      SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_abatimentos).delete();
          if (abatimentos.isEmpty) return;
          await SupabaseServico.tabela(_abatimentos)
              .insert([for (final a in abatimentos) paraPostgrest(a.toMap())]);
        },
        contexto: 'restaurar os abatimentos',
      );
}
