import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/c_token.dart';
import '../../domain/c_tokenizer.dart';

/// A [TextEditingController] that tokenizes the current text on every change
/// and renders colored [TextSpan]s via [buildTextSpan].
///
/// The editor widget uses a [TextField] with `obscureText: false` and a
/// transparent foreground — all visible color comes from this controller.
class CHighlightController extends TextEditingController {
  CHighlightController({super.text});

  bool _isDark = true;
  set isDark(bool value) {
    if (_isDark != value) {
      _isDark = value;
      notifyListeners();
    }
  }

  double _fontSize = 14.0;
  set fontSize(double value) {
    if (_fontSize != value) {
      _fontSize = value;
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final tokens = CTokenizer.tokenize(text);
    return TextSpan(
      style: style,
      children: tokens.map((t) => _tokenSpan(t)).toList(),
    );
  }

  TextSpan _tokenSpan(CToken token) {
    final color = _colorFor(token.type);
    return TextSpan(
      text: token.text,
      style: AppTextStyles.code.copyWith(
        color: color,
        fontSize: _fontSize,
        fontWeight: token.type == CTokenType.keyword
            ? FontWeight.w700
            : token.type == CTokenType.type
            ? FontWeight.w600
            : FontWeight.w400,
        fontStyle: token.type == CTokenType.comment
            ? FontStyle.italic
            : FontStyle.normal,
      ),
    );
  }

  Color _colorFor(CTokenType type) {
    return switch (type) {
      CTokenType.keyword => AppColors.codeKeyword,
      CTokenType.type => AppColors.codeType,
      CTokenType.preprocessor => AppColors.codePreprocessor,
      CTokenType.stringLiteral => AppColors.codeString,
      CTokenType.charLiteral => AppColors.codeString,
      CTokenType.number => AppColors.codeNumber,
      CTokenType.comment => AppColors.codeComment,
      CTokenType.function => AppColors.codeFunction,
      CTokenType.operator_ =>
        _isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
      CTokenType.punctuation => AppColors.codePunctuation,
      CTokenType.identifier =>
        _isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
      CTokenType.whitespace => Colors.transparent,
    };
  }
}
