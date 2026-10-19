import 'package:sqflite/sqflite.dart';
import '../../domain/models/competencia.dart';
import '../../domain/services/validacao_competencia.dart';
import '../backend.dart';
import '../repositorios.dart';
import '../supabase/competencia_repositorio_supabase.dart';
import 'app_database.dart';

/// Fachada de acesso às competências.
///
/// Delega para o Supabase quando [Backend.usaSupabase] e para o SQLite local
/// caso contrário, mantendo as telas indiferentes ao backend ativo.
class CompetenciaRepository implements CompetenciaRepositorio {
  final CompetenciaRepositoryLocal _local = CompetenciaRepositoryLocal();
  final CompetenciaRepositorioSupabase _nuvem = CompetenciaRepositorioSupabase();

  @override
  Future<List<Competencia>> getTodas() =>
      Backend.usaSupabase ? _nuvem.getTodas() : _local.getTodas();

  @override
  Future<Competencia?> getPorId(int id) =>
      Backend.usaSupabase ? _nuvem.getPorId(id) : _local.getPorId(id);

  @override
  Future<Competencia?> getMaisRecente() =>
      Backend.usaSupabase ? _nuvem.getMaisRecente() : _local.getMaisRecente();

  @override
  Future<int> inserir(Competencia competencia) =>
      Backend.usaSupabase ? _nuvem.inserir(competencia) : _local.inserir(competencia);

  @override
  Future<int> atualizar(Competencia competencia) =>
      Backend.usaSupabase ? _nuvem.atualizar(competencia) : _local.atualizar(competencia);

  @override
  Future<int> excluir(int id) =>
      Backend.usaSupabase ? _nuvem.excluir(id) : _local.excluir(id);
}

/// Repositório de acesso a dados para Competências Mensais (SQLite local).
class CompetenciaRepositoryLocal implements CompetenciaRepositorio {
  Future<Database> get _db async => await AppDatabase.instance;

  /// Retorna todas as competências registradas ordenadas pela data decrescente
  @override
  Future<List<Competencia>> getTodas() async {
    final db = await _db;
    final maps = await db.query(
      'competencias',
      orderBy: 'ano_referencia DESC, data_vencimento DESC, id DESC',
    );
    return maps.map((m) => Competencia.fromMap(m)).toList();
  }

  /// Retorna uma competência pelo ID
  @override
  Future<Competencia?> getPorId(int id) async {
    final db = await _db;
    final maps = await db.query(
      'competencias',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Competencia.fromMap(maps.first);
  }

  /// Retorna a competência mais recente ou nulo
  @override
  Future<Competencia?> getMaisRecente() async {
    final db = await _db;
    final maps = await db.query(
      'competencias',
      orderBy: 'ano_referencia DESC, data_vencimento DESC, id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Competencia.fromMap(maps.first);
  }

  /// Insere uma nova competência mensal com validação prévia
  @override
  Future<int> inserir(Competencia competencia) async {
    validarCompetencia(competencia);
    final db = await _db;
    return await db.insert('competencias', competencia.toMap());
  }

  /// Atualiza uma competência existente
  @override
  Future<int> atualizar(Competencia competencia) async {
    if (competencia.id == null) {
      throw ArgumentError('Competência precisa de um ID para ser atualizada.');
    }
    validarCompetencia(competencia);
    final db = await _db;
    return await db.update(
      'competencias',
      competencia.toMap(),
      where: 'id = ?',
      whereArgs: [competencia.id],
    );
  }

  /// Exclui uma competência pelo ID
  @override
  Future<int> excluir(int id) async {
    final db = await _db;
    return await db.delete(
      'competencias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
