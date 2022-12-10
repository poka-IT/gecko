import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/globals.dart';

class BuildText extends StatelessWidget {
  const BuildText({
    Key? key,
    required this.text,
    this.size = 20,
    this.isMd = true,
  }) : super(key: key);

  final String text;
  final double size;
  final bool isMd;

  @override
  Widget build(BuildContext context) {
    final mdStyle = MarkdownStyleSheet(
      p: TextStyle(
          fontSize: isTall ? size : size * 0.9,
          color: Colors.black,
          letterSpacing: 0.3),
      textAlign: WrapAlignment.spaceBetween,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      width: 440,
      decoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: Colors.grey[900]!)),
      child: isMd
          ? MarkdownBody(data: text, styleSheet: mdStyle)
          : Text(text,
              textAlign: TextAlign.justify,
              style: TextStyle(
                  fontSize: isTall ? size : size * 0.9,
                  color: Colors.black,
                  letterSpacing: 0.3)),
    );
  }
}