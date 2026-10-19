import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/currency_utils.dart';
import '../models/fechamento_rateio.dart';
import '../models/rateio_unidade.dart';

/// Serviço responsável pela geração de PDFs dos recibos e demonstrativo de despesas.
class PdfReciboService {
  /// Gera o documento PDF completo para impressão e compartilhamento
  static Future<Uint8List> gerarPdf({
    required FechamentoRateio fechamento,
    String? unidadeFiltro,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    // Filtra as unidades a imprimir
    final itensParaImprimir = unidadeFiltro != null
        ? fechamento.itens.where((i) => i.unidade.codigo == unidadeFiltro).toList()
        : fechamento.itens;

    for (final item in itensParaImprimir) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return _buildPaginaRecibo(item, fechamento, dateFormat);
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildPaginaRecibo(
    RateioUnidade item,
    FechamentoRateio fechamento,
    DateFormat dateFormat,
  ) {
    final comp = fechamento.competencia;
    final u = item.unidade;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. Cabeçalho Principal
          pw.Center(
            child: pw.Text(
              'DEMONSTRATIVO DE DESPESAS DO CONDOMÍNIO EVARISTO LUCCHESE',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              border: pw.Border.all(color: PdfColors.grey500),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'UNIDADE: ${u.descricaoExibicao}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.Text(
                  'MÊS DE REFERÊNCIA: ${comp.mesReferencia}/${comp.anoReferencia}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
                pw.Text(
                  'VENCIMENTO: ${dateFormat.format(comp.dataVencimento)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Morador: ${u.nomeMorador}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),

          // 2. Quadro de Itens (Esquerda) e Faixas de Vencimento/Atraso (Direita)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Quadro de Itens
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                  child: pw.Column(
                    children: [
                      _buildHeaderTabela('ITENS DA DESPESA', 'VALOR (R\$)'),
                      _buildLinhaTabela('Água / Esgoto', CurrencyUtils.formatClean(item.aguaVencimento)),
                      _buildLinhaTabela('Energia Elétrica', CurrencyUtils.formatClean(item.luzVencimento)),
                      _buildLinhaTabela('Limpeza e Conservação', CurrencyUtils.formatClean(item.limpezaVencimento)),
                      _buildLinhaTabela('Seguros', CurrencyUtils.formatClean(item.seguroVencimento)),
                      _buildLinhaTabela('Limpeza Caixas d\'Água', CurrencyUtils.formatClean(item.outrosVencimento)),
                      _buildLinhaTabela('Fundo Manutenções Emergenciais', CurrencyUtils.formatClean(item.fundoVencimento)),
                      _buildLinhaTabela('Rateio Síndico', CurrencyUtils.formatClean(item.rateioSindicoVencimento)),
                      if (item.policiamentoVencimento > 0)
                        _buildLinhaTabela('Policiamento Comunitário', CurrencyUtils.formatClean(item.policiamentoVencimento)),
                      pw.Container(
                        color: PdfColors.grey300,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL A PAGAR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                            pw.Text(
                              CurrencyUtils.formatClean(item.totalGeralVencimento),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(width: 12),

              // Escala de Atraso (Direita)
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                  child: pw.Column(
                    children: [
                      _buildHeaderTabela('FAIXA DE PAGAMENTO', 'VALOR (R\$)'),
                      _buildLinhaTabela('Até o Vencimento', CurrencyUtils.formatClean(item.faixaNoVencimento), bold: true),
                      _buildLinhaTabela('Até 30 dias do vencimento', CurrencyUtils.formatClean(item.faixaAte30Dias)),
                      _buildLinhaTabela('De 30 a 60 dias (+ juros e multa)', CurrencyUtils.formatClean(item.faixa30a60Dias)),
                      _buildLinhaTabela('De 60 a 90 dias', CurrencyUtils.formatClean(item.faixa60a90Dias)),
                      _buildLinhaTabela('De 90 a 120 dias', CurrencyUtils.formatClean(item.faixa90a120Dias)),
                      _buildLinhaTabela('De 120 a 150 dias', CurrencyUtils.formatClean(item.faixa120a150Dias)),
                      _buildLinhaTabela('De 150 a 180 dias', CurrencyUtils.formatClean(item.faixa150a180Dias)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (u.isLoja && item.valorLocatarioLoja != null) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              color: PdfColors.grey100,
              child: pw.Text(
                'Valor a ser pago pelo locatário: ${CurrencyUtils.format(item.valorLocatarioLoja)} (total deduzido o fundo e seguro de responsabilidade do proprietário).',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
            ),
          ],

          pw.SizedBox(height: 12),

          // 3. Dados Utilizados para os Cálculos
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DADOS UTILIZADOS PARA OS CÁLCULOS:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Juros de mora: ${(comp.jurosMoraMensal * 100).toStringAsFixed(1)}% a.m. | Multa de mora: ${(comp.multaMora * 100).toStringAsFixed(1)}% | Moradores no condomínio: ${fechamento.totalPessoas}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Conta Água: ${CurrencyUtils.format(comp.valorContaAgua)} (${comp.consumoAguaM3?.toStringAsFixed(0) ?? '-'} m³) | Conta Energia: ${CurrencyUtils.format(comp.valorContaEnergia)} (${comp.consumoEnergiaKwh?.toStringAsFixed(0) ?? '-'} KWh) | Limpeza: ${CurrencyUtils.format(comp.custoTotalLimpeza)}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ),
                if ((comp.discriminacaoOutrasDespesas ?? '').trim().isNotEmpty)
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Discriminação das Outras Despesas (${CurrencyUtils.format(comp.limpezaCaixasAgua)}): ${comp.discriminacaoOutrasDespesas!.trim()}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                if ((comp.discriminacaoFundoManutencao ?? '').trim().isNotEmpty)
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Discriminação do Fundo Emergencial (${CurrencyUtils.format(comp.fundoManutencaoMensal)}/apto): ${comp.discriminacaoFundoManutencao!.trim()}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // 4. Observações e Informações da Administração
          pw.Text(
            'OBSERVAÇÕES E INSTRUÇÕES:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '1. Síndico(a): ${comp.nomeSindico} | Mandato: ${comp.periodoMandato} | Efetuar pagamento no Apto: ${comp.aptoSindico}.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            '2. Por decisão da Assembléia de Condomínio, os pagamentos em atraso terão acréscimo de juros. A partir do 30º dia também serão cobrados ${(comp.multaMora * 100).toStringAsFixed(0)}% de multa. Até 30 dias de atraso permanece a metodologia até hoje utilizada.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          if (u.isLoja) ...[
            pw.Text(
              '3. O fundo de manutenções é de responsabilidade do proprietário.',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              '4. O valor do seguro obrigatório é de responsabilidade do proprietário.',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],

          pw.Spacer(),

          // Canhoto de Quitação / Assinatura
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Recebi a quantia de R\$ _________________ em _____/_____/_________',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Text(
                  'Assinatura do(a) Síndico(a): __________________________________',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderTabela(String col1, String col2) {
    return pw.Container(
      color: PdfColors.grey200,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(col1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
          pw.Text(col2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildLinhaTabela(String rotulo, String valor, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            rotulo,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
