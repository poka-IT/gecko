import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';

class BuildText extends StatelessWidget {
  const BuildText({super.key, required this.text, this.size = 17, this.isMd = true});

  final String text;
  final double size;
  final bool isMd;

  @override
  Widget build(BuildContext context) {
    final double ratio = isTall ? 1 : 0.95;
    final mdStyle = MarkdownStyleSheet(
      p: scaledTextStyle(fontSize: size * ratio, color: context.colorScheme.onSecondaryContainer, letterSpacing: 0.3),
      textAlign: WrapAlignment.spaceBetween,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      width: scaleSize(350 * ratio),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: isMd
          ? MarkdownBody(data: text, styleSheet: mdStyle)
          : Text(
              text,
              textAlign: TextAlign.justify,
              style: scaledTextStyle(
                fontSize: size * ratio,
                color: context.colorScheme.onSecondaryContainer,
                letterSpacing: 0.3,
              ),
            ),
    );
  }
}
