class Credenciais {
  const Credenciais._();

  static const String usuario = String.fromEnvironment(
    'AUTH_USUARIO',
    defaultValue: 'sindico',
  );

  static const String senha = String.fromEnvironment(
    'AUTH_SENHA',
    defaultValue: 'evaristo2026',
  );

  static bool validar(String usuarioInformado, String senhaInformada) {
    return usuarioInformado.trim() == usuario && senhaInformada == senha;
  }
}
