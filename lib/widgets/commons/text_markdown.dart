import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class TextMarkDown extends StatelessWidget {
  const TextMarkDown(
    this.data, {
    required this.style,
    required this.textAlign,
    super.key,
    this.markdownStyle,
    this.selectable = false,
    this.styleSheetTheme,
    this.syntaxHighlighter,
    this.onSelectionChanged,
    this.onTapLink,
    this.onTapText,
    this.imageDirectory,
    this.blockSyntaxes,
    this.inlineSyntaxes,
    this.extensionSet,
    this.sizedImageBuilder,
    this.checkboxBuilder,
    this.bulletBuilder,
    this.builders = const <String, MarkdownElementBuilder>{},
    this.paddingBuilders = const <String, MarkdownPaddingBuilder>{},
    this.listItemCrossAxisAlignment = MarkdownListItemCrossAxisAlignment.baseline,
    this.shrinkWrap = true,
    this.fitContent = true,
    this.softLineBreak = false,
    this.canUnderline = false,
  });

  final String data;
  final TextStyle style;
  final MarkdownStyleSheet? markdownStyle;
  final WrapAlignment textAlign;
  final bool selectable;
  final MarkdownStyleSheetBaseTheme? styleSheetTheme;
  final SyntaxHighlighter? syntaxHighlighter;
  final void Function(String?, TextSelection, SelectionChangedCause?)? onSelectionChanged;
  final void Function(String, String?, String)? onTapLink;
  final void Function()? onTapText;
  final String? imageDirectory;
  final List<md.BlockSyntax>? blockSyntaxes;
  final List<md.InlineSyntax>? inlineSyntaxes;
  final md.ExtensionSet? extensionSet;
  final Widget Function(MarkdownImageConfig)? sizedImageBuilder;
  final Widget Function(bool)? checkboxBuilder;
  final Widget Function(MarkdownBulletParameters)? bulletBuilder;
  final Map<String, MarkdownElementBuilder> builders;
  final Map<String, MarkdownPaddingBuilder> paddingBuilders;
  final MarkdownListItemCrossAxisAlignment listItemCrossAxisAlignment;
  final bool shrinkWrap;
  final bool fitContent;
  final bool softLineBreak;
  final bool canUnderline;

  @override
  Widget build(BuildContext context) {
    final markdownStyleSheet =
        markdownStyle ??
        MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: style,
          textAlign: textAlign,
          a: style.copyWith(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
          em: style.copyWith(
            fontStyle: canUnderline ? style.fontStyle : FontStyle.italic,
            decoration: canUnderline ? TextDecoration.underline : style.decoration,
          ),
        );
    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: markdownStyleSheet,
      styleSheetTheme: styleSheetTheme,
      syntaxHighlighter: syntaxHighlighter,
      onSelectionChanged: onSelectionChanged,
      onTapLink:
          onTapLink ??
          (text, url, title) {
            launchUrl(Uri.parse(url ?? 'https://helios.do'));
          },
      onTapText: onTapText,
      imageDirectory: imageDirectory,
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      extensionSet: extensionSet,
      sizedImageBuilder: sizedImageBuilder,
      checkboxBuilder: checkboxBuilder,
      bulletBuilder: bulletBuilder,
      builders: builders,
      paddingBuilders: paddingBuilders,
      listItemCrossAxisAlignment: listItemCrossAxisAlignment,
      shrinkWrap: shrinkWrap,
      fitContent: fitContent,
      softLineBreak: softLineBreak,
    );
  }
}
