import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/models/unidade.dart';
import '../../domain/models/competencia.dart';
import '../../domain/models/divida_anterior.dart';
import '../../domain/models/abatimento_divida.dart';
import 'unidade_repository.dart';
import 'competencia_repository.dart';
import 'divida_repository.dart';
import 'exportacao_backup_stub.dart'
    if (dart.library.io) 'exportacao_backup_io.dart'
    if (dart.library.js_interop) 'exportacao_backup_web.dart';

/// Resultado da operação de importação de backup
class BackupImportResult {
  final bool sucesso;
  final String mensagem;
  final int unidadesImportadas;
  final int competenciasImportadas;

  BackupImportResult({
    required this.sucesso,
    required this.mensagem,
    this.unidadesImportadas = 0,
    this.competenciasImportadas = 0,
  });
}

/// Serviço de exportação e restauração segura de backup local dos dados do condomínio.
class BackupService {
  final UnidadeRepository _unidadeRepo = UnidadeRepository();
  final CompetenciaRepository _competenciaRepo = CompetenciaRepository();
  final DividaRepository _dividaRepo = DividaRepository();

  /// Gera a estrutura JSON de backup contendo metadados, unidades, competências,
  /// dívidas anteriores manuais e abatimentos
  Future<String> gerarJsonBackup() async {
    final unidades = await _unidadeRepo.getTodas();
    final competencias = await _competenciaRepo.getTodas();
    final dividas = await _dividaRepo.getDividas();
    final abatimentos = await _dividaRepo.getAbatimentos();

    final dados = {
      'app': 'SindicoEvaristoLucchese',
      'versao_esquema': 2,
      'gerado_em': DateTime.now().toIso8601String(),
      'unidades': unidades.map((u) => u.toMap()).toList(),
      'competencias': competencias.map((c) => c.toMap()).toList(),
      'dividas_anteriores': dividas.values.map((d) => d.toMap()).toList(),
      'abatimentos_divida': abatimentos.map((a) => a.toMap()).toList(),
    };

    final rawJson = jsonEncode(dados);
    // Adiciona checksum SHA-256 para verificação de integridade contra corrupção
    final hash = sha256.convert(utf8.encode(rawJson)).toString();

    final payloadFinal = {
      'checksum_sha256': hash,
      'payload': dados,
    };

    return const JsonEncoder.withIndent('  ').convert(payloadFinal);
  }

  /// Exporta o backup para um arquivo .json.
  ///
  /// Na web dispara o download do arquivo pelo navegador; em plataformas
  /// nativas abre o diálogo de compartilhamento do sistema.
  Future<String> exportarBackup() async {
    final jsonString = await gerarJsonBackup();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final fileName = 'backup_condominio_evaristo_lucchese_$timestamp.json';

    return exportarArquivoBackup(jsonString, fileName);
  }

  /// Restaura os dados a partir de uma string JSON com verificação rigorosa de integridade
  Future<BackupImportResult> restaurarDeJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!decoded.containsKey('checksum_sha256') || !decoded.containsKey('payload')) {
        return BackupImportResult(
          sucesso: false,
          mensagem: 'Arquivo de backup inválido: cabeçalho de integridade ausente.',
        );
      }

      final hashEsperado = decoded['checksum_sha256'] as String;
      final payload = decoded['payload'] as Map<String, dynamic>;
      final rawPayload = jsonEncode(payload);
      final hashCalculado = sha256.convert(utf8.encode(rawPayload)).toString();

      if (hashEsperado != hashCalculado) {
        return BackupImportResult(
          sucesso: false,
          mensagem: 'Falha de integridade: o arquivo de backup foi corrompido ou modificado.',
        );
      }

      if (payload['app'] != 'SindicoEvaristoLucchese') {
        return BackupImportResult(
          sucesso: false,
          mensagem: 'Arquivo de backup incompatível com este aplicativo.',
        );
      }

      final unidadesJson = payload['unidades'] as List<dynamic>? ?? [];
      final competenciasJson = payload['competencias'] as List<dynamic>? ?? [];

      // Importar unidades
      int contUnidades = 0;
      for (final uMap in unidadesJson) {
        final unidade = Unidade.fromMap(uMap as Map<String, dynamic>);
        final existente = await _unidadeRepo.getPorCodigo(unidade.codigo);
        if (existente != null) {
          await _unidadeRepo.atualizar(unidade.copyWith(id: existente.id));
        }
        contUnidades++;
      }

      // Importar competências
      int contCompetencias = 0;
      for (final cMap in competenciasJson) {
        final mapSemId = Map<String, dynamic>.from(cMap as Map<String, dynamic>);
        mapSemId.remove('id');
        final comp = Competencia.fromMap(mapSemId);
        await _competenciaRepo.inserir(comp);
        contCompetencias++;
      }

      // Importar dívidas anteriores e abatimentos (presentes em backups v2+)
      if (payload.containsKey('dividas_anteriores')) {
        final dividasJson = payload['dividas_anteriores'] as List<dynamic>? ?? [];
        final dividas = <DividaAnterior>[];
        for (final dMap in dividasJson) {
          final map = Map<String, dynamic>.from(dMap as Map<String, dynamic>);
          map.remove('id');
          dividas.add(DividaAnterior.fromMap(map));
        }
        await _dividaRepo.substituirDividas(dividas);
      }
      if (payload.containsKey('abatimentos_divida')) {
        final abatJson = payload['abatimentos_divida'] as List<dynamic>? ?? [];
        final abatimentos = <AbatimentoDivida>[];
        for (final aMap in abatJson) {
          final map = Map<String, dynamic>.from(aMap as Map<String, dynamic>);
          map.remove('id');
          abatimentos.add(AbatimentoDivida.fromMap(map));
        }
        await _dividaRepo.substituirAbatimentos(abatimentos);
      }

      return BackupImportResult(
        sucesso: true,
        mensagem: 'Backup restaurado com sucesso!',
        unidadesImportadas: contUnidades,
        competenciasImportadas: contCompetencias,
      );
    } catch (e) {
      return BackupImportResult(
        sucesso: false,
        mensagem: 'Erro durante a importação do backup: $e',
      );
    }
  }
}
