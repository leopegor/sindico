/// Representa a apuração das contas do condomínio para um mês/competência específico.
class Competencia {
  final int? id;
  final String mesReferencia; // ex: "SETEMBRO"
  final int anoReferencia; // ex: 2026
  final DateTime dataVencimento; // ex: 15/10/2026
  final String nomeSindico; // ex: "Rosângela Lucchese"
  final String aptoSindico; // ex: "301"
  final String periodoMandato; // ex: "ago/2026 à jul/2027"

  // Água
  final double valorContaAgua; // D7 (ex: 823.17)
  final double valorEsgotoTotal; // D8 (ex: 252.78)
  final double taxaMinimaAgua; // D10 (ex: 38.60)
  final double? consumoAguaM3; // D11 (ex: 72)
  final double fmrh; // D13 (ex: 0.00)

  // Energia Elétrica
  final double? consumoEnergiaKwh; // D16 (ex: 82)
  final double valorContaEnergia; // D17 (ex: 138.37)

  // Limpeza
  final double servicosLimpeza; // D20 (ex: 800.00)
  final double materiaisLimpeza; // D21 (ex: 0.00)

  // Outras Despesas
  final double limpezaCaixasAgua; // D25 (ex: 360.00)
  final String? discriminacaoOutrasDespesas; // Discriminação das demais despesas (caixas d'água, etc.)
  final double fundoManutencaoMensal; // D27 (ex: 100.00)
  final String? discriminacaoFundoManutencao; // Discriminação do fundo emergencial/manutenção

  // Seguro
  final double? valorApolice; // D30 (opcional, vazio na planilha)
  final int? numeroParcelas; // D31 (opcional, 1 a 12)

  // Juros e Multa
  final double jurosMoraMensal; // D35 (ex: 0.015 = 1,5%)
  final double multaMora; // D36 (ex: 0.02 = 2,0%)

  // Configurações Técnicas
  final int divisorRateioSindico; // D40 (11 na planilha original, ou 10 para fechamento exato)
  final double fatorAtraso; // 0.95 (divisão por 0.95 = acréscimo de 5.26%)
  final String? observacoes;
  final DateTime criadoEm;

  const Competencia({
    this.id,
    required this.mesReferencia,
    required this.anoReferencia,
    required this.dataVencimento,
    required this.nomeSindico,
    required this.aptoSindico,
    this.periodoMandato = 'ago/2026 à jul/2027',
    required this.valorContaAgua,
    required this.valorEsgotoTotal,
    required this.taxaMinimaAgua,
    this.consumoAguaM3,
    this.fmrh = 0.0,
    this.consumoEnergiaKwh,
    required this.valorContaEnergia,
    required this.servicosLimpeza,
    this.materiaisLimpeza = 0.0,
    this.limpezaCaixasAgua = 0.0,
    this.discriminacaoOutrasDespesas,
    required this.fundoManutencaoMensal,
    this.discriminacaoFundoManutencao,
    this.valorApolice,
    this.numeroParcelas,
    this.jurosMoraMensal = 0.015,
    this.multaMora = 0.02,
    this.divisorRateioSindico = 11,
    this.fatorAtraso = 0.95,
    this.observacoes,
    required this.criadoEm,
  });

  /// Custo total de limpeza (Mão de obra + Materiais)
  double get custoTotalLimpeza => servicosLimpeza + materiaisLimpeza;

  /// Parcela de seguro por unidade habitacional (quando houver apólice)
  double get parcelaSeguroPorUnidade {
    if (valorApolice == null || valorApolice! <= 0) return 0.0;
    if (numeroParcelas == null || numeroParcelas! <= 0) return 0.0;
    final valorParcela = valorApolice! / numeroParcelas!;
    return valorParcela / 10.0; // Dividido por 10 apartamentos
  }

  /// Taxa de esgoto por unidade (dividido por 11 unidades)
  double get taxaEsgotoPorUnidade => valorEsgotoTotal / 11.0;

  /// Valor líquido para rateio de água por pessoa: Conta - Esgoto - Taxa Mínima
  double get valorRateioAguaPessoas {
    final liquido = valorContaAgua - taxaEsgotoPorUnidade - taxaMinimaAgua;
    return liquido > 0 ? liquido : 0.0;
  }

