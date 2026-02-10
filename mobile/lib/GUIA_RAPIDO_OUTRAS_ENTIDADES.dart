// ignore_for_file: type=lint
// ignore_for_file: directives_ordering, unused_import, unreachable_from_main, unused_element, unused_local_variable, undefined_class, undefined_identifier
/// ⚠️ FICHEIRO DE DOCUMENTAÇÃO - EXEMPLOS DE CÓDIGO
/// 
/// Este ficheiro contém exemplos e templates de código para referência.
/// Não é para ser executado diretamente. Copie os padrões necessários
/// para os seus próprios ficheiros.
///
/// GUIA RÁPIDO - Como Adicionar Offline-First a Novas Entidades
///
/// Este ficheiro mostra como replicar a estratégia offline-first
/// para outras entidades (Documentos, Planos, etc)

// =============================================================================
// PASSO 1: Criar o Modelo de Dados
// =============================================================================

class Documento {
  final int idDocumento;
  final int idUtilizador;
  final String nomeDocumento;
  final String? tipoDocumento;
  final String? caminhoFicheiro;
  final DateTime? dataUpload;

  Documento({
    required this.idDocumento,
    required this.idUtilizador,
    required this.nomeDocumento,
    this.tipoDocumento,
    this.caminhoFicheiro,
    this.dataUpload,
  });

  // Converter de JSON da API
  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      idDocumento: json['id'] ?? json['id_documento'] ?? 0,
      idUtilizador: json['id_utilizador'] ?? 0,
      nomeDocumento: json['nome_documento'] ?? json['nome'] ?? '',
      tipoDocumento: json['tipo_documento']?.toString(),
      caminhoFicheiro: json['caminho_ficheiro'],
      dataUpload: json['data_upload'] != null 
          ? DateTime.tryParse(json['data_upload']) 
          : null,
    );
  }

  // Converter de Map do SQLite
  factory Documento.fromSqlite(Map<String, dynamic> map) {
    return Documento(
      idDocumento: map['id_documento'] ?? 0,
      idUtilizador: map['id_utilizador'] ?? 0,
      nomeDocumento: map['nome_documento'] ?? '',
      tipoDocumento: map['tipo_documento'],
      caminhoFicheiro: map['caminho_ficheiro'],
      dataUpload: map['data_upload'] != null 
          ? DateTime.tryParse(map['data_upload']) 
          : null,
    );
  }

  // Converter para Map do SQLite
  Map<String, dynamic> toSqlite() {
    return {
      'id_documento': idDocumento,
      'id_utilizador': idUtilizador,
      'nome_documento': nomeDocumento,
      'tipo_documento': tipoDocumento,
      'caminho_ficheiro': caminhoFicheiro,
      'data_upload': dataUpload?.toIso8601String(),
    };
  }
}

