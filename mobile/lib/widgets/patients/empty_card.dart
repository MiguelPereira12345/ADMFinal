import 'package:flutter/material.dart';
import '../app/app_card.dart';

class EmptyCard extends StatelessWidget {
  final String text;

  const EmptyCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    );
  }
}
