/// Estrutura que define as orientações contextuais obrigatórias para um campo.
class FieldHelpInfo {
  final String nome;
  final String finalidade;
  final String instrucao;
  final String origem;
  final String exemplo;
  final String formato;
  final bool obrigatorio;
  final String validacao;
  final String efeito;

  const FieldHelpInfo({
    required this.nome,
    required this.finalidade,
    required this.instrucao,
    required this.origem,
    required this.exemplo,
    required this.formato,
    required this.obrigatorio,
    required this.validacao,
    required this.efeito,
  });
}

/// Catálogo completo de orientações contextuais específicas para cada campo do aplicativo,
/// em estrita conformidade com a documentação da aba DADO_RECIBOS.
class FieldHelpCatalog {
  static const mesReferencia = FieldHelpInfo(
    nome: 'Mês de Referência',
    finalidade: 'Identificar a competência contábil das despesas rateadas no demonstrativo e recibos.',
    instrucao: 'Informe o mês ou selecione no calendário a competência que está sendo apurada.',
    origem: 'Calendário de fechamento mensal do condomínio.',
    exemplo: 'SETEMBRO ou Setembro/2026',
    formato: 'Texto / Mês',
    obrigatorio: true,
    validacao: 'Não pode ficar em branco.',
    efeito: 'Aparece no cabeçalho de todos os 11 recibos e na identificação do demonstrativo.',
  );

  static const dataVencimento = FieldHelpInfo(
    nome: 'Data de Vencimento',
    finalidade: 'Definir o prazo limite para pagamento do condomínio sem aplicação de acréscimos ou juros.',
    instrucao: 'Selecione o dia, mês e ano em que os boletos/recibos vencerão.',
    origem: 'Definição da assembleia geral ou convenção (usualmente dia 10 ou 15 do mês seguinte).',
    exemplo: '15/10/2026',
    formato: 'Data no formato DD/MM/AAAA',
    obrigatorio: true,
    validacao: 'Deve ser uma data válida e posterior ou igual ao mês de apuração.',
    efeito: 'Determina a contagem dos prazos das 7 faixas de vencimento e mora.',
  );

  static const nomeSindico = FieldHelpInfo(
    nome: 'Nome do(a) Síndico(a)',
    finalidade: 'Identificar formalmente o responsável pela gestão e emissão do demonstrativo.',
    instrucao: 'Digite o nome completo do(a) síndico(a) em exercício.',
    origem: 'Ata da assembleia que elegeu o corpo diretivo.',
    exemplo: 'Rosângela Lucchese',
    formato: 'Texto com nome e sobrenome',
    obrigatorio: true,
    validacao: 'Mínimo de 3 caracteres.',
    efeito: 'Impresso nos recibos no campo de contato e responsável pelo recebimento.',
  );

  static const aptoSindico = FieldHelpInfo(
    nome: 'Apartamento do(a) Síndico(a) / Local de Pagamento',
    finalidade: 'Indicar onde os moradores devem efetuar ou comprovar o pagamento do recibo.',
    instrucao: 'Informe a identificação da unidade onde o(a) síndico(a) atende.',
    origem: 'Unidade ocupada pelo síndico eleito.',
    exemplo: '301',
    formato: 'Número da unidade (ex: 301)',
    obrigatorio: true,
    validacao: 'Deve corresponder a uma unidade residencial existente.',
    efeito: 'Aparece na instrução de pagamento de cada recibo e define qual unidade recebe a isenção operacional.',
  );

  static const periodoMandato = FieldHelpInfo(
    nome: 'Período do Mandato',
    finalidade: 'Informar o período de vigência legal da gestão atual aos condôminos.',
    instrucao: 'Digite a vigência do mandato aprovado em ata.',
    origem: 'Ata de eleição de síndico.',
    exemplo: 'ago/2026 à jul/2027',
    formato: 'Texto (ex: mmm/aaaa à mmm/aaaa)',
    obrigatorio: false,
    validacao: 'Opcional, porém recomendado para clareza da prestação de contas.',
    efeito: 'Exibido no cabeçalho do demonstrativo geral de despesas.',
  );

