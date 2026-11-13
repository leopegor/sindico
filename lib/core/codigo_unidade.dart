String normalizarCodigoUnidade(String codigo) =>
    codigo.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toUpperCase();

bool mesmoCodigoUnidade(String a, String b) =>
    normalizarCodigoUnidade(a) == normalizarCodigoUnidade(b);
