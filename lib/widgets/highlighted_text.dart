import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = _buildHighlightedSpans(context);
    
    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<TextSpan> _buildHighlightedSpans(BuildContext context) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    final defaultStyle = style ?? TextStyle(
      color: Theme.of(context).shadowColor,
    );
    
    final defaultHighlightStyle = highlightStyle ?? TextStyle(
      color: Theme.of(context).primaryColor,
      fontWeight: FontWeight.bold,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
    );

    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: defaultStyle,
        ));
      }
      
      // Add the highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: defaultHighlightStyle,
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }
    
    return spans;
  }
}

/// Extension to provide highlighting functionality to any text widget
extension TextHighlighting on String {
  Widget highlighted(
    String query, {
    TextStyle? style,
    TextStyle? highlightStyle,
    int maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return HighlightedText(
      text: this,
      query: query,
      style: style,
      highlightStyle: highlightStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}