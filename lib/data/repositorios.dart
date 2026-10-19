import '../domain/models/abatimento_divida.dart';
import '../domain/models/competencia.dart';
import '../domain/models/divida_anterior.dart';
import '../domain/models/pagamento.dart';
import '../domain/models/unidade.dart';

/// Contratos de acesso a dados.
///
/// Cada contrato tem duas implementações: [CompetenciaRepositoryLocal] e
/// [CompetenciaRepositorioSupabase] (idem para os demais). As fachadas com o
/// mesmo nome das classes locais escolhem a implementação conforme
/// [Backend.usaSupabase], permitindo que as telas continuem sem depender do
/// backend escolhido.
abstract class CompetenciaRepositorio {
  Future<List<Competencia>> getTodas();
  Future<Competencia?> getPorId(int id);
  Future<Competencia?> getMaisRecente();
  Future<int> inserir(Competencia competencia);
  Future<int> atualizar(Competencia competencia);
  Future<int> excluir(int id);
}

abstract class UnidadeRepositorio {
  Future<List<Unidade>> getTodas();
  Future<Unidade?> getPorCodigo(String codigo);
  Future<int> atualizar(Unidade unidade);
  Future<void> definirSindico(String codigoUnidade);
  Future<void> restaurarPadrao();
}

abstract class PagamentoRepositorio {
  Future<Map<String, Pagamento>> getPorCompetencia(int competenciaId);
  Future<void> salvar(Pagamento pagamento);
  Future<void> remover(int competenciaId, String unidadeCodigo);
}

abstract class DividaRepositorio {
  Future<Map<String, DividaAnterior>> getDividas();
  Future<void> salvarDivida(DividaAnterior divida);
  Future<void> removerDivida(String unidadeCodigo);
  Future<List<AbatimentoDivida>> getAbatimentos();
  Future<int> inserirAbatimento(AbatimentoDivida abatimento);
  Future<void> removerAbatimento(int id);
  Future<void> substituirDividas(List<DividaAnterior> dividas);
  Future<void> substituirAbatimentos(List<AbatimentoDivida> abatimentos);
}
