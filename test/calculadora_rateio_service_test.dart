import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/domain/models/competencia.dart';
import 'package:projeto_sindico/domain/models/unidade.dart';
import 'package:projeto_sindico/domain/services/calculadora_rateio_service.dart';

void main() {
  group('CalculadoraRateioService - Competência Setembro/2026', () {
    final competencia = Competencia.exemploSetembro2026;
    final unidades = Unidade.unidadesPadrao;

    final fechamento = CalculadoraRateioService.calcular(
      competencia: competencia,
      unidades: unidades,
    );

    test('Deve apurar 20 moradores no condomínio', () {
      expect(fechamento.totalPessoas, equals(20));
    });

    test('Deve fechar totais consolidados com as contas originais', () {
      expect(fechamento.totalAgua, closeTo(823.17, 0.05));
      expect(fechamento.totalLuz, closeTo(138.37, 0.05));
      expect(fechamento.totalLimpeza, closeTo(800.00, 0.05));
      expect(fechamento.totalOutros, closeTo(360.00, 0.05));
      expect(fechamento.totalFundo, closeTo(1000.00, 0.05));
      expect(fechamento.consumoSindicoRatear, closeTo(171.29, 0.05));
      expect(fechamento.totalGeralVencimento, closeTo(3114.53, 0.05));
      expect(fechamento.isFechamentoConsistente, isTrue);
    });

    test('Rateio da LOJA deve bater com a linha 45 da planilha', () {
      final loja = fechamento.itens.firstWhere((i) => i.unidade.codigo == 'LOJA');
      expect(loja.aguaVencimento, closeTo(61.58, 0.05));
      expect(loja.luzVencimento, equals(0.0));
      expect(loja.limpezaVencimento, closeTo(72.73, 0.05));
      expect(loja.outrosVencimento, closeTo(36.00, 0.05));
      expect(loja.fundoVencimento, equals(0.0));
      expect(loja.rateioSindicoVencimento, closeTo(15.57, 0.05));
      expect(loja.totalGeralVencimento, closeTo(185.88, 0.05));

      // Faixas de atraso da LOJA
      expect(loja.faixaAte30Dias, closeTo(195.66, 0.05));
      expect(loja.faixa30a60Dias, closeTo(202.51, 0.05));
      expect(loja.faixa60a90Dias, closeTo(205.55, 0.05));
      expect(loja.faixa90a120Dias, closeTo(208.63, 0.05));
      expect(loja.faixa120a150Dias, closeTo(211.76, 0.05));
      expect(loja.faixa150a180Dias, closeTo(214.94, 0.05));
    });

    test('Rateio do APTO 101 (1 morador) deve bater com a linha 47 da planilha', () {
      final apto101 = fechamento.itens.firstWhere((i) => i.unidade.codigo == '101');
      expect(apto101.aguaVencimento, closeTo(38.08, 0.05));
      expect(apto101.luzVencimento, closeTo(13.84, 0.05));
      expect(apto101.limpezaVencimento, closeTo(72.73, 0.05));
      expect(apto101.outrosVencimento, closeTo(36.00, 0.05));
      expect(apto101.fundoVencimento, equals(100.00));
      expect(apto101.rateioSindicoVencimento, closeTo(15.57, 0.05));
      expect(apto101.totalGeralVencimento, closeTo(276.22, 0.05));

      // Faixas
      expect(apto101.faixaAte30Dias, closeTo(285.49, 0.05));
      expect(apto101.faixa30a60Dias, closeTo(295.48, 0.05));
      expect(apto101.faixa60a90Dias, closeTo(299.91, 0.05));
      expect(apto101.faixa90a120Dias, closeTo(304.41, 0.05));
      expect(apto101.faixa120a150Dias, closeTo(308.98, 0.05));
      expect(apto101.faixa150a180Dias, closeTo(313.61, 0.05));
    });

    test('Rateio do APTO 202 (2 moradores) deve bater com a linha 51 da planilha', () {
      final apto202 = fechamento.itens.firstWhere((i) => i.unidade.codigo == '202');
      expect(apto202.aguaVencimento, closeTo(76.16, 0.05));
      expect(apto202.totalGeralVencimento, closeTo(314.29, 0.05));
      expect(apto202.faixaAte30Dias, closeTo(325.57, 0.05));
      expect(apto202.faixa30a60Dias, closeTo(336.97, 0.05));
      expect(apto202.faixa60a90Dias, closeTo(342.02, 0.05));
      expect(apto202.faixa90a120Dias, closeTo(347.15, 0.05));
      expect(apto202.faixa120a150Dias, closeTo(352.36, 0.05));
      expect(apto202.faixa150a180Dias, closeTo(357.65, 0.05));
    });

    test('Rateio do APTO 301 (SÍNDICO) deve cobrar apenas o FUNDO no vencimento', () {
      final apto301 = fechamento.itens.firstWhere((i) => i.unidade.codigo == '301');
      expect(apto301.rateioSindicoVencimento, equals(0.0));
      expect(apto301.outrosVencimento, equals(0.0));
      expect(apto301.fundoVencimento, equals(100.00));
      // Síndico paga R$ 100,00 no vencimento
      expect(apto301.totalGeralVencimento, equals(100.00));

      // Faixas do síndico
      expect(apto301.faixaAte30Dias, equals(100.00));
      expect(apto301.faixa30a60Dias, closeTo(103.50, 0.05));
      expect(apto301.faixa60a90Dias, closeTo(105.05, 0.05));
      expect(apto301.faixa90a120Dias, closeTo(106.63, 0.05));
      expect(apto301.faixa120a150Dias, closeTo(108.23, 0.05));
      expect(apto301.faixa150a180Dias, closeTo(109.85, 0.05));
    });

    test('Rateio do APTO 401 (4 moradores) deve bater com a linha 61 da planilha', () {
      final apto401 = fechamento.itens.firstWhere((i) => i.unidade.codigo == '401');
      expect(apto401.aguaVencimento, closeTo(152.32, 0.05));
      expect(apto401.totalGeralVencimento, closeTo(390.45, 0.05));
      expect(apto401.faixaAte30Dias, closeTo(405.74, 0.05));
      expect(apto401.faixa30a60Dias, closeTo(419.94, 0.05));
      expect(apto401.faixa60a90Dias, closeTo(426.24, 0.05));
      expect(apto401.faixa90a120Dias, closeTo(432.63, 0.05));
      expect(apto401.faixa120a150Dias, closeTo(439.12, 0.05));
      expect(apto401.faixa150a180Dias, closeTo(445.71, 0.05));
    });

    test('Deve preservar o síndico gravado na competência antiga', () {
      final competenciaComOutroSindico =
          competencia.copyWith(aptoSindico: '202');
      final resultado = CalculadoraRateioService.calcular(
        competencia: competenciaComOutroSindico,
        unidades: unidades,
      );

      expect(resultado.codigoSindico, equals('202'));

      final sindicoDaCompetencia =
          resultado.itens.firstWhere((i) => i.unidade.codigo == '202');
      final sindicoAtualDoCadastro =
          resultado.itens.firstWhere((i) => i.unidade.codigo == '301');
      expect(sindicoDaCompetencia.rateioSindicoVencimento, equals(0.0));
      expect(sindicoAtualDoCadastro.rateioSindicoVencimento, greaterThan(0.0));
    });

    test('Deve usar o síndico do cadastro quando o apto da competência não existir', () {
      final competenciaComAptoInvalido =
          competencia.copyWith(aptoSindico: '999');
      final resultado = CalculadoraRateioService.calcular(
        competencia: competenciaComAptoInvalido,
        unidades: unidades,
      );

      expect(resultado.codigoSindico, equals('301'));

      final sindicoCadastro =
          resultado.itens.firstWhere((i) => i.unidade.codigo == '301');
      expect(sindicoCadastro.rateioSindicoVencimento, equals(0.0));
    });
  });
}
