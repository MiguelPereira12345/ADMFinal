import 'package:flutter/material.dart';
import 'widgets/declaracao/listadeclaracao.dart';
import 'widgets/app/app_scaffold.dart';
import 'widgets/app/app_colors.dart';

class Declaracao extends StatefulWidget {
  const Declaracao({super.key});

  @override
  State<Declaracao> createState() => _Declaracao();
}

class _Declaracao extends State<Declaracao> {
  @override
  Widget build(BuildContext context) {
    final cardBg = Colors.white;
    return AppScaffold(
      title: 'Declaração de Presenças',
      leading: AppLeading.close,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.02),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Comprovativos de Consulta\nVeja e descarregue as suas declarações em pdf',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Mês Atual',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8),
                  SizedBox(height: 8),

                  // Lista de declarações
                  ListaDeclaracao(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
