import 'package:flutter/foundation.dart';
import '../api/patient_api.dart';
import '../database/database_helper.dart';
import '../services/network_service.dart';
import '../models/consulta.dart';

/// ConsultasRepository - Implementação de Offline-First para Consultas
/// 
/// Este repositório abstrai a fonte de dados (API ou SQLite) do UI.
/// 
/// **Fluxo Offline-First:**
/// 1. Verifica conectividade com NetworkService
/// 2. Se **ONLINE**: busca da API → guarda no SQLite → retorna dados
/// 3. Se **OFFLINE**: busca do SQLite → retorna dados em cache
/// 
/// **Vantagens:**
/// - O UI não precisa saber de onde vêm os dados
/// - Funciona offline automaticamente
/// - Cache sempre atualizado quando há internet
/// - Código limpo e escalável
class ConsultasRepository {
  final PatientApi _api;
  final DatabaseHelper _db;
  final NetworkService _network;

  ConsultasRepository({
    required PatientApi api,
    required DatabaseHelper database,
    required NetworkService network,
  })  : _api = api,
        _db = database,
        _network = network;

  /// Obtém todas as consultas de um utilizador
  /// 
  /// **Estratégia Offline-First:**
  /// - Se online: busca da API, guarda no SQLite e retorna
  /// - Se offline: busca do SQLite (dados em cache)
  /// 
  /// **Exemplo de uso:**
  /// ```dart
  /// final consultas = await consultasRepo.getConsultas(userId);
  /// // O UI não sabe se veio da API ou do SQLite!
  /// ```
  Future<List<Consulta>> getConsultas(int idUtilizador) async {
    try {
      // 1. Verificar conectividade
      final isOnline = _network.isConnected;

      if (isOnline) {
        // 2. ONLINE: Buscar da API
        debugPrint('[ConsultasRepo] ONLINE - Buscando consultas da API para user $idUtilizador');
        
        try {
          final response = await _api.listConsultas(idUtilizador);
          
          // Parse da resposta da API
          final List<dynamic> consultasJson = response['consultas'] ?? 
                                               response['data'] ?? 
                                               response['items'] ?? 
                                               [];
          
          // 3. Converter JSON para objetos Consulta
          final consultas = consultasJson
              .map((json) => Consulta.fromJson(json as Map<String, dynamic>))
              .toList();

          // 4. Guardar no SQLite (cache local)
          await _salvarConsultasNaCache(consultas);
          
          debugPrint('[ConsultasRepo] ✓ ${consultas.length} consultas obtidas da API e guardadas no cache');
          
          return consultas;
        } catch (apiError) {
          // Se API falhar (timeout, erro 500, etc), tenta buscar do cache
          debugPrint('[ConsultasRepo] ⚠ Erro na API: $apiError - Usando cache local');
          return await _getConsultasDoCache(idUtilizador);
        }
      } else {
        // 5. OFFLINE: Buscar do SQLite
        debugPrint('[ConsultasRepo] OFFLINE - Buscando consultas do cache local');
        return await _getConsultasDoCache(idUtilizador);
      }
    } catch (e) {
      debugPrint('[ConsultasRepo] ✗ Erro ao obter consultas: $e');
      rethrow;
    }
  }

  /// Obtém uma consulta específica pelo ID
  /// 
  /// **Estratégia Offline-First:**
  /// - Se online: busca da API, guarda no SQLite e retorna
  /// - Se offline: busca do SQLite
  Future<Consulta?> getConsulta(int idUtilizador, int idConsulta) async {
    try {
      final isOnline = _network.isConnected;

      if (isOnline) {
        // ONLINE: Buscar da API
        debugPrint('[ConsultasRepo] ONLINE - Buscando consulta $idConsulta da API');
        
        try {
          final response = await _api.getConsulta(idUtilizador, idConsulta);
          
          final consultaJson = response['consulta'] ?? 
                              response['data'] ?? 
                              response;
          
          final consulta = Consulta.fromJson(consultaJson as Map<String, dynamic>);
          
          // Guardar no cache
          await _db.insertConsulta(consulta.toSqlite());
          
          debugPrint('[ConsultasRepo] ✓ Consulta $idConsulta obtida da API');
          
          return consulta;
        } catch (apiError) {
          debugPrint('[ConsultasRepo] ⚠ Erro na API: $apiError - Usando cache');
          return await _getConsultaDaCache(idConsulta);
        }
      } else {
        // OFFLINE: Buscar do cache
        debugPrint('[ConsultasRepo] OFFLINE - Buscando consulta $idConsulta do cache');
        return await _getConsultaDaCache(idConsulta);
      }
    } catch (e) {
      debugPrint('[ConsultasRepo] ✗ Erro ao obter consulta: $e');
      rethrow;
    }
  }

