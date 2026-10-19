import 'package:sqflite/sqflite.dart';
import '../../domain/models/pagamento.dart';
import '../backend.dart';
import '../repositorios.dart';
import '../supabase/pagamento_repositorio_supabase.dart';
import 'app_database.dart';

/// Fachada de acesso aos pagamentos.
///
/// Delega para o Supabase quando [Backend.usaSupabase] e para o SQLite local
/// caso contrário, mantendo as telas indiferentes ao backend ativo.
class PagamentoRepository implements PagamentoRepositorio {
  final PagamentoRepositoryLocal _local = PagamentoRepositoryLocal();
  final PagamentoRepositorioSupabase _nuvem = PagamentoRepositorioSupabase();

  @override
  Future<Map<String, Pagamento>> getPorCompetencia(int competenciaId) =>
      Backend.usaSupabase
          ? _nuvem.getPorCompetencia(competenciaId)
          : _local.getPorCompetencia(competenciaId);

  @override
  Future<void> salvar(Pagamento pagamento) =>
      Backend.usaSupabase ? _nuvem.salvar(pagamento) : _local.salvar(pagamento);

  @override
  Future<void> remover(int competenciaId, String unidadeCodigo) =>
      Backend.usaSupabase
          ? _nuvem.remover(competenciaId, unidadeCodigo)
          : _local.remover(competenciaId, unidadeCodigo);
}

/// Repositório de acesso a dados para o controle de pagamento das unidades
/// (SQLite local).
class PagamentoRepositoryLocal implements PagamentoRepositorio {
  Future<Database> get _db async => await AppDatabase.instance;

  /// Retorna os pagamentos de uma competência, indexados pelo código da unidade.
  @override
  Future<Map<String, Pagamento>> getPorCompetencia(int competenciaId) async {
    final db = await _db;
    final maps = await db.query(
      'pagamentos',
      where: 'competencia_id = ?',
      whereArgs: [competenciaId],
    );
    return {
      for (final m in maps)
        (m['unidade_codigo'] as String): Pagamento.fromMap(m),
    };
  }

  /// Insere ou atualiza a situação de pagamento de uma unidade (upsert pelo par competência+unidade).
  @override
  Future<void> salvar(Pagamento pagamento) async {
    final db = await _db;
    final existente = await db.query(
      'pagamentos',
      columns: ['id'],
      where: 'competencia_id = ? AND unidade_codigo = ?',
      whereArgs: [pagamento.competenciaId, pagamento.unidadeCodigo],
      limit: 1,
    );

    if (existente.isEmpty) {
      await db.insert('pagamentos', pagamento.toMap());
    } else {
      final id = existente.first['id'] as int;
      await db.update(
        'pagamentos',
        pagamento.copyWith(id: id).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Remove o registro de pagamento (volta ao estado "sem lançamento").
  @override
  Future<void> remover(int competenciaId, String unidadeCodigo) async {
    final db = await _db;
    await db.delete(
      'pagamentos',
      where: 'competencia_id = ? AND unidade_codigo = ?',
      whereArgs: [competenciaId, unidadeCodigo],
    );
  }
}
