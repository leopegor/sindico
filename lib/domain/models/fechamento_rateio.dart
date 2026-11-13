import 'competencia.dart';
import 'rateio_unidade.dart';

/// Resultado consolidado do fechamento do rateio mensal, contendo os rateios
/// individuais de todas as unidades e a linha de conferência contábil (Linha 67 da planilha).
class FechamentoRateio {
  final Competencia competencia;
  final List<RateioUnidade> itens;
  final String codigoSindico;

  // Linhas de conferência e totais consolidados (Linha 67 da planilha)
  final int totalPessoas; // D67
  final double totalAgua; // E67
  final double totalLuz; // F67
  final double totalLimpeza; // G67
  final double totalSeguro; // H67
  final double totalOutros; // I67
  final double subtotalRubricas; // L67
  final double totalFundo; // M67
  final double consumoSindicoRatear; // N67 / D39
  final double totalRateioSindicoCobrado; // Soma coluna O
  final double totalGeralVencimento; // Q67
  final double previsaoArrecadacao; // I69

  const FechamentoRateio({
    required this.competencia,
    required this.itens,
    required this.codigoSindico,
    required this.totalPessoas,
    required this.totalAgua,
    required this.totalLuz,
    required this.totalLimpeza,
    required this.totalSeguro,
    required this.totalOutros,
    required this.subtotalRubricas,
    required this.totalFundo,
    required this.consumoSindicoRatear,
    required this.totalRateioSindicoCobrado,
    required this.totalGeralVencimento,
    required this.previsaoArrecadacao,
  });

  /// Verifica se o total de água bate com a conta da concessionária (tolerância de R$ 0,02 para arredondamento)
  bool get isAguaFechada => (totalAgua - competencia.valorContaAgua).abs() < 0.05;

  /// Verifica se o total de energia bate com a fatura
  bool get isLuzFechada => (totalLuz - competencia.valorContaEnergia).abs() < 0.05;

  /// Verifica se o total de limpeza bate com os custos
  bool get isLimpezaFechada => (totalLimpeza - competencia.custoTotalLimpeza).abs() < 0.05;

  /// Verifica se outras despesas batem
  bool get isOutrosFechada => (totalOutros - competencia.limpezaCaixasAgua).abs() < 0.05;

  /// Verifica se a previsão de arrecadação bate com a soma das despesas a receber
  bool get isPrevisaoFechada => (previsaoArrecadacao - totalGeralVencimento).abs() < 0.05;

  /// Status geral de fechamento contábil
  bool get isFechamentoConsistente =>
      isAguaFechada && isLuzFechada && isLimpezaFechada && isOutrosFechada && isPrevisaoFechada;
}
