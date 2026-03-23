import 'package:flutter/material.dart';

/// 복사/붙여넣기 및 선택이 비활성화된 보안 텍스트 필드
class SecureTextField extends StatelessWidget {
  const SecureTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 6,
    this.minLines = 4,
    this.style,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;
  final int minLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      // ★ 복사/붙여넣기 비활성화 핵심 설정
      enableInteractiveSelection: false,
      // ★ 컨텍스트 메뉴(복사/잘라내기/붙여넣기) 완전 차단
      contextMenuBuilder: (context, editableTextState) {
        return const SizedBox.shrink();
      },
      style: style ??
          theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            height: 1.7,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