  static const valorContaAgua = FieldHelpInfo(
    nome: 'Valor Total da Conta de Água',
    finalidade: 'Registrar o custo total faturado pela concessionária de água/esgoto (CORSAN).',
    instrucao: 'Digite o valor total a pagar constante na fatura de água.',
    origem: 'Fatura da CORSAN / Concessionária de saneamento.',
    exemplo: 'R\$ 823,17',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: true,
    validacao: 'Deve ser maior que zero e maior ou igual à soma de esgoto e taxa mínima.',
    efeito: 'Alimenta a linha 7 da planilha. O valor excedente é distribuído proporcionalmente ao número de moradores.',
  );

  static const valorEsgotoTotal = FieldHelpInfo(
    nome: 'Valor Total de Esgoto / Faixa de Transição',
    finalidade: 'Destacar a parcela de esgoto cobrada na fatura de água.',
    instrucao: 'Informe o valor total do esgoto destacado na fatura.',
    origem: 'Campo "Esgoto / Faixa de Transição" na fatura de água.',
    exemplo: 'R\$ 252,78',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: true,
    validacao: 'Não pode ser negativo nem superior ao valor total da conta d\'água.',
    efeito: 'Dividido igualmente entre as 11 unidades do condomínio (R\$ 22,98 por unidade no exemplo).',
  );

  static const taxaMinimaAgua = FieldHelpInfo(
    nome: 'Taxa Mínima de Água (Loja)',
    finalidade: 'Atribuir a cota mínima d\'água à unidade comercial (Loja), que não possui moradores residentes.',
    instrucao: 'Informe o valor da tarifa mínima de água vigente na fatura.',
    origem: 'Fatura de água (tarifa básica comercial/mínima).',
    exemplo: 'R\$ 38,60',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: true,
    validacao: 'Valor não negativo.',
    efeito: 'Deduzido do rateio geral e cobrado diretamente da Loja somado à sua taxa de esgoto.',
  );

  static const consumoAguaM3 = FieldHelpInfo(
    nome: 'Consumo de Água (m³)',
    finalidade: 'Demonstrar o volume físico de água consumido no mês para acompanhamento histórico dos condôminos.',
    instrucao: 'Digite os metros cúbicos medidos no hidrômetro geral.',
    origem: 'Campo "Consumo Faturado (m³)" da fatura de água.',
    exemplo: '72 m³',
    formato: 'Número inteiro ou decimal',
    obrigatorio: false,
    validacao: 'Valor maior ou igual a zero.',
    efeito: 'Informativo no quadro "Dados utilizados para os cálculos" dos recibos.',
  );

  static const fmrh = FieldHelpInfo(
    nome: 'FMRH (Fundo Municipal de Recursos Hídricos)',
    finalidade: 'Lançar taxa ambiental municipal quando discriminada na fatura.',
    instrucao: 'Informe o valor do FMRH se cobrado na fatura.',
    origem: 'Fatura de água.',
    exemplo: 'R\$ 0,00',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: false,
    validacao: 'Valor maior ou igual a zero.',
    efeito: 'Compositor da conta de água quando houver cobrança municipal.',
  );

  static const valorContaEnergia = FieldHelpInfo(
    nome: 'Valor da Conta de Energia Elétrica',
    finalidade: 'Registrar a despesa com iluminação e força das áreas comuns do prédio.',
    instrucao: 'Digite o valor total da conta de energia elétrica do condomínio.',
    origem: 'Fatura da RGE / Concessionária de energia elétrica.',
    exemplo: 'R\$ 138,37',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: true,
    validacao: 'Deve ser maior ou igual a zero.',
    efeito: 'Dividido igualmente entre os 10 apartamentos residenciais (a Loja não tem acesso e não usa as áreas comuns).',
  );

