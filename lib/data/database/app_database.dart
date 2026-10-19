import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../../domain/models/unidade.dart';
import '../../domain/models/competencia.dart';

/// Gerenciador central do banco de dados local SQLite do aplicativo.
class AppDatabase {
  static const String _databaseName = 'sindico_evaristo_lucchese.db';
  static const int _databaseVersion = 4;

  static Database? _database;

  /// Inicializa a fábrica adequada: FFI web no navegador, FFI nativo em desktop.
  static void initializeFfiIfNeeded() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return;
    }
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Retorna a instância ativa do banco de dados singleton
  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Permite injetar um banco customizado (ex: in-memory em testes)
  static void setDatabaseForTesting(Database db) {
    _database = db;
  }

  static Future<Database> _initDatabase() async {
    initializeFfiIfNeeded();
    final String path;
    if (kIsWeb) {
      path = _databaseName;
    } else {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, _databaseName);
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE competencias ADD COLUMN discriminacao_outras_despesas TEXT');
      await db.execute('ALTER TABLE competencias ADD COLUMN discriminacao_fundo_manutencao TEXT');
    }
    if (oldVersion < 3) {
      await _criarTabelaPagamentos(db);
    }
    if (oldVersion < 4) {
      await _criarTabelaDividasAnteriores(db);
      await _criarTabelaAbatimentos(db);
    }
  }

  static Future<void> _criarTabelaPagamentos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pagamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        competencia_id INTEGER NOT NULL,
        unidade_codigo TEXT NOT NULL,
        pago INTEGER NOT NULL DEFAULT 0,
        data_pagamento TEXT,
        valor_pago REAL,
        UNIQUE (competencia_id, unidade_codigo)
      )
    ''');
  }

  static Future<void> _criarTabelaDividasAnteriores(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dividas_anteriores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unidade_codigo TEXT NOT NULL UNIQUE,
        valor REAL NOT NULL,
        atualizado_em TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _criarTabelaAbatimentos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS abatimentos_divida (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unidade_codigo TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        observacao TEXT,
        criado_em TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabela de Unidades
    await db.execute('''
      CREATE TABLE unidades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nome_morador TEXT NOT NULL,
        numero_pessoas INTEGER NOT NULL,
        area_privativa REAL NOT NULL,
        fracao_ideal REAL NOT NULL,
        is_sindico INTEGER NOT NULL DEFAULT 0,
        participa_policiamento INTEGER NOT NULL DEFAULT 0,
        valor_policiamento REAL NOT NULL DEFAULT 0.0,
        tipo TEXT NOT NULL
      )
    ''');

    // Tabela de Competências Mensais
    await db.execute('''
      CREATE TABLE competencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mes_referencia TEXT NOT NULL,
        ano_referencia INTEGER NOT NULL,
        data_vencimento TEXT NOT NULL,
        nome_sindico TEXT NOT NULL,
        apto_sindico TEXT NOT NULL,
        periodo_mandato TEXT,
        valor_conta_agua REAL NOT NULL,
        valor_esgoto_total REAL NOT NULL,
        taxa_minima_agua REAL NOT NULL,
        consumo_agua_m3 REAL,
        fmrh REAL DEFAULT 0.0,
        consumo_energia_kwh REAL,
        valor_conta_energia REAL NOT NULL,
        servicos_limpeza REAL NOT NULL,
        materiais_limpeza REAL DEFAULT 0.0,
        limpeza_caixas_agua REAL DEFAULT 0.0,
        discriminacao_outras_despesas TEXT,
        fundo_manutencao_mensal REAL NOT NULL,
        discriminacao_fundo_manutencao TEXT,
        valor_apolice REAL,
        numero_parcelas INTEGER,
        juros_mora_mensal REAL NOT NULL DEFAULT 0.015,
        multa_mora REAL NOT NULL DEFAULT 0.02,
        divisor_rateio_sindico INTEGER NOT NULL DEFAULT 11,
        fator_atraso REAL NOT NULL DEFAULT 0.95,
        observacoes TEXT,
        criado_em TEXT NOT NULL
      )
    ''');

    // Tabela de Controle de Pagamentos
    await _criarTabelaPagamentos(db);

    // Tabelas de dívida anterior manual e abatimentos parciais
    await _criarTabelaDividasAnteriores(db);
    await _criarTabelaAbatimentos(db);

    // Semente inicial (seed): 11 unidades históricas
    for (final unidade in Unidade.unidadesPadrao) {
      await db.insert('unidades', unidade.toMap());
    }

    // Semente inicial da competência histórica documentada (Setembro/2026)
    await db.insert('competencias', Competencia.exemploSetembro2026.toMap());
  }

  /// Fecha o banco de dados
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