/*
// =============================================================================
// PASSO 2: Criar o Repository
// =============================================================================

// ⚠️ CÓDIGO COMENTADO - Este exemplo requer implementação da FilesApi
// Descomente e adapte conforme necessário

import 'package:flutter/foundation.dart';
import '../api/files_api.dart'; // Sua API de documentos
import '../database/database_helper.dart';
import '../services/network_service.dart';

class DocumentosRepository {
  final FilesApi _api;
  final DatabaseHelper _db;
  final NetworkService _network;

  DocumentosRepository({
    required FilesApi api,
    required DatabaseHelper database,
    required NetworkService network,
  })  : _api = api,
        _db = database,
        _network = network;

  /// Obter todos documentos (offline-first)
  Future<List<Documento>> getDocumentos(int idUtilizador, {int? tipoDocumento}) async {
    try {
      final isOnline = _network.isConnected;

      if (isOnline) {
        // ONLINE: Buscar da API
        debugPrint('[DocumentosRepo] ONLINE - Buscando da API');
        
        try {
          // Assumindo que sua API retorna algo como:
          // { "documentos": [...] } ou { "data": [...] }
          final response = await _api.listDocumentos(idUtilizador, tipoDocumento: tipoDocumento);
          
          final List<dynamic> documentosJson = response['documentos'] ?? 
                                                response['data'] ?? 
                                                [];
          
          final documentos = documentosJson
              .map((json) => Documento.fromJson(json as Map<String, dynamic>))
              .toList();

          // Guardar no cache
          for (final doc in documentos) {
            await _db.insertDocumento(doc.toSqlite());
          }
          
          debugPrint('[DocumentosRepo] ✓ ${documentos.length} documentos da API');
          return documentos;
          
        } catch (apiError) {
          debugPrint('[DocumentosRepo] ⚠ Erro API: $apiError - Usando cache');
          return await _getDocumentosDoCache(idUtilizador, tipoDocumento);
        }
      } else {
        // OFFLINE: Buscar do cache
        debugPrint('[DocumentosRepo] OFFLINE - Buscando do cache');
        return await _getDocumentosDoCache(idUtilizador, tipoDocumento);
      }
    } catch (e) {
      debugPrint('[DocumentosRepo] ✗ Erro: $e');
      rethrow;
    }
  }

  /// Upload de novo documento
  Future<Documento> uploadDocumento(
    int idUtilizador,
    String filePath,
    Map<String, dynamic> metadata,
  ) async {
    final isOnline = _network.isConnected;

    if (!isOnline) {
      throw Exception('Upload requer conexão de internet');
    }

    try {
      // Upload via API
      final response = await _api.uploadDocumento(idUtilizador, filePath, metadata);
      
      final documento = Documento.fromJson(response['documento'] ?? response['data'] ?? response);
      
      // Guardar no cache
      await _db.insertDocumento(documento.toSqlite());
      
      debugPrint('[DocumentosRepo] ✓ Documento ${documento.idDocumento} uploaded');
      return documento;
      
    } catch (e) {
      debugPrint('[DocumentosRepo] ✗ Erro upload: $e');
      rethrow;
    }
  }

  /// Download de documento
  Future<String> downloadDocumento(int idUtilizador, int idDocumento) async {
    final isOnline = _network.isConnected;

    if (!isOnline) {
      throw Exception('Download requer conexão de internet');
    }

    try {
      final localPath = await _api.downloadDocumento(idUtilizador, idDocumento);
      
      // Atualizar caminho local no cache
      await _db.insertDocumento({
        'id_documento': idDocumento,
        'id_utilizador': idUtilizador,
        'caminho_ficheiro': localPath,
      });
      
      return localPath;
      
    } catch (e) {
      debugPrint('[DocumentosRepo] ✗ Erro download: $e');
      rethrow;
    }
  }

  /// Deletar documento
  Future<bool> deleteDocumento(int idUtilizador, int idDocumento) async {
    final isOnline = _network.isConnected;

    if (!isOnline) {
      throw Exception('Eliminar documento requer internet');
    }

    try {
      await _api.deleteDocumento(idUtilizador, idDocumento);
      await _db.deleteDocumento(idDocumento);
      
      debugPrint('[DocumentosRepo] ✓ Documento $idDocumento eliminado');
      return true;
      
    } catch (e) {
      debugPrint('[DocumentosRepo] ✗ Erro delete: $e');
      return false;
    }
  }

  // MÉTODOS PRIVADOS DE CACHE

  Future<List<Documento>> _getDocumentosDoCache(int idUtilizador, int? tipoDocumento) async {
    final documentosMaps = await _db.getDocumentos(idUtilizador, tipoDocumento: tipoDocumento);
    
    return documentosMaps
        .map((map) => Documento.fromSqlite(map))
        .toList();
  }
}
*/

// =============================================================================
// PASSO 3: Usar no UI
// =============================================================================

/*
// ⚠️ CÓDIGO COMENTADO - Exemplo de UI
// Descomente e adapte conforme necessário

import 'package:flutter/material.dart';

class DocumentosPage extends StatefulWidget {
  final int userId;
  final DocumentosRepository repository;

  const DocumentosPage({
    Key? key,
    required this.userId,
    required this.repository,
  }) : super(key: key);

  @override
  State<DocumentosPage> createState() => _DocumentosPageState();
}

class _DocumentosPageState extends State<DocumentosPage> {
  List<Documento> _documentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
  }

  Future<void> _loadDocumentos() async {
    setState(() => _isLoading = true);

    try {
      // 🎯 Chamada simples - repository decide tudo!
      final documentos = await widget.repository.getDocumentos(widget.userId);
      
      setState(() {
        _documentos = documentos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _uploadDocumento(String filePath) async {
    try {
      final documento = await widget.repository.uploadDocumento(
        widget.userId,
        filePath,
        {
          'nome_documento': 'Novo Documento',
          'tipo_documento': 1, // Ex: declaração médica
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Documento ${documento.idDocumento} uploaded')),
      );

      _loadDocumentos(); // Refresh lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✗ Erro upload: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _documentos.length,
      itemBuilder: (context, index) {
        final doc = _documentos[index];
        return ListTile(
          leading: const Icon(Icons.description),
          title: Text(doc.nomeDocumento),
          subtitle: Text(doc.tipoDocumento ?? 'Sem tipo'),
          trailing: IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final path = await widget.repository.downloadDocumento(
                  widget.userId,
                  doc.idDocumento,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Download: $path')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✗ Erro: $e')),
                );
              }
            },
          ),
        );
      },
    );
  }
}
*/

// =============================================================================
// RESUMO: Template Rápido para Novas Entidades
// =============================================================================

