import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/domain/models/abatimento_divida.dart';
import 'package:projeto_sindico/domain/models/divida_anterior.dart';

void main() {
  group('DividaAnterior', () {
    test('toMap/fromMap preserva campos', () {
      final divida = DividaAnterior(
        unidadeCodigo: '101',
        valor: 450.75,
        atualizadoEm: DateTime(2026, 10, 16, 10, 30),
      );

      final map = divida.toMap();
      expect(map['id'], isNull);
      expect(map['unidade_codigo'], '101');
      expect(map['valor'], 450.75);

      final restored = DividaAnterior.fromMap(map);
      expect(restored.unidadeCodigo, '101');
      expect(restored.valor, 450.75);
      expect(restored.atualizadoEm, DateTime(2026, 10, 16, 10, 30));
    });

    test('copyWith atualiza valor mantendo id', () {
      final divida = DividaAnterior(
        id: 7,
        unidadeCodigo: 'LOJA',
        valor: 100.0,
        atualizadoEm: DateTime(2026, 1, 1),
      );
      final atualizada = divida.copyWith(valor: 250.0);
      expect(atualizada.id, 7);
      expect(atualizada.valor, 250.0);
      expect(atualizada.unidadeCodigo, 'LOJA');
    });
  });

  group('AbatimentoDivida', () {
    test('toMap/fromMap preserva campos', () {
      final abatimento = AbatimentoDivida(
        unidadeCodigo: '202',
        valor: 120.0,
        data: DateTime(2026, 10, 10),
        observacao: 'pagamento parcial em dinheiro',
        criadoEm: DateTime(2026, 10, 10, 15),
      );

      final map = abatimento.toMap();
      expect(map['unidade_codigo'], '202');
      expect(map['valor'], 120.0);
      expect(map['observacao'], 'pagamento parcial em dinheiro');

      final restored = AbatimentoDivida.fromMap(map);
      expect(restored.valor, 120.0);
      expect(restored.data, DateTime(2026, 10, 10));
      expect(restored.observacao, 'pagamento parcial em dinheiro');
      expect(restored.criadoEm, DateTime(2026, 10, 10, 15));
    });

    test('observacao nula serializa como null', () {
      final abatimento = AbatimentoDivida(
        unidadeCodigo: '301',
        valor: 50.0,
        data: DateTime(2026, 10, 1),
        criadoEm: DateTime(2026, 10, 1),
      );
      final restored =
          AbatimentoDivida.fromMap(abatimento.toMap());
      expect(restored.observacao, isNull);
    });
  });
}
