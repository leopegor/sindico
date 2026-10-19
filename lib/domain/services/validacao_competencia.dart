import '../models/competencia.dart';

/// Regras de validação estritas aplicadas antes de persistir uma competência,
/// compartilhadas pelos repositórios local (SQLite) e remoto (Supabase).
void validarCompetencia(Competencia comp) {
  if (comp.mesReferencia.trim().isEmpty) {
    throw ArgumentError('O mês de referência é obrigatório.');
  }
  if (comp.nomeSindico.trim().isEmpty) {
    throw ArgumentError('O nome do(a) síndico(a) é obrigatório.');
  }
  if (comp.aptoSindico.trim().isEmpty) {
    throw ArgumentError('O apartamento do síndico / local de pagamento é obrigatório.');
  }
  if (comp.valorContaAgua < 0) {
    throw ArgumentError('O valor da conta de água não pode ser negativo.');
  }
  if (comp.valorEsgotoTotal < 0) {
    throw ArgumentError('O valor total do esgoto não pode ser negativo.');
  }
  if (comp.taxaMinimaAgua < 0) {
    throw ArgumentError('A taxa mínima de água não pode ser negativa.');
  }
  if (comp.valorContaEnergia < 0) {
    throw ArgumentError('O valor da conta de energia não pode ser negativo.');
  }
  if (comp.servicosLimpeza < 0) {
    throw ArgumentError('O valor dos serviços de limpeza não pode ser negativo.');
  }
  if (comp.fundoManutencaoMensal < 0) {
    throw ArgumentError('O fundo de manutenção não pode ser negativo.');
  }
}