/*

1. CRIAR MODELO:
   - fromJson(Map<String, dynamic>) → Parse da API
   - fromSqlite(Map<String, dynamic>) → Parse do SQLite
   - toSqlite() → Map<String, dynamic> → Guardar no SQLite

2. CRIAR REPOSITORY:
   ```dart
   class [Entidade]Repository {
     final [SuaApi] _api;
     final DatabaseHelper _db;
     final NetworkService _network;
     
     Future<List<[Entidade]>> get[Entidades](int userId) async {
       if (_network.isConnected) {
         // API → cache → return
       } else {
         // cache → return
       }
     }
   }
   ```

3. USAR NO UI:
   ```dart
   final dados = await repository.get[Entidades](userId);
   // UI não sabe de onde veio!
   ```

4. REGISTAR NO MAIN:
   ```dart
   final [entidade]Repository = [Entidade]Repository(
     api: yourApi,
     database: databaseHelper,
     network: networkService,
   );
   ```

5. DONE! ✅

*/

// =============================================================================
// EXEMPLO COMPLETO: Planos de Tratamento
// =============================================================================

/*
// ⚠️ CÓDIGO COMENTADO - Exemplo completo de outra entidade
// Descomente e adapte conforme necessário

class PlanoTratamento {
  final int idPlano;
  final int idUtilizador;
  final String tituloPlano;
  final String? objetivos;
  final int? numConsultasPrevisto;
  final int? numConsultasRealizado;
  final String? estadoPlano;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  PlanoTratamento({
    required this.idPlano,
    required this.idUtilizador,
    required this.tituloPlano,
    this.objetivos,
    this.numConsultasPrevisto,
    this.numConsultasRealizado,
    this.estadoPlano,
    this.dataInicio,
    this.dataFim,
  });

  factory PlanoTratamento.fromJson(Map<String, dynamic> json) {
    return PlanoTratamento(
      idPlano: json['id'] ?? json['id_plano'] ?? 0,
      idUtilizador: json['id_utilizador'] ?? 0,
      tituloPlano: json['titulo_plano'] ?? json['titulo'] ?? '',
      objetivos: json['objetivos'],
      numConsultasPrevisto: json['num_consultas_previsto'],
      numConsultasRealizado: json['num_consultas_realizado'],
      estadoPlano: json['estado_plano'],
      dataInicio: json['data_inicio'] != null 
          ? DateTime.tryParse(json['data_inicio']) 
          : null,
      dataFim: json['data_fim'] != null 
          ? DateTime.tryParse(json['data_fim']) 
          : null,
    );
  }

  factory PlanoTratamento.fromSqlite(Map<String, dynamic> map) {
    return PlanoTratamento(
      idPlano: map['id_plano'] ?? 0,
      idUtilizador: map['id_utilizador'] ?? 0,
      tituloPlano: map['titulo_plano'] ?? '',
      objetivos: map['objetivos'],
      numConsultasPrevisto: map['num_consultas_previsto'],
      numConsultasRealizado: map['num_consultas_realizado'],
      estadoPlano: map['estado_plano'],
      dataInicio: map['data_inicio'] != null 
          ? DateTime.tryParse(map['data_inicio']) 
          : null,
      dataFim: map['data_fim'] != null 
          ? DateTime.tryParse(map['data_fim']) 
          : null,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id_plano': idPlano,
      'id_utilizador': idUtilizador,
      'titulo_plano': tituloPlano,
      'objetivos': objetivos,
      'num_consultas_previsto': numConsultasPrevisto,
      'num_consultas_realizado': numConsultasRealizado,
      'estado_plano': estadoPlano,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
    };
  }
}

class PlanosRepository {
  final PatientApi _api;
  final DatabaseHelper _db;
  final NetworkService _network;

  PlanosRepository({
    required PatientApi api,
    required DatabaseHelper database,
    required NetworkService network,
  })  : _api = api,
        _db = database,
        _network = network;

  Future<List<PlanoTratamento>> getPlanos(int idUtilizador) async {
    if (_network.isConnected) {
      try {
        final response = await _api.listPlanos(idUtilizador);
        final planosJson = response['planos'] ?? response['data'] ?? [];
        
        final planos = planosJson
            .map((json) => PlanoTratamento.fromJson(json as Map<String, dynamic>))
            .toList();

        for (final plano in planos) {
          await _db.insertPlano(plano.toSqlite());
        }
        
        return planos;
      } catch (e) {
        return await _getPlanosDoCache(idUtilizador);
      }
    } else {
      return await _getPlanosDoCache(idUtilizador);
    }
  }

  Future<List<PlanoTratamento>> _getPlanosDoCache(int idUtilizador) async {
    final planosMaps = await _db.getPlanos(idUtilizador);
    return planosMaps
        .map((map) => PlanoTratamento.fromSqlite(map))
        .toList();
  }
}

*/

// =============================================================================
// FIM DOS EXEMPLOS
// =============================================================================
// 
// ⚠️ TODO O CÓDIGO ACIMA ESTÁ COMENTADO E SERVE APENAS COMO REFERÊNCIA
// 
// Para usar estes padrões:
// 1. Copie as classes de modelo que precisa
// 2. Copie o repositório correspondente
// 3. Adapte os nomes e métodos da API conforme necessário
// 4. Crie os seus próprios ficheiros em lib/repositories/ e lib/models/

// USO:
// final planos = await planosRepository.getPlanos(userId);
// Simples assim! 🎉
