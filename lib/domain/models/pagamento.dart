/// Representa o controle de pagamento de uma unidade em uma competência mensal.
class Pagamento {
  final int? id;
  final int competenciaId;
  final String unidadeCodigo;
  final bool pago;
  final DateTime? dataPagamento;
  final double? valorPago;

  const Pagamento({
    this.id,
    required this.competenciaId,
    required this.unidadeCodigo,
    this.pago = false,
    this.dataPagamento,
    this.valorPago,
  });

  Pagamento copyWith({
    int? id,
    int? competenciaId,
    String? unidadeCodigo,
    bool? pago,
    DateTime? dataPagamento,
    double? valorPago,
  }) {
    return Pagamento(
      id: id ?? this.id,
      competenciaId: competenciaId ?? this.competenciaId,
      unidadeCodigo: unidadeCodigo ?? this.unidadeCodigo,
      pago: pago ?? this.pago,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      valorPago: valorPago ?? this.valorPago,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'competencia_id': competenciaId,
      'unidade_codigo': unidadeCodigo,
      'pago': pago ? 1 : 0,
      'data_pagamento': dataPagamento?.toIso8601String(),
      'valor_pago': valorPago,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Pagamento.fromMap(Map<String, dynamic> map) {
    return Pagamento(
      id: map['id'] as int?,
      competenciaId: (map['competencia_id'] as num).toInt(),
      unidadeCodigo: map['unidade_codigo'] as String,
      pago: (map['pago'] as num?)?.toInt() == 1,
      dataPagamento: map['data_pagamento'] != null
          ? DateTime.tryParse(map['data_pagamento'] as String)
          : null,
      valorPago: (map['valor_pago'] as num?)?.toDouble(),
    );
  }
}
