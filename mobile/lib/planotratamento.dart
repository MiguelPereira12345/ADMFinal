import 'package:flutter/material.dart';

import 'app/session_scope.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app/app_error_view.dart';
import 'plano_tratamento_detalhes_page.dart';
import 'widgets/planos/plan_card.dart';

class PlanoTratamentoPage extends StatefulWidget {
  const PlanoTratamentoPage({super.key});

  @override
  State<PlanoTratamentoPage> createState() => _PlanoTratamentoPageState();
}

class _PlanoTratamentoPageState extends State<PlanoTratamentoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bg = const Color(0xFFFAF7F4);
  final cardBg = Colors.white;
  final primaryGold = const Color(0xFFA87B05);
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final session = SessionScope.of(context);
    final userId = session.userId;
    if (userId == null) throw Exception('Sessão inválida.');
    return session.patientApi.listPlanos(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Planos de Tratamento',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Veja os planos ativos e o histórico.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black12, width: 1),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: primaryGold,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: primaryGold,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Ativos'),
                        Tab(text: 'Histórico'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(width: 12),
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 12),
                        Text(
                          'Pesquisar planos...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AppErrorView(
                      error: snapshot.error,
                      onRetry: () => setState(() => _future = _load()),
                    );
                  }

                  final json = snapshot.data ?? <String, dynamic>{};
                  final planos = _extractList(json);
                  final activeList =
                      planos.where((p) => _matchesFilter(p, true)).toList();
                  final historyList =
                      planos.where((p) => _matchesFilter(p, false)).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(activeList),
                      _buildList(historyList),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> planos) {
    if (planos.isEmpty) {
      return const Center(
        child: Text(
          'Sem planos para apresentar.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: planos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = planos[index];
        return PlanCard(
          plan: p,
          primaryGold: primaryGold,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanoTratamentoDetalhesPage(plan: p),
              ),
            );
          },
        );
      },
    );
  }

  static List<Map<String, dynamic>> _extractList(Map<String, dynamic> json) {
    final candidates = [json['planos'], json['data'], json['items']];
    for (final c in candidates) {
      if (c is List) {
        return c
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }

  static bool _matchesFilter(Map<String, dynamic> plan, bool showActive) {
    final status = (plan['status'] ?? plan['estado'] ?? '')
        .toString()
        .toLowerCase();
    final ativo = plan['ativo'];
    final isActive = (ativo is bool)
        ? ativo
        : !(status.contains('concl') ||
              status.contains('final') ||
              status.contains('inativ'));
    return showActive ? isActive : !isActive;
  }
}

