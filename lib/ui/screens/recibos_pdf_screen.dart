import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../domain/models/fechamento_rateio.dart';
import '../../domain/services/pdf_recibo_service.dart';

/// Tela de visualização e impressão em PDF dos recibos de condomínio.
class RecibosPdfScreen extends StatelessWidget {
  final FechamentoRateio fechamento;
  final String? unidadeFiltro;

  const RecibosPdfScreen({
    super.key,
    required this.fechamento,
    this.unidadeFiltro,
  });

  @override
  Widget build(BuildContext context) {
    final comp = fechamento.competencia;
    final titulo = unidadeFiltro != null
        ? 'Recibo $unidadeFiltro • ${comp.mesReferencia}/${comp.anoReferencia}'
        : 'Recibos • ${comp.mesReferencia}/${comp.anoReferencia}';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: PdfPreview(
        build: (format) => PdfReciboService.gerarPdf(
          fechamento: fechamento,
          unidadeFiltro: unidadeFiltro,
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'recibos_${comp.mesReferencia}_${comp.anoReferencia}.pdf',
      ),
    );
  }
}
