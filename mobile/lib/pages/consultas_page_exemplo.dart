import 'package:flutter/material.dart';
import '../models/consulta.dart';
import '../repositories/consultas_repository.dart';
import '../services/network_service.dart';

/// Exemplo de Página de Consultas com Offline-First
/// 
/// Esta página demonstra como usar o ConsultasRepository.
/// O UI não sabe se os dados vêm da API ou do SQLite!
class ConsultasPage extends StatefulWidget {
  final int userId;
  final ConsultasRepository repository;

  const ConsultasPage({
    Key? key,
    required this.userId,
    required this.repository,
  }) : super(key: key);

  @override
  State<ConsultasPage> createState() => _ConsultasPageState();
}

class _ConsultasPageState extends State<ConsultasPage> {
  final NetworkService _networkService = NetworkService();
  
  List<Consulta> _consultas = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadConsultas();
    _monitorarConexao();
  }

  /// Carrega as consultas usando o Repository
  /// O Repository decide automaticamente se busca da API ou SQLite
  Future<void> _loadConsultas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🎯 PONTO CHAVE: Chamada simples ao repository
      // O repository decide: API (se online) ou SQLite (se offline)
      final consultas = await widget.repository.getConsultas(widget.userId);
      
      setState(() {
        _consultas = consultas;
        _isLoading = false;
      });
      
      print('[UI] ${consultas.length} consultas carregadas');
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar consultas: $e';
        _isLoading = false;
      });
      
      print('[UI] Erro: $e');
    }
  }

  /// Monitora mudanças na conectividade para atualizar o badge de status
  void _monitorarConexao() {
    _isOnline = _networkService.isConnected;
    
    // Escuta mudanças na conectividade
    _networkService.onConnectivityChanged.listen((isConnected) {
      setState(() {
        _isOnline = isConnected;
      });
      
      // Quando voltar a ter internet, sincroniza automaticamente
      if (isConnected) {
        print('[UI] Internet restaurada - Sincronizando...');
        _loadConsultas();
      }
    });
  }

  /// Pull-to-refresh: força atualização dos dados
  Future<void> _onRefresh() async {
    try {
      final consultas = await widget.repository.refreshConsultas(widget.userId);
      
      setState(() {
        _consultas = consultas;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Consultas atualizadas')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Consultas'),
        actions: [
          // Badge de status: Online/Offline
          _buildStatusBadge(),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para marcar consulta
          // Navigator.push(...);
        },
        child: const Icon(Icons.add),
        tooltip: 'Marcar Consulta',
      ),
    );
  }

  /// Badge que mostra se está online ou offline
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConsultas,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_consultas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Sem consultas agendadas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _isOnline
                  ? 'Marque uma consulta clicando no botão +'
                  : 'Dados offline - Conecte-se para sincronizar',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consultas.length,
      itemBuilder: (context, index) {
        final consulta = _consultas[index];
        return _buildConsultaCard(consulta);
      },
    );
  }

  Widget _buildConsultaCard(Consulta consulta) {
    // Formatar data
    final dataFormatada = '${consulta.dataHora.day}/${consulta.dataHora.month}/${consulta.dataHora.year}';
    final horaFormatada = '${consulta.dataHora.hour.toString().padLeft(2, '0')}:${consulta.dataHora.minute.toString().padLeft(2, '0')}';

    // Indicador de sincronização
    final bool precisaSincronizar = consulta.estadoConsulta == 'pendente_sync';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEstadoColor(consulta.estadoConsulta),
          child: const Icon(Icons.medical_services, color: Colors.white),
        ),
        title: Text(
          consulta.nomeMedico ?? 'Médico não definido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('📅 $dataFormatada às $horaFormatada'),
            if (consulta.tipoConsulta != null)
              Text('🏥 ${consulta.tipoConsulta}'),
            if (consulta.motivoConsulta != null)
              Text('📝 ${consulta.motivoConsulta}'),
            
            // Badge de sincronização pendente
            if (precisaSincronizar)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠ Aguardando sincronização',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
          ],
        ),
        trailing: Icon(
          _getEstadoIcon(consulta.estadoConsulta),
          color: _getEstadoColor(consulta.estadoConsulta),
        ),
        onTap: () {
          // Navegar para detalhes da consulta
          // Navigator.push(...);
        },
      ),
    );
  }

  Color _getEstadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'confirmada':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      case 'concluida':
        return Colors.blue;
      case 'pendente_sync':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'confirmada':
        return Icons.check_circle;
      case 'pendente':
        return Icons.hourglass_empty;
      case 'cancelada':
        return Icons.cancel;
      case 'concluida':
        return Icons.done_all;
      case 'pendente_sync':
        return Icons.sync;
      default:
        return Icons.help;
    }
  }
}
