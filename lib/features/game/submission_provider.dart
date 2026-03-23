import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:show_me_bible/core/supabase_client.dart';
import 'package:show_me_bible/shared/accuracy_calculator.dart';
import 'package:show_me_bible/shared/models.dart';

part 'submission_provider.g.dart';

// ──────────────────────────────────────────────────────
// 단순화된 제출 컨트롤러 (contestant_screen 에서 사용)
// ──────────────────────────────────────────────────────
@riverpod
class SubmissionController extends _$SubmissionController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 자동 저장 (progress_rate 업데이트)
  Future<void> autoSave({
    required String sessionId,
    required int roundNumber,
    required String inputText,
    String? answerContent,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    double progress = 0.0;
    if (answerContent != null && answerContent.isNotEmpty) {
      progress = AccuracyCalculator.calculateProgress(answerContent, inputText);
    } else {
      // 보조 수단으로 대략적인 길이 기준 (보통 성경 한 절은 100~200자 내외)
      progress = (inputText.length / 150).clamp(0.0, 1.0);
    }

    try {
      // 이미 최종 제출된 것이 있는지 확인하여 덮어쓰기 방지 (스피드 모드 로직 꼬임 방어)
      final existing = await supabase
          .from('submissions')
          .select('is_final')
          .eq('session_id', sessionId)
          .eq('user_id', userId)
          .eq('round_number', roundNumber)
          .maybeSingle();
      
      if (existing != null && existing['is_final'] == true) return;

      await supabase.from('submissions').upsert(
        {
          'session_id': sessionId,
          'user_id': userId,
          'round_number': roundNumber,
          'input_text': inputText,
          'progress_rate': progress,
          'is_final': false,
        },
        onConflict: 'session_id,user_id,round_number',
      );
    } catch (_) {}
  }

  /// 최종 제출
  Future<void> submitFinal({
    required String sessionId,
    required int roundNumber,
    required String inputText,
    required double accuracyScore,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      await supabase.from('submissions').upsert(
        {
          'session_id': sessionId,
          'user_id': userId,
          'round_number': roundNumber,
          'input_text': inputText,
          'progress_rate': 1.0,
          'accuracy_score': accuracyScore,
          'is_final': true,
          'submitted_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'session_id,user_id,round_number',
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ──────────────────────────────────────────────────────
// 본인 제출 답안 (특정 라운드)
// ──────────────────────────────────────────────────────
@riverpod
Future<Submission?> mySubmission(
  MySubmissionRef ref,
  String sessionId,
  int roundNumber,
) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  if (!uuidRegex.hasMatch(sessionId)) return null;

  final response = await supabase
      .from('submissions')
      .select()
      .eq('session_id', sessionId)
      .eq('user_id', userId)
      .eq('round_number', roundNumber)
      .maybeSingle();

  if (response == null) return null;
  return Submission.fromJson(response);
}

// ──────────────────────────────────────────────────────
// 제출 관리 Notifier (자동저장 + 최종 제출)
// ──────────────────────────────────────────────────────
@riverpod
class SubmissionNotifier extends _$SubmissionNotifier {
  Timer? _autoSaveTimer;
  String _currentText = '';
  bool _isFinal = false;

  @override
  AsyncValue<Submission?> build(String sessionId, int roundNumber) {
    ref.onDispose(() {
      _autoSaveTimer?.cancel();
    });
    return const AsyncData(null);
  }

  /// 텍스트 변경 시 호출 (자동저장 타이머 시작)
  void onTextChanged(String text, String? answerContent) {
    _currentText = text;
    _autoSaveTimer?.cancel();

    // 10초 후 자동저장
    _autoSaveTimer = Timer(const Duration(seconds: 10), () {
      if (!_isFinal) {
        _saveDraft(answerContent);
      }
    });
  }

  /// 임시 저장 (UPSERT)
  Future<void> _saveDraft(String? answerContent) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || _isFinal) return;

    final progress = answerContent != null
        ? AccuracyCalculator.calculateProgress(answerContent, _currentText)
        : 0.0;

    try {
      await supabase.from('submissions').upsert(
        {
          'session_id': sessionId,
          'user_id': userId,
          'round_number': roundNumber,
          'input_text': _currentText,
          'progress_rate': progress,
          'is_final': false,
        },
        onConflict: 'session_id,user_id,round_number',
      );
    } on PostgrestException catch (_) {
      // 세션이 잠긴 경우 무시
    }
  }

  /// 즉시 저장 (수동 트리거)
  Future<void> saveNow(String? answerContent) async {
    _autoSaveTimer?.cancel();
    await _saveDraft(answerContent);
  }

  /// 최종 제출 (is_final = true, 채점 포함)
  Future<void> submitFinal(String answerContent) async {
    if (_isFinal) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      final accuracy = AccuracyCalculator.calculate(answerContent, _currentText);

      await supabase.from('submissions').upsert(
        {
          'session_id': sessionId,
          'user_id': userId,
          'round_number': roundNumber,
          'input_text': _currentText,
          'progress_rate': 1.0,
          'accuracy_score': accuracy,
          'is_final': true,
          'submitted_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'session_id,user_id,round_number',
      );

      _isFinal = true;
      _autoSaveTimer?.cancel();

      // 상태 갱신
      final updated = await supabase
          .from('submissions')
          .select()
          .eq('session_id', sessionId)
          .eq('user_id', userId)
          .eq('round_number', roundNumber)
          .single();

      state = AsyncData(Submission.fromJson(updated));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 이전 라운드 답안 수정 (is_final이 false일 때만)
  Future<void> updatePreviousAnswer(
    int targetRound,
    String newText,
    String answerContent,
  ) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // RLS가 is_final=FALSE + round_active 상태일 때만 허용
    final accuracy = AccuracyCalculator.calculate(answerContent, newText);
    final progress = AccuracyCalculator.calculateProgress(answerContent, newText);

    await supabase.from('submissions').upsert(
      {
        'session_id': sessionId,
        'user_id': userId,
        'round_number': targetRound,
        'input_text': newText,
        'progress_rate': progress,
        'accuracy_score': accuracy,
        'is_final': false,
      },
      onConflict: 'session_id,user_id,round_number',
    );
  }

  bool get isFinal => _isFinal;
  String get currentText => _currentText;
}
