import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/core/field_help_definitions.dart';
import 'package:projeto_sindico/domain/models/competencia.dart';
import 'package:projeto_sindico/domain/models/unidade.dart';
import 'package:projeto_sindico/domain/services/calculadora_rateio_service.dart';
import 'package:projeto_sindico/ui/widgets/conferencia_card.dart';
import 'package:projeto_sindico/ui/widgets/contextual_help_field.dart';

void main() {
  testWidgets('ConferenciaCard exibe status 100% fechado', (WidgetTester tester) async {
    final comp = Competencia.exemploSetembro2026;
    final unidades = Unidade.unidadesPadrao;
    final fechamento = CalculadoraRateioService.calcular(
      competencia: comp,
      unidades: unidades,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConferenciaCard(fechamento: fechamento),
        ),
      ),
    );

    expect(find.text('Conferência Contábil: 100% Fechada'), findsOneWidget);
    expect(find.text('Água (CORSAN)'), findsOneWidget);
    expect(find.text('Energia Elétrica (RGE)'), findsOneWidget);
    expect(find.text('Limpeza e Conservação'), findsOneWidget);
    expect(find.text('Previsão de Arrecadação (Total)'), findsOneWidget);
  });

  testWidgets('ContextualHelpField exibe nome, instrução e botão de ajuda', (WidgetTester tester) async {
    final controller = TextEditingController(text: '823,17');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContextualHelpField(
            helpInfo: FieldHelpCatalog.valorContaAgua,
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('Valor Total da Conta de Água'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);

    // Toca no botão de ajuda para abrir o modal explicativo
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('Finalidade'), findsOneWidget);
    expect(find.text('Como preencher'), findsOneWidget);
    expect(find.text('Onde encontrar'), findsOneWidget);
    expect(find.text('Exemplo prático'), findsOneWidget);
  });
}