  static const consumoEnergiaKwh = FieldHelpInfo(
    nome: 'Consumo de Energia (KWh)',
    finalidade: 'Registrar o consumo elétrico medido no mês para conferência.',
    instrucao: 'Informe a quantidade de KWh consumida.',
    origem: 'Fatura de energia elétrica.',
    exemplo: '82 KWh',
    formato: 'Número inteiro ou decimal',
    obrigatorio: false,
    validacao: 'Valor maior ou igual a zero.',
    efeito: 'Informativo nos recibos e no histórico de despesas.',
  );

  static const servicosLimpeza = FieldHelpInfo(
    nome: 'Serviços de Limpeza (Mão de Obra)',
    finalidade: 'Remuneração da mão de obra de limpeza das áreas comuns.',
    instrucao: 'Informe o valor pago pelo serviço de limpeza das áreas comuns no mês.',
    origem: 'Recibo de prestação de serviços / diarista / empresa contratada.',
    exemplo: 'R\$ 800,00',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: true,
    validacao: 'Valor maior ou igual a zero.',
    efeito: 'Soma-se aos materiais de limpeza e é rateado igualmente entre as 11 unidades (loja + 10 apartamentos).',
  );

  static const materiaisLimpeza = FieldHelpInfo(
    nome: 'Materiais de Limpeza',
    finalidade: 'Reembolsar ou lançar a compra de produtos de limpeza utilizados nas áreas comuns.',
    instrucao: 'Informe o total gasto com compras de produtos de limpeza se houver no mês.',
    origem: 'Notas fiscais / cupons de compra em supermercado ou distribuidora.',
    exemplo: 'R\$ 0,00',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: false,
    validacao: 'Valor maior ou igual a zero.',
    efeito: 'Soma-se à mão de obra e entra no rateio da limpeza geral dividido por 11 unidades.',
  );

  static const limpezaCaixasAgua = FieldHelpInfo(
    nome: 'Outras Despesas / Limpeza de Caixas d\'Água',
    finalidade: 'Lançar despesas extraordinárias não cobertas pelo fundo emergencial (ou estornos com sinal negativo).',
    instrucao: 'Digite o valor do serviço pontual ou estorno.',
    origem: 'Recibo ou nota do prestador de serviço de limpeza de caixas ou reparo avulso.',
    exemplo: 'R\$ 360,00',
    formato: 'Moeda brasileira (R\$ 0,00) - aceita negativo para estorno',
    obrigatorio: false,
    validacao: 'Pode ser zero, positivo ou negativo (estorno).',
    efeito: 'Rateado entre 10 unidades pagantes (excluída a unidade do síndico conforme convenção).',
  );

  static const fundoManutencaoMensal = FieldHelpInfo(
    nome: 'Fundo para Manutenções Emergenciais',
    finalidade: 'Reserva financeira mensal para manutenções urgentes e preservação patrimonial.',
    instrucao: 'Informe a cota mensal aprovada em assembleia por apartamento.',
    origem: 'Deliberação de assembleia geral de condomínio.',
    exemplo: 'R\$ 100,00',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: true,
    validacao: 'Valor maior ou igual a zero.',
    efeito: 'Cobrado de todos os 10 apartamentos (inclusive do síndico). A Loja não contribui no fundo preventivo regular.',
  );

  static const valorApoliceSeguro = FieldHelpInfo(
    nome: 'Valor Total da Apólice de Seguro',
    finalidade: 'Cobrança do seguro predial obrigatório contra incêndio/sinistros.',
    instrucao: 'Deixe em branco ou zerado se não houver seguro ativo. Se houver, digite o valor total da apólice anual.',
    origem: 'Apólice emitida pela seguradora.',
    exemplo: 'R\$ 2.400,00 (ou vazio)',
    formato: 'Moeda brasileira (R\$ 0,00)',
    obrigatorio: false,
    validacao: 'Se informado, o número de parcelas deve ser maior que zero.',
    efeito: 'Quando ativo, divide o valor da parcela pelas 10 unidades residenciais.',
  );

