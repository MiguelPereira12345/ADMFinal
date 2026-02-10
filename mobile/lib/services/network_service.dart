import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// NetworkService - Serviço para verificar conectividade de rede
/// 
/// Utiliza connectivity_plus para monitorizar o estado da conexão de internet.
/// Implementa padrão Singleton para uso global na aplicação.
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  
  NetworkService._internal() {
    _initConnectivity();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Estado atual da conectividade
  bool _isConnected = false;
  
  // Stream para notificar mudanças de conectividade
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  /// Stream que emite true/false quando a conectividade muda
  Stream<bool> get onConnectivityChanged => _connectionController.stream;
  
  /// Verifica se há conexão de internet neste momento
  bool get isConnected => _isConnected;

  /// Inicializa o monitoramento de conectividade
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      
      // Escuta mudanças na conectividade
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _updateConnectionStatus(results);
        },
      );
    } catch (e) {
      debugPrint('[NetworkService] Erro ao inicializar conectividade: $e');
      _isConnected = false;
    }
  }

  /// Atualiza o estado da conexão baseado nos resultados do connectivity_plus
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    
    // Considera conectado se tiver qualquer tipo de conexão (WiFi, Mobile, Ethernet)
    _isConnected = results.any((result) => 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );
    
    // Notifica listeners apenas se o estado mudou
    if (wasConnected != _isConnected) {
      debugPrint('[NetworkService] Conectividade mudou: $_isConnected');
      _connectionController.add(_isConnected);
    }
  }

  /// Verifica conectividade de forma assíncrona (útil para refresh manual)
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isConnected;
    } catch (e) {
      debugPrint('[NetworkService] Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Libera recursos quando não for mais necessário
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}
