import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Em plataformas nativas, grava o backup em arquivo temporário e abre o
/// diálogo de compartilhamento do sistema.
Future<String> exportarArquivoBackup(String jsonString, String nomeArquivo) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$nomeArquivo');
  await file.writeAsString(jsonString, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Backup do Condomínio Evaristo Lucchese',
      text: 'Arquivo de backup dos dados de rateio e cadastro do condomínio.',
    ),
  );

  return file.path;
}