  static const numeroParcelasSeguro = FieldHelpInfo(
    nome: 'Número de Parcelas do Seguro',
    finalidade: 'Definir em quantas vezes a apólice foi fracionada.',
    instrucao: 'Informe em quantas prestações o seguro será pago (ex: 1 a 10).',
    origem: 'Carnê ou proposta da apólice de seguro.',
    exemplo: '8',
    formato: 'Número inteiro (1 a 12)',
    obrigatorio: false,
    validacao: 'Obrigatório se a apólice for informada; deve ser entre 1 e 12.',
    efeito: 'Calcula o valor mensal: (Apólice ÷ Parcelas) ÷ 10 unidades.',
  );

  static const jurosMoraMensal = FieldHelpInfo(
    nome: 'Taxa de Juros de Mora ao Mês',
    finalidade: 'Definir os juros aplicados para pagamentos efetuados após a data de vencimento.',
    instrucao: 'Informe o percentual mensal de juros (padrão histórico da assembleia: 1,50%).',
    origem: 'Convenção do condomínio e assembleia geral.',
    exemplo: '1,50%',
    formato: 'Percentual (0,00%)',
    obrigatorio: true,
    validacao: 'Deve ser entre 0% e 20%.',
    efeito: 'Calcula o acréscimo progressivo nas faixas de atraso a partir de 30 dias.',
  );

  static const multaMora = FieldHelpInfo(
    nome: 'Taxa de Multa de Mora',
    finalidade: 'Penalidade legal aplicada aos atrasos superiores a 30 dias.',
    instrucao: 'Informe o percentual de multa (padrão legal: 2,00% nos termos do Art. 1.336 §1º do Código Civil).',
    origem: 'Código Civil Brasileiro e deliberação de assembleia.',
    exemplo: '2,00%',
    formato: 'Percentual (0,00%)',
    obrigatorio: true,
    validacao: 'Pelo Código Civil brasileiro, o teto legal de multa condominial é 2%.',
    efeito: 'Adicionada ao total devido a partir do 30º dia de atraso em todas as faixas subsequentes.',
  );

  static const fatorAtraso = FieldHelpInfo(
    nome: 'Fator de Atraso até 30 Dias',
    finalidade: 'Definir o acréscimo aplicado à base de cobrança para gerar a faixa de até 30 dias de atraso.',
    instrucao: 'Informe o divisor aplicado ao valor do vencimento. O padrão 0,95 equivale a um acréscimo de 5,26%.',
    origem: 'Fórmula histórica da planilha (valor no vencimento ÷ 0,95).',
    exemplo: '0,95',
    formato: 'Decimal entre 0,01 e 1,00',
    obrigatorio: true,
    validacao: 'Deve ser maior que 0 e menor ou igual a 1,00.',
    efeito: 'Calcula a faixa até 30 dias como valor no vencimento ÷ fator.',
  );

  static const divisorRateioSindico = FieldHelpInfo(
    nome: 'Divisor do Rateio do Síndico',
    finalidade: 'Definir o número de unidades participantes no rateio da isenção de despesas operacionais do síndico.',
    instrucao: 'Selecione entre 11 unidades (legado da fórmula da planilha original) ou 10 unidades (fechamento financeiro exato de 100%).',
    origem: 'Linha 40 da planilha (onde consta 11) versus quantidade real de pagantes (10 unidades).',
    exemplo: '11 (planilha original) ou 10 (fechamento 100%)',
    formato: 'Opção 10 ou 11',
    obrigatorio: true,
    validacao: 'Deve ser 10 ou 11.',
    efeito: 'Define se D39/11 ou D39/10 será cobrado na coluna de rateio do síndico de cada unidade pagante.',
  );
}
