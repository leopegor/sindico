import 'package:sqflite/sqflite.dart';
import '../../domain/models/competencia.dart';
import 'app_database.dart';

/// Repositório de acesso a dados para Competências Mensais.
class CompetenciaRepository {
  Future<Database> get _db async => await AppDatabase.instance;

  /// Retorna todas as competências registradas ordenadas pela data decrescente
  Future<List<Competencia>> getTodas() async {
    final db = await _db;
    final maps = await db.query(
      'competencias',
      orderBy: 'ano_referencia DESC, data_vencimento DESC, id DESC',
    );
    return maps.map((m) => Competencia.fromMap(m)).toList();
  }

  /// Retorna uma competência pelo ID
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
  Future<int> inserir(Competencia competencia) async {
    _validar(competencia);
    final db = await _db;
    return await db.insert('competencias', competencia.toMap());
  }

  /// Atualiza uma competência existente
  Future<int> atualizar(Competencia competencia) async {
    if (competencia.id == null) {
      throw ArgumentError('Competência precisa de um ID para ser atualizada.');
    }
    _validar(competencia);
    final db = await _db;
    return await db.update(
      'competencias',
      competencia.toMap(),
      where: 'id = ?',
      whereArgs: [competencia.id],
    );
  }

  /// Exclui uma competência pelo ID
  Future<int> excluir(int id) async {
    final db = await _db;
    return await db.delete(
      'competencias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Regras de validação estritas antes de persistir no banco
  void _validar(Competencia comp) {
    if (comp.mesReferencia.trim().isEmpty) {
      throw ArgumentError('O mês de referência é obrigatório.');
    }
    if (comp.nomeSindico.trim().isEmpty) {
      throw ArgumentError('O nome do(a) síndico(a) é obrigatório.');
    }
    if (comp.aptoSindico.trim().isEmpty) {
      throw ArgumentError('O apartamento do síndico / local de pagamento é obrigatório.');
    }
    if (comp.valorContaAgua < 0) {
      throw ArgumentError('O valor da conta de água não pode ser negativo.');
    }
    if (comp.valorEsgotoTotal < 0) {
      throw ArgumentError('O valor total do esgoto não pode ser negativo.');
    }
    if (comp.taxaMinimaAgua < 0) {
      throw ArgumentError('A taxa mínima de água não pode ser negativa.');
    }
    if (comp.valorContaEnergia < 0) {
      throw ArgumentError('O valor da conta de energia não pode ser negativo.');
    }
    if (comp.servicosLimpeza < 0) {
      throw ArgumentError('O valor dos serviços de limpeza não pode ser negativo.');
    }
    if (comp.fundoManutencaoMensal < 0) {
      throw ArgumentError('O fundo de manutenção não pode ser negativo.');
    }
  }
}
