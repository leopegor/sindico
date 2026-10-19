import '../../domain/models/pagamento.dart';
import '../repositorios.dart';
import 'conversao_postgrest.dart';
import 'supabase_servico.dart';

/// Acesso ao controle de pagamentos no Supabase (Postgres).
class PagamentoRepositorioSupabase implements PagamentoRepositorio {
  static const _tabela = 'pagamentos';

  Map<String, dynamic> _payload(Pagamento pagamento) =>
      paraPostgrest(pagamento.toMap(), colunasBooleanas: colunasBooleanasPagamentos);

  @override
  Future<Map<String, Pagamento>> getPorCompetencia(int competenciaId) =>
      SupabaseServico.executar(
        () async {
          final linhas = await SupabaseServico.tabela(_tabela)
              .select()
              .eq('competencia_id', competenciaId)
              .order('unidade_codigo');
          final mapa = <String, Pagamento>{};
          for (final linha in listaDoPostgrest(
            linhas,
            colunasBooleanas: colunasBooleanasPagamentos,
          )) {
            mapa[linha['unidade_codigo'] as String] = Pagamento.fromMap(linha);
          }
          return mapa;
        },
        contexto: 'carregar os pagamentos do mês',
      );

  @override
  Future<void> salvar(Pagamento pagamento) => SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_tabela).upsert(
            _payload(pagamento),
            onConflict: 'competencia_id,unidade_codigo',
          );
        },
        contexto: 'registrar o pagamento',
      );

  @override
  Future<void> remover(int competenciaId, String unidadeCodigo) =>
      SupabaseServico.executar(
        () async {
          await SupabaseServico.tabela(_tabela)
              .delete()
              .eq('competencia_id', competenciaId)
              .eq('unidade_codigo', unidadeCodigo);
        },
        contexto: 'remover o pagamento',
      );
}
