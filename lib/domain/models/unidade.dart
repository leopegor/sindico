enum TipoUnidade {
  comercial,
  residencial,
}

/// Representa uma unidade condominial (Loja ou Apartamento) no Edifício Evaristo Lucchese.
class Unidade {
  final int? id;
  final String codigo; // ex: "LOJA", "101", "201", etc.
  final String nomeMorador; // ex: "Daniel Rasia", "Adélia Kaiser Lucchese"
  final int numeroPessoas; // moradores (loja = 0)
  final double areaPrivativa; // m² (ex: 44.11)
  final double fracaoIdeal; // referencial (ex: 0.0838 = 8.38%)
  final bool isSindico; // 1 se síndico em exercício, 0 caso contrário
  final bool participaPoliciamento; // "sim" ou "não"
  final double valorPoliciamento; // valor opcional
  final TipoUnidade tipo;

  const Unidade({
    this.id,
    required this.codigo,
    required this.nomeMorador,
    required this.numeroPessoas,
    required this.areaPrivativa,
    required this.fracaoIdeal,
    this.isSindico = false,
    this.participaPoliciamento = false,
    this.valorPoliciamento = 0.0,
    required this.tipo,
  });

  bool get isLoja => codigo.trim().toUpperCase() == 'LOJA' || tipo == TipoUnidade.comercial;

  String get descricaoExibicao => isLoja ? 'LOJA' : 'APTO $codigo';

  Unidade copyWith({
    int? id,
    String? codigo,
    String? nomeMorador,
    int? numeroPessoas,
    double? areaPrivativa,
    double? fracaoIdeal,
    bool? isSindico,
    bool? participaPoliciamento,
    double? valorPoliciamento,
    TipoUnidade? tipo,
  }) {
    return Unidade(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nomeMorador: nomeMorador ?? this.nomeMorador,
      numeroPessoas: numeroPessoas ?? this.numeroPessoas,
      areaPrivativa: areaPrivativa ?? this.areaPrivativa,
      fracaoIdeal: fracaoIdeal ?? this.fracaoIdeal,
      isSindico: isSindico ?? this.isSindico,
      participaPoliciamento: participaPoliciamento ?? this.participaPoliciamento,
      valorPoliciamento: valorPoliciamento ?? this.valorPoliciamento,
      tipo: tipo ?? this.tipo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nome_morador': nomeMorador,
      'numero_pessoas': numeroPessoas,
      'area_privativa': areaPrivativa,
      'fracao_ideal': fracaoIdeal,
      'is_sindico': isSindico ? 1 : 0,
      'participa_policiamento': participaPoliciamento ? 1 : 0,
      'valor_policiamento': valorPoliciamento,
      'tipo': tipo.name,
    };
  }

  factory Unidade.fromMap(Map<String, dynamic> map) {
    return Unidade(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      nomeMorador: map['nome_morador'] as String,
      numeroPessoas: (map['numero_pessoas'] as num).toInt(),
      areaPrivativa: (map['area_privativa'] as num).toDouble(),
      fracaoIdeal: (map['fracao_ideal'] as num).toDouble(),
      isSindico: (map['is_sindico'] as int? ?? 0) == 1,
      participaPoliciamento: (map['participa_policiamento'] as int? ?? 0) == 1,
      valorPoliciamento: (map['valor_policiamento'] as num?)?.toDouble() ?? 0.0,
      tipo: (map['tipo'] as String?) == TipoUnidade.comercial.name
          ? TipoUnidade.comercial
          : TipoUnidade.residencial,
    );
  }

  /// Lista padrão histórica das 11 unidades do Condomínio Evaristo Lucchese (aba DADO_RECIBOS)
  static List<Unidade> get unidadesPadrao {
    return const [
      Unidade(
        codigo: 'LOJA',
        nomeMorador: 'Daniel Rasia',
        numeroPessoas: 0,
        areaPrivativa: 44.11,
        fracaoIdeal: 0.0838,
        isSindico: false,
        tipo: TipoUnidade.comercial,
      ),
      Unidade(
        codigo: '101',
        nomeMorador: 'Adélia Kaiser Lucchese',
        numeroPessoas: 1,
        areaPrivativa: 106.61,
        fracaoIdeal: 0.2026,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '201',
        nomeMorador: 'Sandra Maria Oliveira',
        numeroPessoas: 1,
        areaPrivativa: 62.70,
        fracaoIdeal: 0.1191,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '202',
        nomeMorador: 'Diogo Perini',
        numeroPessoas: 2,
        areaPrivativa: 38.89,
        fracaoIdeal: 0.0739,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '203',
        nomeMorador: 'Ana Cristina F. Côrtes',
        numeroPessoas: 2,
        areaPrivativa: 38.33,
        fracaoIdeal: 0.0728,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '301',
        nomeMorador: 'Ben Hur Luchese',
        numeroPessoas: 2,
        areaPrivativa: 42.46,
        fracaoIdeal: 0.0807,
        isSindico: true, // Síndico na competência do documento
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '302',
        nomeMorador: 'Laura Sofia Ortiz Cecconello',
        numeroPessoas: 2,
        areaPrivativa: 37.20,
        fracaoIdeal: 0.0707,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '303',
        nomeMorador: 'Daniel Caravaglia',
        numeroPessoas: 3,
        areaPrivativa: 38.89,
        fracaoIdeal: 0.0739,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '401',
        nomeMorador: 'Fernanda Facchin',
        numeroPessoas: 4,
        areaPrivativa: 42.68,
        fracaoIdeal: 0.0811,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '402',
        nomeMorador: 'Marciano Rossatto',
        numeroPessoas: 2,
        areaPrivativa: 37.20,
        fracaoIdeal: 0.0707,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
      Unidade(
        codigo: '403',
        nomeMorador: 'Salete Caravaglia',
        numeroPessoas: 1,
        areaPrivativa: 37.20,
        fracaoIdeal: 0.0707,
        isSindico: false,
        tipo: TipoUnidade.residencial,
      ),
    ];
  }
}
