import 'package:flutter/material.dart';
import '../../utils/app_formatters.dart';

class DependentsTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onView;
  const DependentsTable({super.key, required this.items, required this.onView});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Data nascimento')),
          DataColumn(label: Text('Sexo')),
          DataColumn(label: Text('Ações')),
        ],
        rows: items
            .map((item) {
              final nome =
                  firstString(item, ['nome', 'name', 'paciente_nome']) ??
                  'Dependente';
              final dataNasc = formatDate(
                firstString(item, [
                  'data_nascimento',
                  'dataNascimento',
                  'birth_date',
                  'dob',
                ]),
              );
              final sexo = firstString(item, ['sexo', 'gender']);

              return DataRow(
                cells: [
                  DataCell(Text(nome)),
                  DataCell(Text(displayString(dataNasc))),
                  DataCell(Text(displayString(sexo))),
                  DataCell(
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
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
                    ),
                  ),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
