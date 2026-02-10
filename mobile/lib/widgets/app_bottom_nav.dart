import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int? selectedIndex;

  const AppBottomNav({super.key, this.selectedIndex});

  void _navigate(BuildContext context, int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/menu');
    if (index == 1) Navigator.pushReplacementNamed(context, '/asminhasconsultas');
    if (index == 2) Navigator.pushReplacementNamed(context, '/plano_tratamento');
    if (index == 3) Navigator.pushReplacementNamed(context, '/perfil');
  }

  int _indexFromRoute(BuildContext context) {
    final name = ModalRoute.of(context)?.settings.name ?? '';
    switch (name) {
      case '/menu':
        return 0;
      case '/asminhasconsultas':
        return 1;
      case '/plano_tratamento':
        return 2;
      case '/perfil':
        return 3;
      default:
        return selectedIndex ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGold = const Color(0xFFA87B05);
    final current = _indexFromRoute(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0x0F000000), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navItem(context, icon: Icons.home_outlined, label: 'Início', index: 0, primaryGold: primaryGold, isSelected: current == 0),
              _navItem(context, icon: Icons.calendar_month_outlined, label: 'Consultas', index: 1, primaryGold: primaryGold, isSelected: current == 1),
              _navItem(context, icon: Icons.folder_open_outlined, label: 'Planos', index: 2, primaryGold: primaryGold, isSelected: current == 2),
              _navItem(context, icon: Icons.person_outline, label: 'Perfil', index: 3, primaryGold: primaryGold, isSelected: current == 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required int index, required Color primaryGold, required bool isSelected}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigate(context, index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF3EDE7) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: isSelected ? primaryGold : Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? primaryGold : Colors.black54)),
          ],
        ),
      ),
    );
  }
}
