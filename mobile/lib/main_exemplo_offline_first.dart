// ignore_for_file: type=lint
// ignore_for_file: unused_import, unreachable_from_main, unrelated_type_equality_checks, abstract_class_member
/// ⚠️ FICHEIRO DE EXEMPLO - NÃO EXECUTAR DIRETAMENTE
/// 
/// Este ficheiro serve apenas como referência de como configurar
/// a arquitetura offline-first. Copie o código necessário para
/// o seu main.dart real e adapte conforme necessário.

import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'api/patient_api.dart';
import 'api/token_store.dart';
import 'database/database_helper.dart';
import 'services/network_service.dart';
import 'repositories/consultas_repository.dart';
import 'pages/consultas_page_exemplo.dart';

/// EXEMPLO DE SETUP OFFLINE-FIRST
/// 
/// Este ficheiro mostra como inicializar todos os componentes
/// necessários para a arquitetura offline-first.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar Database Helper (SQLite)
  final databaseHelper = DatabaseHelper();
  await databaseHelper.database; // Força inicialização
  print('✓ DatabaseHelper inicializado');
  
  // 2. Inicializar Network Service
  // final networkService = NetworkService();
  // print('✓ NetworkService inicializado');
  
  // 3. Inicializar API Client
  // final tokenStore = TokenStore(); // ⚠️ Implementar conforme sua autenticação (classe abstrata)
  /*
  final apiClient = ApiClient(
    baseUrl: 'https://api.clinimolelos.com', // Substituir pela sua URL
    tokenStore: tokenStore,
  );
  final patientApi = PatientApi(apiClient);
  print('✓ API Client inicializado');
  
  // 4. Criar Repository (Offline-First)
  final consultasRepository = ConsultasRepository(
    api: patientApi,
    database: databaseHelper,
    network: networkService,
  );
  print('✓ ConsultasRepository criado');
  
  runApp(MyApp(
    consultasRepository: consultasRepository,
  ));
  */
  
  // ⚠️ CÓDIGO COMENTADO - Exemplo de inicialização
  // Descomente e implemente TokenStore() antes de usar
  print('⚠️ Este é um ficheiro de exemplo. Implemente TokenStore() primeiro.');
}

class MyApp extends StatelessWidget {
  final ConsultasRepository consultasRepository;
  
  const MyApp({
    Key? key,
    required this.consultasRepository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CliniMolelos - Offline-First',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      // Passar repository para as páginas que precisam
      routes: {
        '/consultas': (context) => ConsultasPage(
          userId: 1, // Substituir pelo ID real do usuário logado
          repository: consultasRepository,
        ),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CliniMolelos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Offline-First Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/consultas');
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Ver Minhas Consultas'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// EXEMPLOS DE USO EM OUTROS WIDGETS
// ========================================

/// Exemplo 1: Usar o Repository num StatefulWidget
class ExemploUsageWidget extends StatefulWidget {
  final ConsultasRepository repository;
  final int userId;
  
  const ExemploUsageWidget({
    Key? key,
    required this.repository,
    required this.userId,
  }) : super(key: key);

  @override
  State<ExemploUsageWidget> createState() => _ExemploUsageWidgetState();
}

class _ExemploUsageWidgetState extends State<ExemploUsageWidget> {
  
  /// Buscar consultas (automático offline-first)
  Future<void> buscarConsultas() async {
    final consultas = await widget.repository.getConsultas(widget.userId);
    print('Obtidas ${consultas.length} consultas');
    // UI não sabe se veio da API ou SQLite!
  }
  
  /// Buscar uma consulta específica
  Future<void> buscarConsultaDetalhes(int consultaId) async {
    final consulta = await widget.repository.getConsulta(widget.userId, consultaId);
    if (consulta != null) {
      print('Consulta: ${consulta.nomeMedico} em ${consulta.dataHora}');
    }
  }
  
  /// Marcar nova consulta
  Future<void> marcarConsulta() async {
    try {
      final novaConsulta = await widget.repository.marcarConsulta(
        widget.userId,
        {
          'data_hora': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'tipo_consulta': 'Consulta de Rotina',
          'motivo_consulta': 'Check-up anual',
        },
      );
      
      print('✓ Consulta marcada: ${novaConsulta.idConsulta}');
      
      // Nota: Se offline, a consulta será guardada localmente
      // e sincronizada quando tiver internet
      
    } catch (e) {
      print('✗ Erro ao marcar consulta: $e');
    }
  }
  
  /// Refresh forçado (pull-to-refresh)
  Future<void> atualizarConsultas() async {
    final consultas = await widget.repository.refreshConsultas(widget.userId);
    print('✓ Consultas atualizadas: ${consultas.length}');
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(); // Implementação do UI
  }
}

/// Exemplo 2: Usar com Provider/Riverpod
/// 
/// Se estiver usando Provider ou Riverpod, pode injetar o repository:
/// 
/// ```dart
/// final consultasRepositoryProvider = Provider<ConsultasRepository>((ref) {
///   return ConsultasRepository(
///     api: ref.read(patientApiProvider),
///     database: ref.read(databaseHelperProvider),
///     network: ref.read(networkServiceProvider),
///   );
/// });
/// 
/// // No widget:
/// final repository = ref.read(consultasRepositoryProvider);
/// final consultas = await repository.getConsultas(userId);
/// ```
