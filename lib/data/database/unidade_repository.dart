import 'package:sqflite/sqflite.dart';
import '../../domain/models/unidade.dart';
import 'app_database.dart';

/// Repositório de acesso a dados para Unidades do Condomínio.
class UnidadeRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  /// Retorna todas as unidades cadastradas ordenadas por código (Loja primeiro, depois 101, 201...)
  Future<List<Unidade>> getTodas() async {
    final db = await _db;
    final maps = await db.query('unidades', orderBy: 'id ASC');
    return maps.map((m) => Unidade.fromMap(m)).toList();
  }

  /// Retorna uma unidade específica por código
  Future<Unidade?> getPorCodigo(String codigo) async {
    final db = await _db;
    final maps = await db.query(
      'unidades',
      where: 'codigo = ?',
      whereArgs: [codigo],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Unidade.fromMap(maps.first);
  }

  /// Atualiza os dados de uma unidade
  Future<int> atualizar(Unidade unidade) async {
    final db = await _db;
    return await db.update(
      'unidades',
      unidade.toMap(),
      where: 'id = ?',
      whereArgs: [unidade.id],
    );
  }

  /// Define qual unidade é ocupada pelo síndico no exercício (remove a flag das demais)
  Future<void> definirSindico(String codigoUnidade) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Remove flag de todas
      await txn.update('unidades', {'is_sindico': 0});
      // Atribui à escolhida
      await txn.update(
        'unidades',
        {'is_sindico': 1},
        where: 'codigo = ?',
        whereArgs: [codigoUnidade],
      );
    });
  }

  /// Restaura as 11 unidades para o padrão original da documentação
  Future<void> restaurarPadrao() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('unidades');
      for (final unidade in Unidade.unidadesPadrao) {
        await txn.insert('unidades', unidade.toMap());
      }
    });
  }
}
