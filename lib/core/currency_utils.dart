import 'package:intl/intl.dart';

/// Utilitários para formatação e manipulação monetária e numérica.
class CurrencyUtils {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  /// Formata um valor double como moeda brasileira (ex: "R$ 1.234,56")
  static String format(double? value) {
    if (value == null) return 'R\$ 0,00';
    return _currencyFormatter.format(value);
  }

  /// Formata um valor sem o símbolo R$ (ex: "1.234,56")
  static String formatClean(double? value) {
    if (value == null) return '0,00';
    return _compactCurrencyFormatter.format(value).trim();
  }

  /// Formata percentual (ex: 0.02 -> "2,00%")
  static String formatPercent(double? value, {int decimalDigits = 2}) {
    if (value == null) return '0,00%';
    final n = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '%',
      decimalDigits: decimalDigits,
      customPattern: '#,##0.00 \u00A4',
    );
    return n.format(value * 100).replaceAll('\u00A4', '%').trim();
  }

  /// Faz o parse seguro de String para double considerando vírgula ou ponto
  static double parse(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    // Remove símbolos e espaços
    String cleaned = text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .trim();
    if (cleaned.isEmpty) return 0.0;

    // Se contém vírgula, a vírgula é o separador decimal e pontos são milhares
    if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains('.')) {
      // Se não contém vírgula, verifica se o ponto é decimal ou milhar
      final parts = cleaned.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // Ex: "150.5" ou "150.50" -> ponto é decimal, mantém o ponto
      } else {
        // Ex: "1.000" ou "1.000.000" -> pontos são separadores de milhar
        cleaned = cleaned.replaceAll('.', '');
      }
    }
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Arredonda para 2 casas decimais com precisão monetária padrão
  static double round2(double value) {
    return (value * 100).roundToDouble() / 100.0;
  }
}
