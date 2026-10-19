/// Implementação não suportada para plataformas sem IO nem JS.
Future<String> exportarArquivoBackup(String jsonString, String nomeArquivo) {
  throw UnsupportedError('Exportação de arquivo não suportada nesta plataforma.');
}
