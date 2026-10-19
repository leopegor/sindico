import '../models/competencia.dart';
import '../models/unidade.dart';
import '../models/rateio_unidade.dart';
import '../models/fechamento_rateio.dart';
import '../../core/currency_utils.dart';

/// Serviço responsável pelo cálculo e rateio das despesas condominiais,
/// fiel às regras e fórmulas da aba DADO_RECIBOS.
class CalculadoraRateioService {
  /// Executa o cálculo de rateio completo para a competência e lista de unidades fornecidas.
  static FechamentoRateio calcular({
    required Competencia competencia,
    required List<Unidade> unidades,
  }) {
    // 1. Total de moradores/pessoas no prédio
    final totalPessoas = unidades.fold<int>(
      0,
      (acc, u) => acc + (u.isLoja ? 0 : u.numeroPessoas),
    );

    // 2. Parâmetros de Água
    final taxaEsgotoUnidade = competencia.taxaEsgotoPorUnidade; // D8 / 11
    final valorRateioAguaPessoas = competencia.valorRateioAguaPessoas; // D7 - D9 - D10
    final aguaPorPessoa = totalPessoas > 0 ? (valorRateioAguaPessoas / totalPessoas) : 0.0;

    // 3. Parâmetros de Luz
    // Dividido por 10 apartamentos (a loja não paga)
    final luzPorApto = competencia.valorContaEnergia / 10.0;

    // 4. Parâmetros de Limpeza
    // Dividido por 11 unidades (loja + 10 apartamentos)
    final limpezaPorUnidade = competencia.custoTotalLimpeza / 11.0;

    // 5. Parâmetros de Seguro
    final seguroPorUnidade = competencia.parcelaSeguroPorUnidade;

    // 6. Parâmetros de Outras Despesas (Caixas d'água)
    // Rateado entre 10 unidades (síndico isento)
    final outrosPorUnidade = competencia.limpezaCaixasAgua / 10.0;

    // 7. Identificação do Síndico para apuração do consumo da unidade do síndico
    // Prioriza o aptoSindico informado na competência atual, com fallback para isSindico
    String normalizarCodigo(String cod) =>
        cod.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toUpperCase();
    final aptoNormalizado = normalizarCodigo(competencia.aptoSindico);

    Unidade? sindicoUnidade;
    if (aptoNormalizado.isNotEmpty) {
      for (final u in unidades) {
        if (normalizarCodigo(u.codigo) == aptoNormalizado) {
          sindicoUnidade = u;
          break;
        }
      }
    }
    if (sindicoUnidade == null) {
      for (final u in unidades) {
        if (u.isSindico) {
          sindicoUnidade = u;
          break;
        }
      }
    }
    final idSindico = sindicoUnidade?.id;
    final codigoSindicoNormalizado = normalizarCodigo(sindicoUnidade?.codigo ?? competencia.aptoSindico);

    // 8. Cálculo prévio do consumo operacional da unidade do síndico
    // Na planilha, D39 = N67 (consumo de água + luz + limpeza do síndico na linha atrasada ÷ 0,95)
    double consumoSindicoLinhaAtrasada = 0.0;
    if (sindicoUnidade != null && !sindicoUnidade.isLoja) {
      final aguaSindico = aguaPorPessoa * sindicoUnidade.numeroPessoas;
      final luzSindico = luzPorApto;
      final limpezaSindico = limpezaPorUnidade;
      final subtotalOperacionalSindico = aguaSindico + luzSindico + limpezaSindico;
      // Linha par divide por 0,95:
      consumoSindicoLinhaAtrasada = CurrencyUtils.round2(
        subtotalOperacionalSindico / competencia.fatorAtraso,
      );
    }

    // 9. Rateio do síndico por unidade pagante
    // D41 = D39 / D40
    final divisor = competencia.divisorRateioSindico > 0 ? competencia.divisorRateioSindico : 11;
    final rateioSindicoPorUnidade = CurrencyUtils.round2(consumoSindicoLinhaAtrasada / divisor);

    // 10. Calcular rateio para cada unidade
    final itens = <RateioUnidade>[];

    for (final u in unidades) {
      final isUnidadeSindico = (idSindico != null && u.id == idSindico) ||
          (normalizarCodigo(u.codigo) == codigoSindicoNormalizado);

      // Água no vencimento
      final double aguaVenc;
      if (u.isLoja) {
        // Loja paga taxa mínima + esgoto
        aguaVenc = CurrencyUtils.round2(competencia.taxaMinimaAgua + taxaEsgotoUnidade);
      } else {
        aguaVenc = CurrencyUtils.round2(aguaPorPessoa * u.numeroPessoas);
      }

      // Luz no vencimento
      final double luzVenc;
      if (u.isLoja) {
        luzVenc = 0.0;
      } else {
        luzVenc = CurrencyUtils.round2(luzPorApto);
      }

      // Limpeza no vencimento
      final double limpezaVenc = CurrencyUtils.round2(limpezaPorUnidade);

      // Seguro no vencimento
      final double seguroVenc = CurrencyUtils.round2(seguroPorUnidade);

      // Outros (caixas d'água) no vencimento
      final double outrosVenc;
      if (isUnidadeSindico) {
        outrosVenc = 0.0; // Síndico isento
      } else {
        outrosVenc = CurrencyUtils.round2(outrosPorUnidade);
      }

      // Policiamento
      final double policiamentoVenc = u.participaPoliciamento ? u.valorPoliciamento : 0.0;

      // Subtotal rubricas L (E:K)
      final subtotalL = CurrencyUtils.round2(
        aguaVenc + luzVenc + limpezaVenc + seguroVenc + outrosVenc + policiamentoVenc,
      );

      // Fundo no vencimento (Loja isenta mensalmente)
      final double fundoVenc;
      if (u.isLoja) {
        fundoVenc = 0.0;
      } else {
        fundoVenc = CurrencyUtils.round2(competencia.fundoManutencaoMensal);
      }

      // Rateio do síndico
      final double rateioSindicoVenc;
      if (isUnidadeSindico) {
        rateioSindicoVenc = 0.0; // Próprio síndico não paga o rateio de si mesmo
      } else {
        rateioSindicoVenc = rateioSindicoPorUnidade;
      }

      // Total a pagar no vencimento (Coluna Q)
      final double totalVenc;
      if (isUnidadeSindico) {
        // Síndico tem as despesas operacionais cobertas; paga apenas o fundo (e eventual policiamento)
        totalVenc = CurrencyUtils.round2(fundoVenc + policiamentoVenc);
      } else {
        totalVenc = CurrencyUtils.round2(subtotalL + fundoVenc + rateioSindicoVenc);
      }

      // Consumo apurado do síndico para exibição na linha N
      final double consumoSindicoApuradoLinha = isUnidadeSindico ? consumoSindicoLinhaAtrasada : 0.0;

      // LINHA PAR: Valores de atraso
      // Rubricas divididas por 0,95 (+5,26%)
      final double fator = competencia.fatorAtraso > 0 ? competencia.fatorAtraso : 0.95;

      final double aguaAtraso = CurrencyUtils.round2(aguaVenc / fator);
      final double luzAtraso = CurrencyUtils.round2(luzVenc / fator);
      final double limpezaAtraso = CurrencyUtils.round2(limpezaVenc / fator);
      final double seguroAtraso = seguroVenc > 0 ? CurrencyUtils.round2(seguroVenc / fator) : 0.0;
      final double outrosAtraso = outrosVenc > 0 ? CurrencyUtils.round2(outrosVenc / fator) : 0.0;
      final double rateioSindicoAtraso = rateioSindicoVenc > 0
          ? CurrencyUtils.round2(rateioSindicoVenc / fator)
          : 0.0;
      // Fundo de manutenção NÃO é dividido por 0,95
      final double fundoAtraso = fundoVenc;

      // Base da faixa "Até 30 dias" (Coluna R)
      final double baseAte30Dias;
      if (isUnidadeSindico) {
        // Para o síndico a base de atraso é apenas o fundo (R$ 100,00)
        baseAte30Dias = CurrencyUtils.round2(fundoVenc + policiamentoVenc);
      } else {
        baseAte30Dias = CurrencyUtils.round2(
          aguaAtraso +
              luzAtraso +
              limpezaAtraso +
              seguroAtraso +
              outrosAtraso +
              fundoAtraso +
              rateioSindicoAtraso +
              policiamentoVenc,
        );
      }

      // Multa de mora (Coluna S): R × 2%
      final double multa = CurrencyUtils.round2(baseAte30Dias * competencia.multaMora);

      // Faixa 30 a 60 dias (Coluna T): R × (1 + juros) + Multa
      final double faixa30a60 = CurrencyUtils.round2(
        baseAte30Dias * (1.0 + competencia.jurosMoraMensal) + multa,
      );

      // Faixas progressivas com juros compostos mensais
      final double faixa60a90 = CurrencyUtils.round2(
        faixa30a60 * (1.0 + competencia.jurosMoraMensal),
      );
      final double faixa90a120 = CurrencyUtils.round2(
        faixa60a90 * (1.0 + competencia.jurosMoraMensal),
      );
      final double faixa120a150 = CurrencyUtils.round2(
        faixa90a120 * (1.0 + competencia.jurosMoraMensal),
      );
      final double faixa150a180 = CurrencyUtils.round2(
        faixa120a150 * (1.0 + competencia.jurosMoraMensal),
      );

      // Para a Loja: valor do locatário (excluindo fundo e seguro do proprietário)
      double? valorLocatario;
      if (u.isLoja) {
        valorLocatario = CurrencyUtils.round2(totalVenc - fundoVenc - seguroVenc);
      }

      itens.add(RateioUnidade(
        unidade: u,
        aguaVencimento: aguaVenc,
        luzVencimento: luzVenc,
        limpezaVencimento: limpezaVenc,
        seguroVencimento: seguroVenc,
        outrosVencimento: outrosVenc,
        policiamentoVencimento: policiamentoVenc,
        subtotalRubricas: subtotalL,
        fundoVencimento: fundoVenc,
        rateioSindicoVencimento: rateioSindicoVenc,
        totalGeralVencimento: totalVenc,
        consumoSindicoApurado: consumoSindicoApuradoLinha,
        aguaAtraso: aguaAtraso,
        luzAtraso: luzAtraso,
        limpezaAtraso: limpezaAtraso,
        seguroAtraso: seguroAtraso,
        outrosAtraso: outrosAtraso,
        rateioSindicoAtraso: rateioSindicoAtraso,
        fundoAtraso: fundoAtraso,
        faixaNoVencimento: totalVenc,
        faixaAte30Dias: baseAte30Dias,
        multaCalculada: multa,
        faixa30a60Dias: faixa30a60,
        faixa60a90Dias: faixa60a90,
        faixa90a120Dias: faixa90a120,
        faixa120a150Dias: faixa120a150,
        faixa150a180Dias: faixa150a180,
        valorLocatarioLoja: valorLocatario,
      ));
    }

    // 11. Consolidação e Linhas de Conferência (Linha 67 da planilha)
    final somaAgua = CurrencyUtils.round2(itens.fold(0.0, (acc, item) => acc + item.aguaVencimento));
    final somaLuz = CurrencyUtils.round2(itens.fold(0.0, (acc, item) => acc + item.luzVencimento));
    final somaLimpeza = CurrencyUtils.round2(
      itens.fold(0.0, (acc, item) => acc + item.limpezaVencimento),
    );
    final somaSeguro = CurrencyUtils.round2(itens.fold(0.0, (acc, item) => acc + item.seguroVencimento));
    final somaOutros = CurrencyUtils.round2(itens.fold(0.0, (acc, item) => acc + item.outrosVencimento));
    final somaSubtotalRubricas = CurrencyUtils.round2(
      itens.fold(0.0, (acc, item) => acc + item.subtotalRubricas),
    );
    final somaFundo = CurrencyUtils.round2(itens.fold(0.0, (acc, item) => acc + item.fundoVencimento));
    final somaRateioSindico = CurrencyUtils.round2(
      itens.fold(0.0, (acc, item) => acc + item.rateioSindicoVencimento),
    );
    final somaTotalGeral = CurrencyUtils.round2(
      itens.fold(0.0, (acc, item) => acc + item.totalGeralVencimento),
    );

    return FechamentoRateio(
      competencia: competencia,
      itens: itens,
      totalPessoas: totalPessoas,
      totalAgua: somaAgua,
      totalLuz: somaLuz,
      totalLimpeza: somaLimpeza,
      totalSeguro: somaSeguro,
      totalOutros: somaOutros,
      subtotalRubricas: somaSubtotalRubricas,
      totalFundo: somaFundo,
      consumoSindicoRatear: consumoSindicoLinhaAtrasada,
      totalRateioSindicoCobrado: somaRateioSindico,
      totalGeralVencimento: somaTotalGeral,
      previsaoArrecadacao: somaTotalGeral,
    );
  }
}
