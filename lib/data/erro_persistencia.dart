/// Erro de acesso a dados com mensagem amigável para exibição na interface.
class ErroPersistencia implements Exception {
  final String mensagem;
  final Object? causa;

  ErroPersistencia(this.mensagem, {this.causa});

  @override
  String toString() => mensagem;
}