  Competencia copyWith({
    int? id,
    String? mesReferencia,
    int? anoReferencia,
    DateTime? dataVencimento,
    String? nomeSindico,
    String? aptoSindico,
    String? periodoMandato,
    double? valorContaAgua,
    double? valorEsgotoTotal,
    double? taxaMinimaAgua,
    double? consumoAguaM3,
    double? fmrh,
    double? consumoEnergiaKwh,
    double? valorContaEnergia,
    double? servicosLimpeza,
    double? materiaisLimpeza,
    double? limpezaCaixasAgua,
    String? discriminacaoOutrasDespesas,
    double? fundoManutencaoMensal,
    String? discriminacaoFundoManutencao,
    double? valorApolice,
    int? numeroParcelas,
    double? jurosMoraMensal,
    double? multaMora,
    int? divisorRateioSindico,
    double? fatorAtraso,
    String? observacoes,
    DateTime? criadoEm,
  }) {
    return Competencia(
      id: id ?? this.id,
      mesReferencia: mesReferencia ?? this.mesReferencia,
      anoReferencia: anoReferencia ?? this.anoReferencia,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      nomeSindico: nomeSindico ?? this.nomeSindico,
      aptoSindico: aptoSindico ?? this.aptoSindico,
      periodoMandato: periodoMandato ?? this.periodoMandato,
      valorContaAgua: valorContaAgua ?? this.valorContaAgua,
      valorEsgotoTotal: valorEsgotoTotal ?? this.valorEsgotoTotal,
      taxaMinimaAgua: taxaMinimaAgua ?? this.taxaMinimaAgua,
      consumoAguaM3: consumoAguaM3 ?? this.consumoAguaM3,
      fmrh: fmrh ?? this.fmrh,
      consumoEnergiaKwh: consumoEnergiaKwh ?? this.consumoEnergiaKwh,
      valorContaEnergia: valorContaEnergia ?? this.valorContaEnergia,
      servicosLimpeza: servicosLimpeza ?? this.servicosLimpeza,
      materiaisLimpeza: materiaisLimpeza ?? this.materiaisLimpeza,
      limpezaCaixasAgua: limpezaCaixasAgua ?? this.limpezaCaixasAgua,
      discriminacaoOutrasDespesas: discriminacaoOutrasDespesas ?? this.discriminacaoOutrasDespesas,
      fundoManutencaoMensal: fundoManutencaoMensal ?? this.fundoManutencaoMensal,
      discriminacaoFundoManutencao: discriminacaoFundoManutencao ?? this.discriminacaoFundoManutencao,
      valorApolice: valorApolice ?? this.valorApolice,
      numeroParcelas: numeroParcelas ?? this.numeroParcelas,
      jurosMoraMensal: jurosMoraMensal ?? this.jurosMoraMensal,
      multaMora: multaMora ?? this.multaMora,
      divisorRateioSindico: divisorRateioSindico ?? this.divisorRateioSindico,
      fatorAtraso: fatorAtraso ?? this.fatorAtraso,
      observacoes: observacoes ?? this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'mes_referencia': mesReferencia,
      'ano_referencia': anoReferencia,
      'data_vencimento': dataVencimento.toIso8601String(),
      'nome_sindico': nomeSindico,
      'apto_sindico': aptoSindico,
      'periodo_mandato': periodoMandato,
      'valor_conta_agua': valorContaAgua,
      'valor_esgoto_total': valorEsgotoTotal,
      'taxa_minima_agua': taxaMinimaAgua,
      'consumo_agua_m3': consumoAguaM3,
      'fmrh': fmrh,
      'consumo_energia_kwh': consumoEnergiaKwh,
      'valor_conta_energia': valorContaEnergia,
      'servicos_limpeza': servicosLimpeza,
      'materiais_limpeza': materiaisLimpeza,
      'limpeza_caixas_agua': limpezaCaixasAgua,
      'discriminacao_outras_despesas': discriminacaoOutrasDespesas,
      'fundo_manutencao_mensal': fundoManutencaoMensal,
      'discriminacao_fundo_manutencao': discriminacaoFundoManutencao,
      'valor_apolice': valorApolice,
      'numero_parcelas': numeroParcelas,
      'juros_mora_mensal': jurosMoraMensal,
      'multa_mora': multaMora,
      'divisor_rateio_sindico': divisorRateioSindico,
      'fator_atraso': fatorAtraso,
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Competencia.fromMap(Map<String, dynamic> map) {
    return Competencia(
      id: map['id'] as int?,
      mesReferencia: map['mes_referencia'] as String,
      anoReferencia: (map['ano_referencia'] as num).toInt(),
      dataVencimento: DateTime.parse(map['data_vencimento'] as String),
      nomeSindico: map['nome_sindico'] as String,
      aptoSindico: map['apto_sindico'] as String,
      periodoMandato: map['periodo_mandato'] as String? ?? 'ago/2026 à jul/2027',
      valorContaAgua: (map['valor_conta_agua'] as num).toDouble(),
      valorEsgotoTotal: (map['valor_esgoto_total'] as num).toDouble(),
      taxaMinimaAgua: (map['taxa_minima_agua'] as num).toDouble(),
      consumoAguaM3: (map['consumo_agua_m3'] as num?)?.toDouble(),
      fmrh: (map['fmrh'] as num?)?.toDouble() ?? 0.0,
      consumoEnergiaKwh: (map['consumo_energia_kwh'] as num?)?.toDouble(),
      valorContaEnergia: (map['valor_conta_energia'] as num).toDouble(),
      servicosLimpeza: (map['servicos_limpeza'] as num).toDouble(),
      materiaisLimpeza: (map['materiais_limpeza'] as num?)?.toDouble() ?? 0.0,
      limpezaCaixasAgua: (map['limpeza_caixas_agua'] as num?)?.toDouble() ?? 0.0,
      discriminacaoOutrasDespesas: map['discriminacao_outras_despesas'] as String?,
      fundoManutencaoMensal: (map['fundo_manutencao_mensal'] as num).toDouble(),
      discriminacaoFundoManutencao: map['discriminacao_fundo_manutencao'] as String?,
      valorApolice: (map['valor_apolice'] as num?)?.toDouble(),
      numeroParcelas: (map['numero_parcelas'] as num?)?.toInt(),
      jurosMoraMensal: (map['juros_mora_mensal'] as num?)?.toDouble() ?? 0.015,
      multaMora: (map['multa_mora'] as num?)?.toDouble() ?? 0.02,
      divisorRateioSindico: (map['divisor_rateio_sindico'] as num?)?.toInt() ?? 11,
      fatorAtraso: (map['fator_atraso'] as num?)?.toDouble() ?? 0.95,
      observacoes: map['observacoes'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }

  /// Dados de exemplo padrão idênticos ao mês de Setembro/2026 da planilha
  static Competencia get exemploSetembro2026 {
    return Competencia(
      mesReferencia: 'SETEMBRO',
      anoReferencia: 2026,
      dataVencimento: DateTime(2026, 10, 15),
      nomeSindico: 'Rosângela Lucchese',
      aptoSindico: '301',
      periodoMandato: 'ago/2026 à jul/2027',
      valorContaAgua: 823.17,
      valorEsgotoTotal: 252.78,
      taxaMinimaAgua: 38.60,
      consumoAguaM3: 72,
      fmrh: 0.0,
      consumoEnergiaKwh: 82,
      valorContaEnergia: 138.37,
      servicosLimpeza: 800.0,
      materiaisLimpeza: 0.0,
      limpezaCaixasAgua: 360.0,
      discriminacaoOutrasDespesas: 'Limpeza de caixas d\'água',
      fundoManutencaoMensal: 100.0,
      discriminacaoFundoManutencao: 'Fundo de manutenções emergenciais',
      valorApolice: null,
      numeroParcelas: null,
      jurosMoraMensal: 0.015,
      multaMora: 0.02,
      divisorRateioSindico: 11,
      fatorAtraso: 0.95,
      criadoEm: DateTime(2026, 9, 30),
    );
  }
}
