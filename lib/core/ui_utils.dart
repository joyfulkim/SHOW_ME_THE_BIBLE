import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

DateTime? _lastPressedAt;

/// 앱 종료 확인 다이얼로그
Future<bool?> showExitConfirmationDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('앱 종료'),
      content: const Text('R_BIBLE 앱을 종료하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('종료', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}

/// 뒤로가기 두 번 눌러서 앱 종료 처리 (기존 호환성 유지용)
Future<void> handleDoubleTapExit(BuildContext context) async {
  final now = DateTime.now();
  if (_lastPressedAt == null ||
      now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
    _lastPressedAt = now;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('한번 더 누르면 종료됩니다'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  await SystemNavigator.pop();
}
