/// Conversão entre o formato dos modelos (que espelha o SQLite: booleanos como
/// 0/1, datas como texto ISO-8601) e o formato JSON do PostgREST (booleanos
/// nativos, colunas `date` como `YYYY-MM-DD`).
///
/// Mantém [Unidade.fromMap], [Competencia.fromMap], etc. funcionando sem
/// alterações, independentemente de o dado ter vindo do SQLite ou do Supabase.
library;

/// Colunas booleanas por tabela remota (Postgres) — no SQLite são 0/1.
const Set<String> colunasBooleanasUnidades = {'is_sindico', 'participa_policiamento'};
const Set<String> colunasBooleanasPagamentos = {'pago'};

/// Converte uma linha vinda do PostgREST para o formato esperado pelos modelos
/// (`fromMap`): booleanos passam a 0/1 e `null` permanece `null`.
Map<String, dynamic> doPostgrest(
  Map<String, dynamic> linha, {
  Set<String> colunasBooleanas = const {},
}) {
  final saida = Map<String, dynamic>.from(linha);
  for (final coluna in colunasBooleanas) {
    final valor = saida[coluna];
    if (valor is bool) {
      saida[coluna] = valor ? 1 : 0;
    }
  }
  return saida;
}

/// Converte uma lista de linhas do PostgREST.
List<Map<String, dynamic>> listaDoPostgrest(
  List<dynamic> linhas, {
  Set<String> colunasBooleanas = const {},
}) {
  return linhas
      .map((linha) => doPostgrest(
            Map<String, dynamic>.from(linha as Map),
            colunasBooleanas: colunasBooleanas,
          ))
      .toList();
}

/// Converte o mapa de um modelo (formato SQLite) para o JSON aceito pelo
/// PostgREST: remove a chave `id` (colunas identity do Postgres são geradas
/// pelo servidor) e converte 0/1 em booleanos nas colunas indicadas.
///
/// [colunasData] recebe colunas `date` cujo texto ISO completo deve ser
/// truncado para `YYYY-MM-DD`.
Map<String, dynamic> paraPostgrest(
  Map<String, dynamic> mapa, {
  Set<String> colunasBooleanas = const {},
  Set<String> colunasData = const {},
  bool removerId = true,
}) {
  final saida = Map<String, dynamic>.from(mapa);
  if (removerId) {
    saida.remove('id');
  }
  for (final coluna in colunasBooleanas) {
    final valor = saida[coluna];
    if (valor is int) {
      saida[coluna] = valor == 1;
    }
  }
  for (final coluna in colunasData) {
    final valor = saida[coluna];
    if (valor is String && valor.isNotEmpty) {
      saida[coluna] = valor.length >= 10 ? valor.substring(0, 10) : valor;
    }
  }
  return saida;
}
