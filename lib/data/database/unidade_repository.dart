import 'package:sqflite/sqflite.dart';
import '../../domain/models/unidade.dart';
import '../backend.dart';
import '../repositorios.dart';
import '../supabase/unidade_repositorio_supabase.dart';
import 'app_database.dart';

/// Fachada de acesso às unidades.
///
/// Delega para o Supabase quando [Backend.usaSupabase] e para o SQLite local
/// caso contrário, mantendo as telas indiferentes ao backend ativo.
class UnidadeRepository implements UnidadeRepositorio {
  final UnidadeRepositoryLocal _local = UnidadeRepositoryLocal();
  final UnidadeRepositorioSupabase _nuvem = UnidadeRepositorioSupabase();

  @override
  Future<List<Unidade>> getTodas() =>
      Backend.usaSupabase ? _nuvem.getTodas() : _local.getTodas();

  @override
  Future<Unidade?> getPorCodigo(String codigo) =>
      Backend.usaSupabase ? _nuvem.getPorCodigo(codigo) : _local.getPorCodigo(codigo);

  @override
  Future<int> atualizar(Unidade unidade) =>
      Backend.usaSupabase ? _nuvem.atualizar(unidade) : _local.atualizar(unidade);

  @override
  Future<void> definirSindico(String codigoUnidade) => Backend.usaSupabase
      ? _nuvem.definirSindico(codigoUnidade)
      : _local.definirSindico(codigoUnidade);

  @override
  Future<void> restaurarPadrao() =>
      Backend.usaSupabase ? _nuvem.restaurarPadrao() : _local.restaurarPadrao();
}

/// Repositório de acesso a dados para Unidades do Condomínio (SQLite local).
class UnidadeRepositoryLocal implements UnidadeRepositorio {
  Future<Database> get _db async => await AppDatabase.instance;

  /// Retorna todas as unidades cadastradas ordenadas por código (Loja primeiro, depois 101, 201...)
  @override
  Future<List<Unidade>> getTodas() async {
    final db = await _db;
    final maps = await db.query('unidades', orderBy: 'id ASC');
    return maps.map((m) => Unidade.fromMap(m)).toList();
  }

  /// Retorna uma unidade específica por código
  @override
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
  @override
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
  @override
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
  @override
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
