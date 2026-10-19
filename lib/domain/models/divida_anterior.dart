/// Registro da dívida anterior definida manualmente para uma unidade.
/// Quando presente, substitui o cálculo automático de meses anteriores.
class DividaAnterior {
  final int? id;
  final String unidadeCodigo;
  final double valor;
  final DateTime atualizadoEm;

  const DividaAnterior({
    this.id,
    required this.unidadeCodigo,
    required this.valor,
    required this.atualizadoEm,
  });

  DividaAnterior copyWith({
    int? id,
    String? unidadeCodigo,
    double? valor,
    DateTime? atualizadoEm,
  }) {
    return DividaAnterior(
      id: id ?? this.id,
      unidadeCodigo: unidadeCodigo ?? this.unidadeCodigo,
      valor: valor ?? this.valor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'unidade_codigo': unidadeCodigo,
      'valor': valor,
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory DividaAnterior.fromMap(Map<String, dynamic> map) {
    return DividaAnterior(
      id: map['id'] as int?,
      unidadeCodigo: map['unidade_codigo'] as String,
      valor: (map['valor'] as num).toDouble(),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
    );
  }
}
