import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/domain/models/unidade.dart';

void main() {
  group('Unidade Model Test', () {
    test('Deve inicializar as 11 unidades padrão com consistência', () {
      final unidades = Unidade.unidadesPadrao;
      expect(unidades.length, equals(11));

      final loja = unidades.firstWhere((u) => u.codigo == 'LOJA');
      expect(loja.isLoja, isTrue);
      expect(loja.numeroPessoas, equals(0));
      expect(loja.areaPrivativa, equals(44.11));

      final apto301 = unidades.firstWhere((u) => u.codigo == '301');
      expect(apto301.isSindico, isTrue);
      expect(apto301.numeroPessoas, equals(2));
      expect(apto301.areaPrivativa, equals(42.46));
    });

    test('Soma das frações ideais deve ser 100% e soma da área deve ser 526,27 m²', () {
      final unidades = Unidade.unidadesPadrao;
      final somaArea = unidades.fold(0.0, (acc, u) => acc + u.areaPrivativa);
      final somaFracao = unidades.fold(0.0, (acc, u) => acc + u.fracaoIdeal);

      expect(somaArea, closeTo(526.27, 0.05));
      expect(somaFracao, closeTo(1.00, 0.01));
    });

    test('Serialização e Desserialização toMap / fromMap', () {
      final u = Unidade.unidadesPadrao.first;
      final map = u.toMap();
      final u2 = Unidade.fromMap(map);

      expect(u2.codigo, equals(u.codigo));
      expect(u2.nomeMorador, equals(u.nomeMorador));
      expect(u2.numeroPessoas, equals(u.numeroPessoas));
      expect(u2.areaPrivativa, equals(u.areaPrivativa));
      expect(u2.fracaoIdeal, equals(u.fracaoIdeal));
      expect(u2.isSindico, equals(u.isSindico));
    });
  });
}
