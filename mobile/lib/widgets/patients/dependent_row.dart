import 'package:flutter/material.dart';
import '../../utils/app_formatters.dart';
import 'mini_field.dart';

class DependentRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic> item) onView;
  const DependentRow({super.key, required this.item, required this.onView});

  @override
  Widget build(BuildContext context) {
    final nome =
        firstString(item, ['nome', 'name', 'paciente_nome']) ?? 'Dependente';
    final dataNasc = formatDate(
      firstString(item, [
        'data_nascimento',
        'dataNascimento',
        'birth_date',
        'dob',
      ]),
    );
    final sexo = firstString(item, ['sexo', 'gender']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  MiniField(
                    label: 'Data nascimento',
                    value: displayString(dataNasc),
                  ),
                  MiniField(label: 'Sexo', value: displayString(sexo)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => onView(item),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFA87B05),
            side: const BorderSide(color: Color(0xFFA87B05)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Ver'),
        ),
      ],
    );
  }
}
