import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// DatabaseHelper - Gestão da base de dados SQLite local (Offline Cache)
/// 
/// Esta classe implementa o padrão Singleton para gerir a base de dados
/// local da aplicação CliniMolelos, permitindo funcionalidade offline-first.
/// 
/// Todas as tabelas incluem campo 'ultima_sincronizacao' para controlo de
/// sincronização com o backend.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'clinimolelos.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de utilizadores (cache local)
    await db.execute('''
      CREATE TABLE utilizadores (
        id_utilizador INTEGER PRIMARY KEY,
        nome_completo TEXT NOT NULL,
        email TEXT NOT NULL,
        tipo_utilizador INTEGER,
        ultima_sincronizacao TEXT
      )
    ''');

    // Tabela de consultas (cache local)
    await db.execute('''
      CREATE TABLE consultas (
        id_consulta INTEGER PRIMARY KEY,
        id_utilizador INTEGER,
        data_hora TEXT NOT NULL,
        duracao_minutos INTEGER,
        tipo_consulta TEXT,
        estado_consulta TEXT,
        motivo_consulta TEXT,
        sintomas TEXT,
        resultados TEXT,
        nome_medico TEXT,
        ultima_sincronizacao TEXT,
        FOREIGN KEY (id_utilizador) REFERENCES utilizadores (id_utilizador)
      )
    ''');

    // Tabela de documentos/declarações (cache local)
    await db.execute('''
      CREATE TABLE documentos (
        id_documento INTEGER PRIMARY KEY,
        id_utilizador INTEGER,
        nome_documento TEXT,
        tipo_documento INTEGER,
        caminho_ficheiro TEXT,
        data_upload TEXT,
        observacoes TEXT,
        ultima_sincronizacao TEXT,
        FOREIGN KEY (id_utilizador) REFERENCES utilizadores (id_utilizador)
      )
    ''');

    // Tabela de planos de tratamento (cache local)
    await db.execute('''
      CREATE TABLE planos_tratamento (
        id_plano INTEGER PRIMARY KEY,
        id_utilizador INTEGER,
        titulo_plano TEXT NOT NULL,
        objetivos TEXT,
        num_consultas_previsto INTEGER,
        num_consultas_realizado INTEGER,
        estado_plano TEXT,
        data_inicio TEXT,
        data_fim TEXT,
        ultima_sincronizacao TEXT,
        FOREIGN KEY (id_utilizador) REFERENCES utilizadores (id_utilizador)
      )
    ''');

    // Tabela de dados pessoais (titular/dependente)
    await db.execute('''
      CREATE TABLE dados_pessoais (
        id_utente INTEGER PRIMARY KEY,
        id_utilizador INTEGER UNIQUE,
        nome_completo TEXT,
        data_nascimento TEXT,
        genero TEXT,
        nif TEXT,
        num_sns TEXT,
        telefone TEXT,
        morada TEXT,
        estado_civil TEXT,
        profissao TEXT,
        tipo_utente INTEGER,
        ultima_sincronizacao TEXT,
        FOREIGN KEY (id_utilizador) REFERENCES utilizadores (id_utilizador)
      )
    ''');

    // Tabela de notificações locais
    await db.execute('''
      CREATE TABLE notificacoes (
        id_notificacao INTEGER PRIMARY KEY AUTOINCREMENT,
        id_utilizador INTEGER,
        titulo TEXT NOT NULL,
        mensagem TEXT NOT NULL,
        data_envio TEXT NOT NULL,
        lida INTEGER DEFAULT 0,
        tipo TEXT,
        FOREIGN KEY (id_utilizador) REFERENCES utilizadores (id_utilizador)
      )
    ''');

    print('[SQLite] Base de dados criada com sucesso');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('[SQLite] Atualização da base de dados de $oldVersion para $newVersion');
  }
  
  // ===== MÉTODOS PARA UTILIZADORES =====
  
  Future<int> insertUtilizador(Map<String, dynamic> utilizador) async {
    final db = await database;
    utilizador['ultima_sincronizacao'] = DateTime.now().toIso8601String();
    return await db.insert('utilizadores', utilizador, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUtilizador(int idUtilizador) async {
    final db = await database;
    final results = await db.query('utilizadores', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUtilizador(int idUtilizador, Map<String, dynamic> utilizador) async {
    final db = await database;
    utilizador['ultima_sincronizacao'] = DateTime.now().toIso8601String();
    return await db.update('utilizadores', utilizador, where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
  }
  
  // ===== MÉTODOS PARA CONSULTAS =====
  
  Future<int> insertConsulta(Map<String, dynamic> consulta) async {
    final db = await database;
    consulta['ultima_sincronizacao'] = DateTime.now().toIso8601String();
    return await db.insert('consultas', consulta, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getConsultas(int idUtilizador) async {
    final db = await database;
    return await db.query('consultas', where: 'id_utilizador = ?', whereArgs: [idUtilizador], orderBy: 'data_hora DESC');
  }

  Future<Map<String, dynamic>?> getConsulta(int idConsulta) async {
    final db = await database;
    final results = await db.query('consultas', where: 'id_consulta = ?', whereArgs: [idConsulta]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> deleteConsulta(int idConsulta) async {
    final db = await database;
    return await db.delete('consultas', where: 'id_consulta = ?', whereArgs: [idConsulta]);
  }

  Future<int> deleteTodasConsultas(int idUtilizador) async {
    final db = await database;
    return await db.delete('consultas', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
  }
  
  // ===== MÉTODOS PARA DOCUMENTOS =====
  
  Future<int> insertDocumento(Map<String, dynamic> documento) async {
    final db = await database;
    documento['ultima_sincronizacao'] = DateTime.now().toIso8601String();
    return await db.insert('documentos', documento, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getDocumentos(int idUtilizador, {int? tipoDocumento}) async {
    final db = await database;
    if (tipoDocumento != null) {
      return await db.query('documentos', where: 'id_utilizador = ? AND tipo_documento = ?', whereArgs: [idUtilizador, tipoDocumento]);
    }
    return await db.query('documentos', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
  }

  Future<int> deleteDocumento(int idDocumento) async {
    final db = await database;
    return await db.delete('documentos', where: 'id_documento = ?', whereArgs: [idDocumento]);
  }
  
  // ===== MÉTODOS PARA PLANOS DE TRATAMENTO =====
  
  Future<int> insertPlano(Map<String, dynamic> plano) async {
    final db = await database;
    plano['ultima_sincronizacao'] = DateTime.now().toIso8601String();
    return await db.insert('planos_tratamento', plano, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPlanos(int idUtilizador) async {
    final db = await database;
    return await db.query('planos_tratamento', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
  }
  
  // ===== MÉTODOS PARA DADOS PESSOAIS =====
  
  Future<int> insertDadosPessoais(Map<String, dynamic> dados) async {
    final db = await database;
    dados['ultima_sincronizacao'] = DateTime.now().toIso8601String();
    return await db.insert('dados_pessoais', dados, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDadosPessoais(int idUtilizador) async {
    final db = await database;
    final results = await db.query('dados_pessoais', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateDadosPessoais(int idUtilizador, Map<String, dynamic> dados) async {
    final db = await database;
    dados['ultima_sincronizacao'] = DateTime.now().toIso8601String();
    return await db.update('dados_pessoais', dados, where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
  }
  
  // ===== MÉTODOS PARA NOTIFICAÇÕES =====
  
  Future<int> insertNotificacao(Map<String, dynamic> notificacao) async {
    final db = await database;
    return await db.insert('notificacoes', notificacao);
  }

  Future<List<Map<String, dynamic>>> getNotificacoes(int idUtilizador, {bool? apenasNaoLidas}) async {
    final db = await database;
    if (apenasNaoLidas == true) {
      return await db.query('notificacoes', where: 'id_utilizador = ? AND lida = 0', whereArgs: [idUtilizador], orderBy: 'data_envio DESC');
    }
    return await db.query('notificacoes', where: 'id_utilizador = ?', whereArgs: [idUtilizador], orderBy: 'data_envio DESC');
  }

  Future<int> marcarNotificacaoComoLida(int idNotificacao) async {
    final db = await database;
    return await db.update('notificacoes', {'lida': 1}, where: 'id_notificacao = ?', whereArgs: [idNotificacao]);
  }

  Future<int> getNumeroNotificacoesNaoLidas(int idUtilizador) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notificacoes WHERE id_utilizador = ? AND lida = 0', [idUtilizador]);
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  // ===== MÉTODOS DE LIMPEZA =====
  
  Future<void> limparCache(int idUtilizador) async {
    final db = await database;
    await db.delete('consultas', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
    await db.delete('documentos', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
    await db.delete('planos_tratamento', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
    await db.delete('dados_pessoais', where: 'id_utilizador = ?', whereArgs: [idUtilizador]);
    print('[SQLite] Cache limpo para utilizador $idUtilizador');
  }

  Future<void> limparTudo() async {
    final db = await database;
    await db.delete('utilizadores');
    await db.delete('consultas');
    await db.delete('documentos');
    await db.delete('planos_tratamento');
    await db.delete('dados_pessoais');
    await db.delete('notificacoes');
    print('[SQLite] Toda a base de dados foi limpa');
  }

  Future<void> fecharBaseDados() async {
    final db = await database;
    await db.close();
    _database = null;
    print('[SQLite] Base de dados fechada');
  }
}
