import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/domain/models/competencia.dart';
import 'package:projeto_sindico/domain/models/unidade.dart';
import 'package:projeto_sindico/domain/services/calculadora_rateio_service.dart';
import 'package:projeto_sindico/domain/services/pdf_recibo_service.dart';

void main() {
  test('Deve gerar bytes de PDF válidos para os 11 recibos', () async {
    final comp = Competencia.exemploSetembro2026;
    final unidades = Unidade.unidadesPadrao;

    final fechamento = CalculadoraRateioService.calcular(
      competencia: comp,
      unidades: unidades,
    );

    final bytes = await PdfReciboService.gerarPdf(fechamento: fechamento);
    expect(bytes, isNotEmpty);
    // Assinatura de arquivo PDF (%PDF-)
    expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
  });

  test('Deve gerar PDF para uma única unidade filtrada', () async {
    final comp = Competencia.exemploSetembro2026;
    final unidades = Unidade.unidadesPadrao;

    final fechamento = CalculadoraRateioService.calcular(
      competencia: comp,
      unidades: unidades,
    );

    final bytes = await PdfReciboService.gerarPdf(
      fechamento: fechamento,
      unidadeFiltro: 'LOJA',
    );
    expect(bytes, isNotEmpty);
    expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
  });
}
