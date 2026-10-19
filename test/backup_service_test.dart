import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_sindico/data/database/backup_service.dart';

void main() {
  group('Backup & Integridade Test', () {
    test('Estrutura de payload com SHA-256 deve ser validada com sucesso', () async {
      final payload = {
        'app': 'SindicoEvaristoLucchese',
        'versao_esquema': 1,
        'gerado_em': DateTime.now().toIso8601String(),
        'unidades': [],
        'competencias': [],
      };

      final rawJson = jsonEncode(payload);
      final hash = sha256.convert(utf8.encode(rawJson)).toString();

      final backupJson = jsonEncode({
        'checksum_sha256': hash,
        'payload': payload,
      });

      final service = BackupService();
      final res = await service.restaurarDeJson(backupJson);
      expect(res.sucesso, isTrue);
    });

    test('Payload corrompido deve falhar na validação do checksum', () async {
      final payload = {
        'app': 'SindicoEvaristoLucchese',
        'versao_esquema': 1,
        'gerado_em': DateTime.now().toIso8601String(),
        'unidades': [],
        'competencias': [],
      };

      final backupJson = jsonEncode({
        'checksum_sha256': 'hash_invalido_1234567890',
        'payload': payload,
      });

      final service = BackupService();
      final res = await service.restaurarDeJson(backupJson);
      expect(res.sucesso, isFalse);
      expect(res.mensagem, contains('Falha de integridade'));
    });
  });
}
