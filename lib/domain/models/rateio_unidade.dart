import 'unidade.dart';

/// Guarda o rateio detalhado de uma unidade para uma competência,
/// contendo os valores no vencimento (linha ímpar da planilha) e as faixas de atraso (linha par).
class RateioUnidade {
  final Unidade unidade;

  // Valores no vencimento (linha ímpar da planilha)
  final double aguaVencimento; // Coluna E
  final double luzVencimento; // Coluna F
  final double limpezaVencimento; // Coluna G
  final double seguroVencimento; // Coluna H
  final double outrosVencimento; // Coluna I (Caixas d'água)
  final double policiamentoVencimento; // Coluna K
  final double subtotalRubricas; // Coluna L (Soma E:K)
  final double fundoVencimento; // Coluna M (Fundo de manutenções)
  final double rateioSindicoVencimento; // Coluna O
  final double totalGeralVencimento; // Coluna Q (Total a pagar no vencimento)

  // Consumo apurado do síndico (só existe para a unidade do síndico - Coluna N da planilha)
  final double consumoSindicoApurado; // Coluna N

  // Valores da linha par (acréscimo de 5,26% / divisão por 0,95)
  final double aguaAtraso;
  final double luzAtraso;
  final double limpezaAtraso;
  final double seguroAtraso;
  final double outrosAtraso;
  final double rateioSindicoAtraso;
  final double fundoAtraso; // Fundo NÃO é dividido por 0,95

  // 7 Faixas de Cobrança (Colunas Q a X da planilha)
  final double faixaNoVencimento; // Coluna Q
  final double faixaAte30Dias; // Coluna R (base de atraso ÷ 0,95)
  final double multaCalculada; // Coluna S (R × 2%)
  final double faixa30a60Dias; // Coluna T (R × 1,015 + Multa)
  final double faixa60a90Dias; // Coluna U (T × 1,015)
  final double faixa90a120Dias; // Coluna V (U × 1,015)
  final double faixa120a150Dias; // Coluna W (V × 1,015)
  final double faixa150a180Dias; // Coluna X (W × 1,015)

  // Valor específico para o locatário da Loja (Total - Fundo, quando aplicável)
  final double? valorLocatarioLoja;

  const RateioUnidade({
    required this.unidade,
    required this.aguaVencimento,
    required this.luzVencimento,
    required this.limpezaVencimento,
    required this.seguroVencimento,
    required this.outrosVencimento,
    required this.policiamentoVencimento,
    required this.subtotalRubricas,
    required this.fundoVencimento,
    required this.rateioSindicoVencimento,
    required this.totalGeralVencimento,
    required this.consumoSindicoApurado,
    required this.aguaAtraso,
    required this.luzAtraso,
    required this.limpezaAtraso,
    required this.seguroAtraso,
    required this.outrosAtraso,
    required this.rateioSindicoAtraso,
    required this.fundoAtraso,
    required this.faixaNoVencimento,
    required this.faixaAte30Dias,
    required this.multaCalculada,
    required this.faixa30a60Dias,
    required this.faixa60a90Dias,
    required this.faixa90a120Dias,
    required this.faixa120a150Dias,
    required this.faixa150a180Dias,
    this.valorLocatarioLoja,
  });

  /// Retorna o valor de uma faixa pelo índice (0 = vencimento, 1 = até 30d, 2 = 30-60d, ..., 6 = 150-180d)
  double valorFaixa(int indice) {
    switch (indice) {
      case 0:
        return faixaNoVencimento;
      case 1:
        return faixaAte30Dias;
      case 2:
        return faixa30a60Dias;
      case 3:
        return faixa60a90Dias;
      case 4:
        return faixa90a120Dias;
      case 5:
        return faixa120a150Dias;
      case 6:
        return faixa150a180Dias;
      default:
        return faixaNoVencimento;
    }
  }

  /// Índice da faixa de cobrança aplicável para [data] considerando o vencimento informado.
  /// 0 = vencimento, 1 = até 30d, 2 = 30-60d, 3 = 60-90d, 4 = 90-120d, 5 = 120-150d, 6 = 150-180d.
  static int indiceFaixaPorData(DateTime vencimento, DateTime data) {
    final diasAtraso = data.difference(vencimento).inDays;
    if (diasAtraso <= 0) return 0;
    if (diasAtraso <= 30) return 1;
    if (diasAtraso <= 60) return 2;
    if (diasAtraso <= 90) return 3;
    if (diasAtraso <= 120) return 4;
    if (diasAtraso <= 150) return 5;
    return 6;
  }

  /// Valor a ser pago pela unidade na [data], aplicando a faixa de atraso correspondente.
  double valorNaData(DateTime vencimento, DateTime data) =>
      valorFaixa(indiceFaixaPorData(vencimento, data));

  static const List<String> titulosFaixas = [
    'Até o Vencimento',
    'Até 30 dias do vencimento',
    'De 30 a 60 dias (+ juros e multa)',
    'De 60 a 90 dias',
    'De 90 a 120 dias',
    'De 120 a 150 dias',
    'De 150 a 180 dias',
  ];
}
