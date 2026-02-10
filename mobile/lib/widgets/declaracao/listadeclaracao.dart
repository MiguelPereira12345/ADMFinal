import 'package:flutter/material.dart';

class ListaDeclaracao extends StatelessWidget {
	const ListaDeclaracao({super.key});

	Widget _buildItem(BuildContext context, String dayMonth, String title, String subtitle) {
		final primaryGreen = const Color(0xFF2E8B57);
		return Container(
			margin: const EdgeInsets.only(bottom: 12),
			padding: const EdgeInsets.all(12),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(12),
				boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.03), blurRadius: 6, offset: const Offset(0, 3))],
			),
			child: Row(
				children: [
					Container(
						width: 56,
						height: 56,
						decoration: BoxDecoration(
							color: const Color(0xFFF5F3F2),
							borderRadius: BorderRadius.circular(10),
						),
						child: Center(
							child: Text(
								dayMonth,
								textAlign: TextAlign.center,
								style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
							),
						),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
								const SizedBox(height: 6),
								Text(subtitle, style: const TextStyle(color: Colors.black54)),
							],
						),
					),
					const SizedBox(width: 8),
					ElevatedButton.icon(
						onPressed: () {

							// implementar download do PDF
							ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A descarregar PDF...')));
						},
						icon: const Icon(Icons.download_rounded, size: 18),
						label: const Text('Descarregar\nPDF', textAlign: TextAlign.center),
						style: ElevatedButton.styleFrom(
							backgroundColor: primaryGreen,
							padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
							shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
							textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
						),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {


		// substituir por dados reais quando disponíveis
		final items = List.generate(6, (_) => {
			'date': '28\nOUT\n2024',
			'title': 'Médico',
			'subtitle': 'Dra. Sofia Lima\n·Higiene Oral'
		});

		return Column(
			children: items.map((it) => _buildItem(context, it['date']!, it['title']!, it['subtitle']!)).toList(),
		);
	}
}
