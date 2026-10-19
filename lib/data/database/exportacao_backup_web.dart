import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// No navegador, dispara o download do backup como arquivo .json.
Future<String> exportarArquivoBackup(String jsonString, String nomeArquivo) async {
  final bytes = Uint8List.fromList(utf8.encode(jsonString));
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = nomeArquivo;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return nomeArquivo;
}
