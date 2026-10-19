/// Pagamento parcial (abatimento) aplicado sobre a dívida anterior de uma unidade.
class AbatimentoDivida {
  final int? id;
  final String unidadeCodigo;
  final double valor;
  final DateTime data;
  final String? observacao;
  final DateTime criadoEm;

  const AbatimentoDivida({
    this.id,
    required this.unidadeCodigo,
    required this.valor,
    required this.data,
    this.observacao,
    required this.criadoEm,
  });

  AbatimentoDivida copyWith({
    int? id,
    String? unidadeCodigo,
    double? valor,
    DateTime? data,
    String? observacao,
    DateTime? criadoEm,
  }) {
    return AbatimentoDivida(
      id: id ?? this.id,
      unidadeCodigo: unidadeCodigo ?? this.unidadeCodigo,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      observacao: observacao ?? this.observacao,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'unidade_codigo': unidadeCodigo,
      'valor': valor,
      'data': data.toIso8601String(),
      'observacao': observacao,
      'criado_em': criadoEm.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AbatimentoDivida.fromMap(Map<String, dynamic> map) {
    return AbatimentoDivida(
      id: map['id'] as int?,
      unidadeCodigo: map['unidade_codigo'] as String,
      valor: (map['valor'] as num).toDouble(),
      data: DateTime.parse(map['data'] as String),
      observacao: map['observacao'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }
}
