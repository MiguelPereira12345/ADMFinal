import 'package:flutter/material.dart';

class RequestConsultaCard extends StatelessWidget {
  final Widget child;
  const RequestConsultaCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
