# 📱 Arquitetura Offline-First - CliniMolelos

**Guia Completo de Implementação e Utilização**

---

## 📖 Índice

1. [🚀 Quick Start (5 minutos)](#-quick-start)
2. [🎯 Objetivo e Conceitos](#-objetivo-e-conceitos)
3. [🏗️ Arquitetura](#️-arquitetura)
4. [📁 Estrutura de Ficheiros](#-estrutura-de-ficheiros)
5. [🔧 Componentes Principais](#-componentes-principais)
6. [⚡ Como Usar](#-como-usar)
7. [📊 Fluxos de Dados](#-fluxos-de-dados)
8. [🎨 Diagramas Visuais](#-diagramas-visuais)
9. [✅ Checklist de Implementação](#-checklist-de-implementação)
10. [🧪 Testing](#-testing)
11. [🐛 Troubleshooting](#-troubleshooting)
12. [🚀 Próximos Passos](#-próximos-passos)

---

## 🚀 Quick Start

### Ficheiros Criados

```
mobile/
├── lib/
│   ├── database/
│   │   └── database_helper.dart              ✅ ATUALIZADO
│   ├── services/
│   │   └── network_service.dart              🆕 CRIADO
│   ├── models/
│   │   └── consulta.dart                     🆕 CRIADO
│   ├── repositories/
│   │   └── consultas_repository.dart         🆕 CRIADO
│   ├── pages/
│   │   └── consultas_page_exemplo.dart       🆕 CRIADO (exemplo)
│   ├── main_exemplo_offline_first.dart       🆕 CRIADO (exemplo)
│   └── GUIA_RAPIDO_OUTRAS_ENTIDADES.dart     🆕 CRIADO (template)
└── test/
    └── repositories/
        └── consultas_repository_test.dart    🆕 CRIADO (exemplo)
```

### Exemplo Rápido de Uso

```dart
// 1️⃣ Setup no main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final db = DatabaseHelper();
  final network = NetworkService();
  final api = PatientApi(apiClient);
  
  final consultasRepo = ConsultasRepository(
    api: api,
    database: db,
    network: network,
  );
  
  runApp(MyApp(consultasRepo: consultasRepo));
}

// 2️⃣ Usar no Widget
class ConsultasPage extends StatefulWidget {
  final ConsultasRepository repository;
  final int userId;
  
  @override
  State<ConsultasPage> createState() => _ConsultasPageState();
}

class _ConsultasPageState extends State<ConsultasPage> {
  List<Consulta> consultas = [];
  
  @override
  void initState() {
    super.initState();
    loadConsultas();
  }
  
  Future<void> loadConsultas() async {
    // 🎯 Repository decide tudo automaticamente!
    final data = await widget.repository.getConsultas(widget.userId);
    setState(() => consultas = data);
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: consultas.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(consultas[i].nomeMedico ?? ''),
        subtitle: Text(consultas[i].dataHora.toString()),
      ),
    );
  }
}
```

---

## 🎯 Objetivo e Conceitos

### Objetivo Principal

Implementar uma estratégia **offline-first** onde:
- ✅ Se houver internet → busca da **API REST** e guarda no **SQLite**
- ✅ Se não houver internet → busca do **SQLite** (cache local)
- ✅ O **UI não sabe** de onde vêm os dados (abstração completa)
- ✅ Fallback automático se API falhar

### Conceitos Chave

#### 1. Repository decide: API ou Cache?

```dart
Future<List<Consulta>> getConsultas(int userId) async {
  if (network.isConnected) {
    // ONLINE: API → Cache → Return
    final response = await api.listConsultas(userId);
    final consultas = parse(response);
    await saveToCache(consultas);
    return consultas;
  } else {
    // OFFLINE: Cache → Return
    return getFromCache(userId);
  }
}
```

#### 2. UI não sabe a origem dos dados

```dart
// UI simplesmente chama:
final consultas = await repository.getConsultas(userId);

// Não sabe se veio da API ou SQLite!
// Não precisa saber! 🎉
```

#### 3. Fallback automático em erro

```dart
try {
  return await api.listConsultas(userId);
} catch (e) {
  // API falhou → fallback para cache
  return getFromCache(userId);
}
```

### Vantagens

| Vantagem | Descrição |
|----------|-----------|
| **Desacoplamento** | UI não conhece fonte de dados (API ou SQLite) |
| **Testabilidade** | Fácil mockar Repository nos testes |
| **Resiliência** | App funciona mesmo offline |
| **Performance** | Cache local = respostas instantâneas |
| **Escalabilidade** | Mesmo padrão para outras entidades |
| **UX Superior** | Sem "telas brancas" ou erros de rede |

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         UI LAYER                             │
│  (ConsultasPage, outros widgets)                            │
│  → Não sabe se dados vêm da API ou SQLite!                 │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    │ repository.getConsultas(userId)
                    ↓
┌─────────────────────────────────────────────────────────────┐
│                   REPOSITORY LAYER                           │
│  (ConsultasRepository)                                       │
│  → Decide: API (online) ou SQLite (offline)                │
│  → Abstrai fonte de dados                                   │
└───────┬──────────────────────────────────┬──────────────────┘
        │                                  │
        │ isConnected?                     │
        ↓                                  ↓
┌───────────────┐                  ┌──────────────────┐
│ NetworkService│                  │  DatabaseHelper  │
│ (connectivity)│                  │  (SQLite cache)  │
└───────┬───────┘                  └────────┬─────────┘
        │                                   │
        │ YES → API                         │ NO → SQLite
        ↓                                   ↓
┌───────────────┐                  ┌──────────────────┐
│   PatientApi  │                  │   SQLite Tables  │
│  (REST calls) │                  │   (local cache)  │
└───────────────┘                  └──────────────────┘
```

**Fluxo Offline-First:**

```
USER solicita dados
        ↓
Repository verifica: isConnected?
        ↓
   ┌────┴────┐
   │         │
ONLINE    OFFLINE
   │         │
   ↓         ↓
  API      Cache
   │         │
   ↓         │
Cache ←──────┘
   │
   ↓
  UI
```

---

## 📁 Estrutura de Ficheiros

### Componentes de Produção

```
lib/
├── database/
│   └── database_helper.dart          # ✅ Cache SQLite (atualizado)
│       ├── Tables: utilizadores, consultas, documentos
│       ├── planos_tratamento, dados_pessoais, notificacoes
│       └── Métodos CRUD + limparCache()
│
├── services/
│   └── network_service.dart          # 🆕 Verifica conectividade
│       ├── isConnected: bool
│       ├── onConnectivityChanged: Stream<bool>
│       └── checkConnectivity(): Future<void>
│
├── models/
│   └── consulta.dart                 # 🆕 Modelo de dados
│       ├── fromJson() - Parse da API
│       ├── fromSqlite() - Parse do SQLite
│       └── toSqlite() - Converter para Map
│
├── repositories/
│   └── consultas_repository.dart     # 🆕 Lógica offline-first
│       ├── getConsultas()
│       ├── getConsulta()
│       ├── marcarConsulta()
│       ├── cancelarConsulta()
│       ├── refreshConsultas()
│       └── limparCache()
│
└── pages/
    └── [suas páginas usam os repositories]
```

### Ficheiros de Exemplo/Documentação

```
lib/
├── pages/
│   └── consultas_page_exemplo.dart   # 🆕 Exemplo de UI (comentado)
│       └── Badge online/offline, pull-refresh, auto-sync
│
├── main_exemplo_offline_first.dart   # 🆕 Setup completo (comentado)
│   └── Exemplo de inicialização
│
└── GUIA_RAPIDO_OUTRAS_ENTIDADES.dart # 🆕 Templates (comentado)
    └── Exemplos: Documentos, Planos

test/
└── repositories/
    └── consultas_repository_test.dart # 🆕 Testes exemplo (comentado)
        └── Testes com mockito (requer dependências)
```

> ⚠️ **Nota:** Ficheiros de exemplo estão comentados para evitar erros de compilação. Descomente conforme necessário.

---

## 🔧 Componentes Principais

### 1️⃣ NetworkService (`services/network_service.dart`)

**Responsabilidade:** Verificar conectividade de internet

```dart
final networkService = NetworkService();

// Verificar se está online
bool isOnline = networkService.isConnected;

// Escutar mudanças na conectividade
networkService.onConnectivityChanged.listen((isConnected) {
  print('Estado da conexão: $isConnected');
});

// Forçar verificação
await networkService.checkConnectivity();
```

**Implementação:**
- Singleton pattern
- Usa `connectivity_plus` package
- Stream para notificar mudanças
- Auto-inicializa na primeira chamada

---

### 2️⃣ DatabaseHelper (`database/database_helper.dart`)

**Responsabilidade:** Gerir cache local SQLite

**Tabelas:**
- `utilizadores` - Cache de usuários
- `consultas` - Cache de consultas ⭐
- `documentos` - Cache de documentos
- `planos_tratamento` - Cache de planos
- `dados_pessoais` - Cache de dados pessoais
- `notificacoes` - Notificações locais

**Métodos principais:**
```dart
final db = DatabaseHelper();

// Consultas
await db.insertConsulta(consultaMap);
final consultas = await db.getConsultas(userId);
final consulta = await db.getConsulta(consultaId);
await db.deleteConsulta(consultaId);

// Limpeza
await db.limparCache(userId);
await db.limparTudo();
```

**Características:**
- Singleton pattern
- Schema versioning para futuras migrations
- Campo `ultima_sincronizacao` em cada tabela
- ConflictAlgorithm.replace para evitar duplicados

---

### 3️⃣ Consulta Model (`models/consulta.dart`)

**Responsabilidade:** Representar dados de consulta de forma type-safe

```dart
final consulta = Consulta(
  idConsulta: 123,
  idUtilizador: 1,
  dataHora: DateTime.now(),
  nomeMedico: 'Dr. Silva',
  tipoConsulta: 'Rotina',
);

// Converter de/para JSON (API)
final consultaFromApi = Consulta.fromJson(jsonData);

// Converter de/para Map (SQLite)
final consultaFromDb = Consulta.fromSqlite(dbMap);
final mapToSave = consulta.toSqlite();
```

**Factory Methods:**
- `fromJson()` - Parse da resposta da API
- `fromSqlite()` - Parse do Map do SQLite
- `toSqlite()` - Converter para Map para guardar

---

### 4️⃣ ConsultasRepository (`repositories/consultas_repository.dart`) ⭐

**Responsabilidade:** Implementar lógica offline-first

#### Fluxo Offline-First:

```dart
Future<List<Consulta>> getConsultas(int userId) async {
  // 1. Verifica conectividade
  if (networkService.isConnected) {
    // 2. ONLINE: Busca da API
    try {
      final response = await api.listConsultas(userId);
      final consultas = parseConsultas(response);
      
      // 3. Guarda no SQLite (cache)
      await saveToCache(consultas);
      
      return consultas; // ✅ Dados frescos da API
    } catch (e) {
      // API falhou → fallback para cache
      return getFromCache(userId);
    }
  } else {
    // 4. OFFLINE: Busca do SQLite
    return getFromCache(userId);
  }
}
```

#### Métodos disponíveis:

```dart
final repository = ConsultasRepository(
  api: patientApi,
  database: databaseHelper,
  network: networkService,
);

// Obter todas consultas (offline-first automático)
final consultas = await repository.getConsultas(userId);

// Obter consulta específica
final consulta = await repository.getConsulta(userId, consultaId);

// Marcar nova consulta
final novaConsulta = await repository.marcarConsulta(userId, {
  'data_hora': '2026-03-15T10:00:00',
  'tipo_consulta': 'Rotina',
  'motivo_consulta': 'Check-up',
});

// Refresh forçado (pull-to-refresh)
final consultas = await repository.refreshConsultas(userId);

// Limpar cache
await repository.limparCache(userId);
```

---

## ⚡ Como Usar

### Setup Inicial (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar componentes
  final databaseHelper = DatabaseHelper();
  final networkService = NetworkService();
  
  // 2. Inicializar API
  final tokenStore = /* sua implementação */;
  final apiClient = ApiClient(
    baseUrl: 'https://api.clinimolelos.com',
    tokenStore: tokenStore,
  );
  final patientApi = PatientApi(apiClient);
  
  // 3. Criar Repository
  final consultasRepository = ConsultasRepository(
    api: patientApi,
    database: databaseHelper,
    network: networkService,
  );
  
  // 4. Passar para a app
  runApp(MyApp(consultasRepository: consultasRepository));
}
```

### Opção com Provider

```dart
// pubspec.yaml: provider: ^6.1.2

MultiProvider(
  providers: [
    Provider(create: (_) => DatabaseHelper()),
    Provider(create: (_) => NetworkService()),
    Provider(create: (_) => PatientApi(apiClient)),
    ProxyProvider3<PatientApi, DatabaseHelper, NetworkService, ConsultasRepository>(
      update: (_, api, db, network, __) => ConsultasRepository(
        api: api,
        database: db,
        network: network,
      ),
    ),
  ],
  child: MyApp(),
)

// No widget:
final repository = context.read<ConsultasRepository>();
```

### No Widget/Página

```dart
class ConsultasPage extends StatefulWidget {
  final ConsultasRepository repository;
  final int userId;
  
  const ConsultasPage({
    Key? key,
    required this.repository,
    required this.userId,
  }) : super(key: key);
  
  @override
  State<ConsultasPage> createState() => _ConsultasPageState();
}

class _ConsultasPageState extends State<ConsultasPage> {
  List<Consulta> consultas = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    loadConsultas();
    monitorNetwork();
  }
  
  Future<void> loadConsultas() async {
    setState(() => isLoading = true);
    
    // 🎯 Chamada simples - repository decide tudo!
    final data = await widget.repository.getConsultas(widget.userId);
    
    setState(() {
      consultas = data;
      isLoading = false;
    });
  }
  
  void monitorNetwork() {
    NetworkService().onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        // Internet voltou - sincronizar
        loadConsultas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Dados sincronizados')),
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consultas'),
        actions: [
          // Badge Online/Offline
          Chip(
            label: Text(
              NetworkService().isConnected ? 'Online' : 'Offline',
            ),
            backgroundColor: NetworkService().isConnected 
                ? Colors.green 
                : Colors.orange,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadConsultas,
              child: ListView.builder(
                itemCount: consultas.length,
                itemBuilder: (context, index) {
                  final consulta = consultas[index];
                  return ListTile(
                    title: Text(consulta.nomeMedico ?? 'Sem médico'),
                    subtitle: Text(
                      '${consulta.dataHora.day}/${consulta.dataHora.month}/${consulta.dataHora.year}',
                    ),
                    trailing: Text(consulta.tipoConsulta ?? ''),
                  );
                },
              ),
            ),
    );
  }
}
```

---

## 📊 Fluxos de Dados

### Cenário 1: Usuário Online

```
1. User abre app
2. Repository detecta: ONLINE
3. Busca da API (/patients/{id}/consultas)
4. Guarda no SQLite
5. Retorna dados para UI
6. UI mostra badge "Online" ✅
```

### Cenário 2: Usuário Offline

```
1. User abre app (sem internet)
2. Repository detecta: OFFLINE
3. Busca do SQLite (cache local)
4. Retorna dados para UI
5. UI mostra badge "Offline" ⚠️
6. Dados podem estar desatualizados
```

### Cenário 3: Internet Restaurada

```
1. Conexão volta
2. NetworkService notifica mudança
3. UI escuta evento
4. Chama repository.refreshConsultas()
5. Dados sincronizados automaticamente
6. UI atualiza com dados frescos ✅
```

### Cenário 4: API Falha (timeout/erro 500)

```
1. Repository tenta API
2. API falha (timeout, 500, etc)
3. Repository faz fallback → SQLite
4. Retorna dados em cache
5. UI continua funcional ✅
```

---

## 🎨 Diagramas Visuais

### Fluxo 1: Buscar Consultas (Online)

```
USER
 │
 ↓
UI: ConsultasPage
 │  repository.getConsultas(1)
 ↓
Repository
 │  Verifica: isConnected? → TRUE
 ↓
API: PatientApi
 │  GET /patients/1/consultas
 │  Retorna: { consultas: [...] }
 ↓
Repository
 │  Parse JSON → List<Consulta>
 │  db.insertConsulta(...) para cada
 ↓
Database (SQLite)
 │  INSERT INTO consultas
 │  Cache atualizado ✅
 ↓
Repository
 │  Retorna: List<Consulta>
 ↓
UI
 │  setState(() => consultas = data)
 │  Mostra lista ✅
```

### Fluxo 2: Buscar Consultas (Offline)

```
USER
 │
 ↓
UI: ConsultasPage
 │  repository.getConsultas(1)
 ↓
Repository
 │  Verifica: isConnected? → FALSE
 ↓
Database (SQLite)
 │  SELECT * FROM consultas
 │  WHERE id_utilizador = 1
 ↓
Repository
 │  Parse Map → List<Consulta>
 │  Retorna: List<Consulta>
 ↓
UI
 │  setState(() => consultas = data)
 │  Mostra badge "Offline" ⚠️
 │  Mostra dados do cache ✅
```

### Tabela de Decisão: API vs Cache

| Cenário | Conectado? | Ação | Fonte |
|---------|------------|------|-------|
| Load inicial | ✅ SIM | Buscar API → Guardar Cache | **API** |
| Load inicial | ❌ NÃO | Buscar Cache | **Cache** |
| Refresh manual | ✅ SIM | Buscar API → Atualizar Cache | **API** |
| Refresh manual | ❌ NÃO | Buscar Cache (dados antigos) | **Cache** |
| API falha | ✅ SIM | Fallback → Buscar Cache | **Cache** |
| Criar/Editar | ✅ SIM | Enviar API → Guardar Cache | **API** |
| Criar/Editar | ❌ NÃO | Guardar localmente (sync depois) | **Cache** |

---

## ✅ Checklist de Implementação

### 📦 1. Dependências (pubspec.yaml)

- [x] `sqflite: ^2.3.0` - Base de dados SQLite
- [x] `connectivity_plus: ^6.0.5` - Verificar conectividade
- [x] `path_provider: ^2.1.3` - Diretório da app

**Status:** ✅ Já instaladas no projeto

---

### 🗄️ 2. Database Helper

- [x] `database_helper.dart` criado em `lib/database/`
- [x] Tabela `consultas` com campo `ultima_sincronizacao`
- [x] Métodos CRUD para consultas
- [x] Método `limparCache(userId)`
- [x] Método `limparTudo()`

**Testes:**
```bash
flutter run
# Verificar logs: "[SQLite] Base de dados criada"
```

---

### 🌐 3. Network Service

- [x] `network_service.dart` criado em `lib/services/`
- [x] Singleton pattern implementado
- [x] Propriedade `isConnected` (bool)
- [x] Stream `onConnectivityChanged` (Stream<bool>)
- [x] Método `checkConnectivity()` (refresh manual)

**Testes:**
```dart
final network = NetworkService();
print('Online: ${network.isConnected}');

network.onConnectivityChanged.listen((isConnected) {
  print('Estado mudou: $isConnected');
});
```

---

### 📝 4. Modelos de Dados

- [x] Ficheiro `consulta.dart` em `lib/models/`
- [x] Método `fromJson()` - parse da API
- [x] Método `fromSqlite()` - parse do SQLite
- [x] Método `toSqlite()` - converter para Map

**Próximos modelos (seguir mesmo padrão):**
- [ ] `documento.dart`
- [ ] `plano_tratamento.dart`
- [ ] `dados_pessoais.dart`

---

### 🏗️ 5. Repository - Consultas

- [x] `consultas_repository.dart` em `lib/repositories/`
- [x] Construtor recebe: `api`, `database`, `network`
- [x] Método `getConsultas(userId)` - lista completa
- [x] Método `getConsulta(userId, consultaId)` - específica
- [x] Método `marcarConsulta(userId, dados)` - criar nova
- [x] Método `cancelarConsulta(userId, consultaId)` - deletar
- [x] Método `refreshConsultas(userId)` - forçar refresh
- [x] Método `limparCache(userId)` - limpar dados
- [x] Lógica offline-first: API → Cache ou Cache only
- [x] Try-catch com fallback para cache quando API falha

**Próximos repositories:**
- [ ] `documentos_repository.dart`
- [ ] `planos_repository.dart`
- [ ] `perfil_repository.dart`

---

### 🎨 6. UI/Páginas

- [x] Exemplo criado: `consultas_page_exemplo.dart` (comentado)
- [ ] Aplicar padrão nas páginas reais

**Features recomendadas:**
- [ ] Badge Online/Offline no AppBar
- [ ] Pull-to-refresh com `RefreshIndicator`
- [ ] Loading state (CircularProgressIndicator)
- [ ] Empty state (sem dados)
- [ ] Escutar mudanças de conectividade
- [ ] Auto-sync quando internet voltar

---

### 🔧 7. Configuração no Main

- [x] Exemplo criado: `main_exemplo_offline_first.dart` (comentado)
- [ ] Copiar setup para o `main.dart` real
- [ ] Inicializar `DatabaseHelper` no `main()`
- [ ] Inicializar `NetworkService` no `main()`
- [ ] Criar repositories com dependências
- [ ] Passar repositories para widgets

---

### 🧪 8. Testes

- [x] Ficheiro de exemplo: `consultas_repository_test.dart` (comentado)
- [ ] Adicionar `mockito` ao `dev_dependencies`
- [ ] Adicionar `build_runner` ao `dev_dependencies`
- [ ] Gerar mocks: `flutter pub run build_runner build`
- [ ] Testar cenário ONLINE → API
- [ ] Testar cenário OFFLINE → Cache
- [ ] Testar fallback (API falha → Cache)

**Comandos:**
```bash
# Instalar dependências
flutter pub add dev:mockito dev:build_runner

# Gerar mocks
flutter pub run build_runner build

# Executar testes
flutter test
```

---

### 📱 9. Validação Manual

#### Teste 1: App com Internet
1. [ ] Abrir app com WiFi ligado
2. [ ] Ver badge "Online"
3. [ ] Verificar logs: `ONLINE - Buscando da API`
4. [ ] Verificar logs: `X consultas guardadas no cache`

#### Teste 2: App sem Internet
1. [ ] Ativar modo avião
2. [ ] Fechar e reabrir app
3. [ ] Ver badge "Offline"
4. [ ] Verificar logs: `OFFLINE - Buscando do cache`
5. [ ] Dados devem aparecer (do cache)

#### Teste 3: Internet Restaurada
1. [ ] Com app aberto em modo offline
2. [ ] Desativar modo avião
3. [ ] Badge deve mudar: "Offline" → "Online"
4. [ ] App deve auto-sincronizar

#### Teste 4: API Falha
1. [ ] Desligar servidor backend
2. [ ] Com Internet, tentar carregar dados
3. [ ] Verificar logs: `Erro na API - Usando cache`
4. [ ] App deve mostrar dados do cache

---

## 🧪 Testing

### Exemplo de Teste Unitário

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([PatientApi, DatabaseHelper, NetworkService])
import 'consultas_repository_test.mocks.dart';

void main() {
  test('getConsultas retorna da API quando online', () async {
    // Arrange
    final mockApi = MockPatientApi();
    final mockDb = MockDatabaseHelper();
    final mockNetwork = MockNetworkService();
    
    when(mockNetwork.isConnected).thenReturn(true);
    when(mockApi.listConsultas(1)).thenAnswer((_) async => {
      'consultas': [{'id': 123, 'nome_medico': 'Dr. Silva'}]
    });
    
    final repository = ConsultasRepository(
      api: mockApi,
      database: mockDb,
      network: mockNetwork,
    );
    
    // Act
    final consultas = await repository.getConsultas(1);
    
    // Assert
    expect(consultas.length, 1);
    expect(consultas[0].nomeMedico, 'Dr. Silva');
    verify(mockDb.insertConsulta(any)).called(1);
  });
  
  test('getConsultas retorna do cache quando offline', () async {
    // Arrange
    final mockApi = MockPatientApi();
    final mockDb = MockDatabaseHelper();
    final mockNetwork = MockNetworkService();
    
    when(mockNetwork.isConnected).thenReturn(false);
    when(mockDb.getConsultas(1)).thenAnswer((_) async => [
      {'id_consulta': 123, 'nome_medico': 'Dr. Silva'}
    ]);
    
    final repository = ConsultasRepository(
      api: mockApi,
      database: mockDb,
      network: mockNetwork,
    );
    
    // Act
    final consultas = await repository.getConsultas(1);
    
    // Assert
    expect(consultas.length, 1);
    expect(consultas[0].nomeMedico, 'Dr. Silva');
    verifyNever(mockApi.listConsultas(any));
  });
}
```

---

## 🐛 Troubleshooting

### Problema: "Database is locked"
**Solução:** Fechar conexões antigas antes de abrir novas
```dart
await DatabaseHelper().fecharBaseDados();
```

### Problema: "Table doesn't exist"
**Solução:** Incrementar versão da DB e fazer migration
```dart
version: 2,  // era 1
onUpgrade: (db, oldVersion, newVersion) {
  if (oldVersion < 2) {
    // Criar nova tabela ou coluna
  }
}
```

### Problema: Cache nunca atualiza
**Solução:** Verificar `ConflictAlgorithm.replace` no insert
```dart
await db.insert('consultas', data, 
  conflictAlgorithm: ConflictAlgorithm.replace
);
```

### Problema: Repository retorna dados vazios
**Solução:** Verificar parsing JSON → Consulta.fromJson()
```dart
debugPrint('API Response: $response');
debugPrint('Parsed consultas: ${consultas.length}');
```

### Problema: UI não atualiza quando internet volta
**Solução:** Verificar se está a escutar o stream
```dart
networkService.onConnectivityChanged.listen((isConnected) {
  if (isConnected) {
    _loadConsultas(); // Refresh
  }
});
```

### Problema: Dados não atualizam
**Solução:** Verificar se `ultima_sincronizacao` está a ser atualizado  
**Debug:** Adicionar `debugPrint` no repository e no DatabaseHelper

### Problema: App crashou offline
**Solução:** Garantir que todos os `await` da API têm try-catch  
**Debug:** Verificar logs `[ConsultasRepo]`

---

## 🚀 Próximos Passos

### 1. Aplicar em Outras Entidades

Ver ficheiro `lib/GUIA_RAPIDO_OUTRAS_ENTIDADES.dart` (comentado) para templates de:
- **Documentos** - Upload/download de ficheiros
- **Planos de Tratamento** - Gestão de planos
- **Perfil** - Dados pessoais

**Template genérico:**

```dart
// 1. Criar modelo
class Documento {
  factory Documento.fromJson(Map<String, dynamic> json) => ...
  factory Documento.fromSqlite(Map<String, dynamic> map) => ...
  Map<String, dynamic> toSqlite() => ...
}

// 2. Criar repository
class DocumentosRepository {
  Future<List<Documento>> getDocumentos(int userId) async {
    if (_network.isConnected) {
      final response = await _api.listDocumentos(userId);
      await saveToCache(response);
      return parse(response);
    } else {
      return getFromCache(userId);
    }
  }
}

// 3. Usar no UI
final documentos = await documentosRepo.getDocumentos(userId);
```

### 2. Sincronização Bidirecional

- [ ] Guardar ações offline (criar, editar, deletar)
- [ ] Sincronizar quando voltar online
- [ ] Resolver conflitos (última escrita ganha)

### 3. Estratégias de Cache

- [ ] TTL (Time To Live) para invalidar cache antigo
- [ ] `ultima_sincronizacao` para refresh inteligente
- [ ] Limpar cache automaticamente após X dias

### 4. Otimizações de Performance

- [ ] Paginação (carregar 20 itens de cada vez)
- [ ] Lazy loading com scroll infinito
- [ ] Comprimir JSON antes de guardar
- [ ] Índices nas tabelas SQLite

### 5. Features de UX

- [ ] Skeleton screens durante loading
- [ ] Animações de transição (online ↔ offline)
- [ ] Toast notifications para sync
- [ ] Indicador de "X itens pendentes"

### 6. Background Sync

- [ ] Implementar `SyncService`
- [ ] Usar `WorkManager` para sync em background
- [ ] Queue de operações pendentes

---

## 📚 Recursos

- [sqflite - Pub.dev](https://pub.dev/packages/sqflite)
- [connectivity_plus - Pub.dev](https://pub.dev/packages/connectivity_plus)
- [Repository Pattern in Flutter](https://developer.android.com/topic/architecture/data-layer)

---

## 💡 Dicas Finais

⚠️ **Sempre usar Repository** - Nunca chamar API diretamente no UI  
⚠️ **Cache é rei** - Se API falha, fallback para cache  
⚠️ **Debug prints** - Ajudam a entender fluxo de dados  
⚠️ **Testar offline** - Modo avião é seu amigo  
⚠️ **Consistency** - Mesmo padrão para todas entidades  

---

## 📞 Suporte

Para dúvidas sobre a implementação:

1. Ler esta documentação completa
2. Ver exemplos de código (ficheiros comentados)
3. Verificar diagramas de fluxo acima
4. Consultar checklist de implementação

---

**Desenvolvido para:** CliniMolelos  
**Data:** 2026-02-10  
**Versão:** 1.0  
**Arquitetura:** Offline-First com Repository Pattern

---

**Happy Coding! 🚀**
