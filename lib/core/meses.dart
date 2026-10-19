// Utilitários de meses em português para agrupamento e exibição de competências.

/// Nomes dos meses no padrão armazenado no banco (maiúsculas).
const List<String> nomesMesesMaiusculo = [
  'JANEIRO',
  'FEVEREIRO',
  'MARÇO',
  'ABRIL',
  'MAIO',
  'JUNHO',
  'JULHO',
  'AGOSTO',
  'SETEMBRO',
  'OUTUBRO',
  'NOVEMBRO',
  'DEZEMBRO',
];

/// Nomes dos meses para exibição (capitalizados).
const List<String> nomesMesesTitulo = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// Abreviações dos meses para exibição compacta.
const List<String> nomesMesesAbreviado = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

/// Nome do mês (maiúsculo, padrão do banco) a partir do índice 1-12.
String nomeMesBanco(int mes) => nomesMesesMaiusculo[mes - 1];

/// Nome do mês capitalizado a partir do índice 1-12.
String nomeMesTitulo(int mes) => nomesMesesTitulo[mes - 1];

/// Abreviação do mês a partir do índice 1-12.
String nomeMesAbreviado(int mes) => nomesMesesAbreviado[mes - 1];

/// Converte o nome do mês armazenado em texto para o índice 1-12.
/// Aceita variações de acentuação e maiúsculas/minúsculas ("Março", "MARCO").
int? indiceMesPorNome(String nome) {
  final normalizado = _normalizar(nome);
  for (var i = 0; i < nomesMesesMaiusculo.length; i++) {
    if (_normalizar(nomesMesesMaiusculo[i]) == normalizado) return i + 1;
  }
  return null;
}

String _normalizar(String valor) {
  return valor
      .trim()
      .toUpperCase()
      .replaceAll('Ç', 'C')
      .replaceAll('Á', 'A')
      .replaceAll('Ã', 'A')
      .replaceAll('Â', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Ê', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ô', 'O')
      .replaceAll('Õ', 'O')
      .replaceAll('Ú', 'U');
}