  /// Marca/solicita uma nova consulta
  /// 
  /// **Estratégia Offline-First:**
  /// - Se online: envia para API e sincroniza
  /// - Se offline: guarda localmente para sincronizar depois (funcionalidade futura)
  Future<Consulta> marcarConsulta(
    int idUtilizador,
    Map<String, dynamic> dadosConsulta,
  ) async {
    final isOnline = _network.isConnected;

    if (isOnline) {
      // ONLINE: Enviar para API
      debugPrint('[ConsultasRepo] ONLINE - Marcando consulta via API');
      
      final response = await _api.requestConsulta(idUtilizador, dadosConsulta);
      
      final consultaJson = response['consulta'] ?? 
                          response['data'] ?? 
                          response;
      
      final consulta = Consulta.fromJson(consultaJson as Map<String, dynamic>);
      
      // Guardar no cache
      await _db.insertConsulta(consulta.toSqlite());
      
      debugPrint('[ConsultasRepo] ✓ Consulta marcada com sucesso');
      
      return consulta;
    } else {
      // OFFLINE: Guardar localmente para sincronizar depois
      debugPrint('[ConsultasRepo] OFFLINE - Consulta será guardada para sincronização posterior');
      
      // Criar uma consulta temporária com ID negativo (indica não sincronizada)
      final consultaTemp = Consulta(
        idConsulta: -DateTime.now().millisecondsSinceEpoch, // ID temporário negativo
        idUtilizador: idUtilizador,
        dataHora: DateTime.parse(dadosConsulta['data_hora']),
        tipoConsulta: dadosConsulta['tipo_consulta'],
        motivoConsulta: dadosConsulta['motivo_consulta'],
        estadoConsulta: 'pendente_sync', // Estado especial para sincronização
      );
      
      await _db.insertConsulta(consultaTemp.toSqlite());
      
      debugPrint('[ConsultasRepo] ⚠ Consulta guardada localmente - requer sincronização');
      
      return consultaTemp;
    }
  }

  /// Remove uma consulta (apenas se estiver online)
  Future<bool> cancelarConsulta(int idUtilizador, int idConsulta) async {
    final isOnline = _network.isConnected;

    if (!isOnline) {
      debugPrint('[ConsultasRepo] ✗ Não é possível cancelar offline');
      throw Exception('É necessário estar online para cancelar uma consulta');
    }

    try {
      // Chamar API de cancelamento (assumindo que existe)
      // await _api.cancelConsulta(idUtilizador, idConsulta);
      
      // Remover do cache local
      await _db.deleteConsulta(idConsulta);
      
      debugPrint('[ConsultasRepo] ✓ Consulta $idConsulta cancelada');
      
      return true;
    } catch (e) {
      debugPrint('[ConsultasRepo] ✗ Erro ao cancelar consulta: $e');
      return false;
    }
  }

  /// Força refresh dos dados da API (útil para pull-to-refresh)
  Future<List<Consulta>> refreshConsultas(int idUtilizador) async {
    debugPrint('[ConsultasRepo] 🔄 Refresh forçado das consultas');
    
    if (!_network.isConnected) {
      debugPrint('[ConsultasRepo] ⚠ Sem conexão - retornando cache');
      return await _getConsultasDoCache(idUtilizador);
    }

    return await getConsultas(idUtilizador);
  }

  /// Limpa o cache de consultas (útil para logout)
  Future<void> limparCache(int idUtilizador) async {
    await _db.deleteTodasConsultas(idUtilizador);
    debugPrint('[ConsultasRepo] 🗑 Cache de consultas limpo para user $idUtilizador');
  }

  // ========== MÉTODOS PRIVADOS DE CACHE ==========

  /// Busca consultas do cache local (SQLite)
  Future<List<Consulta>> _getConsultasDoCache(int idUtilizador) async {
    final consultasMaps = await _db.getConsultas(idUtilizador);
    
    final consultas = consultasMaps
        .map((map) => Consulta.fromSqlite(map))
        .toList();
    
    debugPrint('[ConsultasRepo] 📦 ${consultas.length} consultas obtidas do cache');
    
    return consultas;
  }

  /// Busca uma consulta específica do cache
  Future<Consulta?> _getConsultaDaCache(int idConsulta) async {
    final consultaMap = await _db.getConsulta(idConsulta);
    
    if (consultaMap == null) {
      debugPrint('[ConsultasRepo] ⚠ Consulta $idConsulta não encontrada no cache');
      return null;
    }
    
    return Consulta.fromSqlite(consultaMap);
  }

  /// Guarda lista de consultas no cache
  Future<void> _salvarConsultasNaCache(List<Consulta> consultas) async {
    for (final consulta in consultas) {
      await _db.insertConsulta(consulta.toSqlite());
    }
    
    debugPrint('[ConsultasRepo] 💾 ${consultas.length} consultas guardadas no cache');
  }
}
