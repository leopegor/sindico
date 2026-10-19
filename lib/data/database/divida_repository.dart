import 'package:sqflite/sqflite.dart';
import '../../domain/models/abatimento_divida.dart';
import '../../domain/models/divida_anterior.dart';
import '../backend.dart';
import '../repositorios.dart';
import '../supabase/divida_repositorio_supabase.dart';
import 'app_database.dart';

/// Fachada de acesso a dívidas anteriores e abatimentos.
///
/// Delega para o Supabase quando [Backend.usaSupabase] e para o SQLite local
/// caso contrário, mantendo as telas indiferentes ao backend ativo.
class DividaRepository implements DividaRepositorio {
  final DividaRepositoryLocal _local = DividaRepositoryLocal();
  final DividaRepositorioSupabase _nuvem = DividaRepositorioSupabase();

  @override
  Future<Map<String, DividaAnterior>> getDividas() =>
      Backend.usaSupabase ? _nuvem.getDividas() : _local.getDividas();

  @override
  Future<void> salvarDivida(DividaAnterior divida) =>
      Backend.usaSupabase ? _nuvem.salvarDivida(divida) : _local.salvarDivida(divida);

  @override
  Future<void> removerDivida(String unidadeCodigo) => Backend.usaSupabase
      ? _nuvem.removerDivida(unidadeCodigo)
      : _local.removerDivida(unidadeCodigo);

  @override
  Future<List<AbatimentoDivida>> getAbatimentos() =>
      Backend.usaSupabase ? _nuvem.getAbatimentos() : _local.getAbatimentos();

  @override
  Future<int> inserirAbatimento(AbatimentoDivida abatimento) => Backend.usaSupabase
      ? _nuvem.inserirAbatimento(abatimento)
      : _local.inserirAbatimento(abatimento);

  @override
  Future<void> removerAbatimento(int id) =>
      Backend.usaSupabase ? _nuvem.removerAbatimento(id) : _local.removerAbatimento(id);

  @override
  Future<void> substituirDividas(List<DividaAnterior> dividas) => Backend.usaSupabase
      ? _nuvem.substituirDividas(dividas)
      : _local.substituirDividas(dividas);

  @override
  Future<void> substituirAbatimentos(List<AbatimentoDivida> abatimentos) =>
      Backend.usaSupabase
          ? _nuvem.substituirAbatimentos(abatimentos)
          : _local.substituirAbatimentos(abatimentos);
}

/// Repositório de acesso a dados para dívidas anteriores (valores manuais)
/// e abatimentos (pagamentos parciais) das unidades (SQLite local).
class DividaRepositoryLocal implements DividaRepositorio {
  Future<Database> get _db async => await AppDatabase.instance;

  // ---------- Dívida anterior (valor manual) ----------

  /// Retorna todas as dívidas anteriores manuais, indexadas pelo código da unidade.
  @override
  Future<Map<String, DividaAnterior>> getDividas() async {
    final db = await _db;
    final maps = await db.query('dividas_anteriores');
    return {
      for (final m in maps)
        (m['unidade_codigo'] as String): DividaAnterior.fromMap(m),
    };
  }

  /// Insere ou atualiza a dívida anterior manual da unidade (upsert por código).
  @override
  Future<void> salvarDivida(DividaAnterior divida) async {
    final db = await _db;
    final existente = await db.query(
      'dividas_anteriores',
      columns: ['id'],
      where: 'unidade_codigo = ?',
      whereArgs: [divida.unidadeCodigo],
      limit: 1,
    );

    if (existente.isEmpty) {
      await db.insert('dividas_anteriores', divida.toMap());
    } else {
      final id = existente.first['id'] as int;
      await db.update(
        'dividas_anteriores',
        divida.copyWith(id: id).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Remove a dívida manual (volta ao cálculo automático de meses anteriores).
  @override
  Future<void> removerDivida(String unidadeCodigo) async {
    final db = await _db;
    await db.delete(
      'dividas_anteriores',
      where: 'unidade_codigo = ?',
      whereArgs: [unidadeCodigo],
    );
  }

  // ---------- Abatimentos (pagamentos parciais) ----------

  /// Retorna todos os abatimentos registrados, ordenados da data mais recente.
  @override
  Future<List<AbatimentoDivida>> getAbatimentos() async {
    final db = await _db;
    final maps = await db.query('abatimentos_divida', orderBy: 'data DESC, id DESC');
    return maps.map((m) => AbatimentoDivida.fromMap(m)).toList();
  }

  @override
  Future<int> inserirAbatimento(AbatimentoDivida abatimento) async {
    final db = await _db;
    return await db.insert('abatimentos_divida', abatimento.toMap());
  }

  @override
  Future<void> removerAbatimento(int id) async {
    final db = await _db;
    await db.delete('abatimentos_divida', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Restauração de backup ----------

  /// Substitui todas as dívidas manuais (usado na restauração de backup).
  @override
  Future<void> substituirDividas(List<DividaAnterior> dividas) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('dividas_anteriores');
      for (final d in dividas) {
        await txn.insert('dividas_anteriores', d.toMap());
      }
    });
  }

  /// Substitui todos os abatimentos (usado na restauração de backup).
  @override
  Future<void> substituirAbatimentos(List<AbatimentoDivida> abatimentos) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('abatimentos_divida');
      for (final a in abatimentos) {
        await txn.insert('abatimentos_divida', a.toMap());
      }
    });
  }
}
