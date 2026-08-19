import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:mock_mobile/core/theme/app_colors.dart';
import 'package:mock_mobile/core/utils/rich_content_utils.dart';

class MockRichContent extends StatelessWidget {
  const MockRichContent({
    super.key,
    this.content,
    this.format,
    this.style,
    this.inline = false,
    this.textAlign,
  });

  final String? content;
  final String? format;
  final TextStyle? style;
  final bool inline;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final safeContent = content?.trim() ?? '';
    if (safeContent.isEmpty) {
      return const SizedBox.shrink();
    }

    final resolvedStyle = style ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: inline ? null : AppColors.textSecondary,
              height: inline ? 1.35 : 1.6,
            ) ??
        const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6);

    final normalizedFormat = normalizeContentFormat(format);
    final containsMath = hasMathContent(safeContent);
    final containsHtml = containsHtmlMarkup(safeContent);

    if ((normalizedFormat == 'HTML' || (containsHtml && !containsMath)) &&
        !safeContent.contains('\n') &&
        !containsMath) {
      return _HtmlBlock(
        data: safeContent,
        inline: inline,
        style: resolvedStyle,
        textAlign: textAlign,
      );
    }

    final blocks = _buildBlocks(
      safeContent,
      resolvedStyle,
      normalizedFormat == 'LATEX',
    );

    if (inline) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: blocks,
      );
    }

    return DefaultTextStyle(
      style: resolvedStyle.copyWith(
        fontFamily: normalizedFormat == 'LATEX' ? 'serif' : resolvedStyle.fontFamily,
        letterSpacing: normalizedFormat == 'LATEX' ? 0.15 : resolvedStyle.letterSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks,
      ),
    );
  }

  List<Widget> _buildBlocks(String safeContent, TextStyle resolvedStyle, bool latexFormat) {
    final lines = safeContent.split('\n');
    final blocks = <Widget>[];
    final listBuffer = <String>[];

    void flushList() {
      if (listBuffer.isEmpty) {
        return;
      }
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listBuffer
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(left: 18, bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: _RichLine(parts: item, style: resolvedStyle)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
      listBuffer.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flushList();
        continue;
      }

      if (!inline && RegExp(r'^[-*•]\s+').hasMatch(trimmed)) {
        listBuffer.add(trimmed.replaceFirst(RegExp(r'^[-*•]\s+'), ''));
        continue;
      }

      flushList();
      blocks.add(
        Padding(
          padding: EdgeInsets.only(bottom: inline ? 0 : 8),
          child: _RichLine(parts: trimmed, style: resolvedStyle),
        ),
      );
    }

    flushList();
    return blocks;
  }
}

class _RichLine extends StatelessWidget {
  const _RichLine({required this.parts, required this.style});

  final String parts;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (containsHtmlMarkup(parts) && !hasMathContent(parts)) {
      return _HtmlBlock(data: parts, inline: true, style: style);
    }

    final segments = splitRichContent(parts);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < segments.length; index++)
          _RichSegment(key: ValueKey('$index-${segments[index]}'), value: segments[index], style: style),
      ],
    );
  }
}

class _RichSegment extends StatelessWidget {
  const _RichSegment({super.key, required this.value, required this.style});

  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final mathToken = normalizeMathToken(value);
    if (mathToken != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: mathToken.displayMode ? 6 : 0),
        child: Math.tex(
          mathToken.expression,
          mathStyle: mathToken.displayMode ? MathStyle.display : MathStyle.text,
          textStyle: style,
          onErrorFallback: (error) => Text(
            value,
            style: style.copyWith(fontFamily: null),
          ),
        ),
      );
    }

    if (containsHtmlMarkup(value)) {
      return _HtmlBlock(data: value, inline: true, style: style);
    }

    return Text(value, style: style);
  }
}

class _HtmlBlock extends StatelessWidget {
  const _HtmlBlock({
    required this.data,
    required this.inline,
    required this.style,
    this.textAlign,
  });

  final String data;
  final bool inline;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Html(
      data: data,
      shrinkWrap: true,
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(style.fontSize ?? 15),
          lineHeight: LineHeight(style.height ?? 1.5),
          color: style.color,
          fontWeight: style.fontWeight,
          textAlign: textAlign ?? TextAlign.start,
          display: inline ? Display.inlineBlock : Display.block,
        ),
        'p': Style(margin: Margins.only(bottom: 6)),
        'sup': Style(fontSize: FontSize((style.fontSize ?? 15) * 0.8), verticalAlign: VerticalAlign.sup),
        'sub': Style(fontSize: FontSize((style.fontSize ?? 15) * 0.8), verticalAlign: VerticalAlign.sub),
      },
    );
  }
}
