import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/domain/models/competencia.dart';

void main() {
  group('Competencia Model Test', () {
    test('Competência padrão de Setembro/2026 deve ter valores corretos', () {
      final comp = Competencia.exemploSetembro2026;

      expect(comp.mesReferencia, equals('SETEMBRO'));
      expect(comp.anoReferencia, equals(2026));
      expect(comp.nomeSindico, equals('Rosângela Lucchese'));
      expect(comp.aptoSindico, equals('301'));
      expect(comp.valorContaAgua, equals(823.17));
      expect(comp.valorEsgotoTotal, equals(252.78));
      expect(comp.taxaMinimaAgua, equals(38.60));
      expect(comp.valorContaEnergia, equals(138.37));
      expect(comp.servicosLimpeza, equals(800.00));
      expect(comp.limpezaCaixasAgua, equals(360.00));
      expect(comp.fundoManutencaoMensal, equals(100.00));
      expect(comp.jurosMoraMensal, equals(0.015));
      expect(comp.multaMora, equals(0.02));
      expect(comp.divisorRateioSindico, equals(11));
    });

    test('Cálculos derivados do modelo', () {
      final comp = Competencia.exemploSetembro2026;

      expect(comp.custoTotalLimpeza, equals(800.00));
      expect(comp.taxaEsgotoPorUnidade, closeTo(22.98, 0.01));
      expect(comp.valorRateioAguaPessoas, closeTo(761.59, 0.01));
      expect(comp.parcelaSeguroPorUnidade, equals(0.0));
    });

    test('Serialização e Desserialização toMap / fromMap', () {
      final comp = Competencia.exemploSetembro2026;
      final map = comp.toMap();
      final comp2 = Competencia.fromMap(map);

      expect(comp2.mesReferencia, equals(comp.mesReferencia));
      expect(comp2.anoReferencia, equals(comp.anoReferencia));
      expect(comp2.valorContaAgua, equals(comp.valorContaAgua));
      expect(comp2.valorContaEnergia, equals(comp.valorContaEnergia));
      expect(comp2.nomeSindico, equals(comp.nomeSindico));
    });
  });
}
