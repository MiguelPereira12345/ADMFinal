import 'package:flutter/material.dart';

/// Logo + title + subtitle widget used on the login page.
class Logotipo extends StatelessWidget {
  final String titleText;
  final TextStyle titleStyle;
  final String logoAsset;
  final String subtitle;
  final Color boxColor;

  const Logotipo({
    super.key,
    required this.titleText,
    required this.titleStyle,
    this.logoAsset = 'assets/CliniMolelos.png',
    this.subtitle = 'Aceda à sua conta',
    this.boxColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: titleText, style: titleStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final logoWidth = textPainter.width;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            width: logoWidth,
            child: Image.asset(
              logoAsset,
              width: logoWidth,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => SizedBox(
                width: logoWidth,
                height: logoWidth * 0.4,
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(titleText, style: titleStyle),
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 14)),
      ],
    );
  }
}
