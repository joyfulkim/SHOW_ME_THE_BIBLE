import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:show_me_bible/core/supabase_client.dart';
import 'package:show_me_bible/shared/models.dart';

part 'game_provider.g.dart';

// ──────────────────────────────────────────────────────
// 현재 활성 세션 ID (앱 전역 공유)
// ──────────────────────────────────────────────────────
final activeSessionIdProvider = StateProvider<String?>((ref) => null);

// ──────────────────────────────────────────────────────
// 가장 최근의 활성 (waiting, round_active, round_locked) 세션 찾기 (실시간 반영)
// ──────────────────────────────────────────────────────
@riverpod
Stream<GameSession?> latestActiveSession(LatestActiveSessionRef ref) {
  // game_sessions 테이블 전체를 구독하여 실시간 변화 감지
  return supabase
      .from('game_sessions')
      .stream(primaryKey: ['id'])
      .map((list) {
        // DB에 있는 모든 세션을 불러와서 클라이언트 측에서 정렬 및 필터링
        if (list.isEmpty) return null;
        
        // 1. 생성일자 기준 내림차순 정렬 (가장 최신 것이 첫 번째)
        final sorted = List<Map<String, dynamic>>.from(list)
          ..sort((a, b) {
            final aTime = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
            final bTime = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
          
        final latest = sorted.first;
        final status = latest['status'] as String?;
        final createdAtStr = latest['created_at']?.toString() ?? '';
        final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime(0);
        final age = DateTime.now().difference(createdAt);

        // 2. 가장 최신 세션이라도 '종료'되었거나 12시간 이상 지났다면 '없음'으로 간주
        // 이렇게 해야 현재 진행 중인 딱 하나의 세션만 참가자에게 노출됩니다.
        if (status == 'finished' || age.inHours >= 12) {
          return null;
        }
          
        return GameSession.fromJson(latest);
      });
}

// ──────────────────────────────────────────────────────
// 게임 세션 Realtime 스트림
// ──────────────────────────────────────────────────────
@riverpod
Stream<GameSession?> gameSessionStream(GameSessionStreamRef ref, String sessionId) {
  // UUID 형식이 아니면 (예: "default") 쿼리하지 않고 즉시 null 반환하여 DB 에러 방지
  final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  if (!uuidRegex.hasMatch(sessionId)) {
    return Stream.value(null);
  }

  // 최초 데이터 로드 + Realtime 구독 결합
  return supabase
      .from('game_sessions')
      .stream(primaryKey: ['id'])
      .eq('id', sessionId)
      .limit(1)
      .map((rows) => rows.isNotEmpty ? GameSession.fromJson(rows.first) : null);
}

// ──────────────────────────────────────────────────────
// 현재 라운드 구절 (session_questions + verses_pool JOIN)
// ──────────────────────────────────────────────────────
@riverpod
Future<SessionQuestion?> currentQuestion(
  CurrentQuestionRef ref,
  String sessionId,
  int roundNumber,
) async {
  final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  if (!uuidRegex.hasMatch(sessionId)) return null;

  final response = await supabase
      .from('session_questions')
      .select('*, verses_pool(*)')
      .eq('session_id', sessionId)
      .eq('round_number', roundNumber)
      .maybeSingle();

  if (response == null) return null;
  return SessionQuestion.fromJson(response);
}

// ──────────────────────────────────────────────────────
// 현재 라운드 구절 스트림
// game_sessions 스트림이 변경될 때마다 session_questions를
// select()로 직접 조회 → stream()의 필터링 버그 우회
// ──────────────────────────────────────────────────────
@riverpod
Stream<SessionQuestion?> currentQuestionStream(
  CurrentQuestionStreamRef ref,
  String sessionId,
  int roundNumber,
) async* {
  final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  if (!uuidRegex.hasMatch(sessionId)) {
    yield null;
    return;
  }

  // 세션의 변화를 watch하여 변화가 생길 때마다 구절 정보를 다시 조회하도록 함
  final _ = ref.watch(gameSessionStreamProvider(sessionId)).valueOrNull;
  
  // 최초 및 세션 변화 시마다 조회
  final question = await _fetchQuestion(sessionId, roundNumber);
  yield question;

  // 만약 구절이 아직 없다면(데이터 지연 등), submissions 변화가 있을 때 재시도할 수 있도록 함
  if (question == null) {
    await for (final _ in supabase.from('session_questions').stream(primaryKey: ['id']).eq('session_id', sessionId)) {
      yield await _fetchQuestion(sessionId, roundNumber);
    }
  }
}

/// 구절 단건 조회 헬퍼 (verses_pool JOIN 포함)
Future<SessionQuestion?> _fetchQuestion(
  String sessionId,
  int roundNumber,
) async {
  try {
    final row = await supabase
        .from('session_questions')
        .select('*, verses_pool(*)')
        .eq('session_id', sessionId)
        .eq('round_number', roundNumber)
        .maybeSingle();
    if (row == null) return null;
    return SessionQuestion.fromJson(row);
  } catch (_) {
    return null;
  }
}

// ──────────────────────────────────────────────────────
// 사용자의 현재 라운드 (실시간 반영)
// ──────────────────────────────────────────────────────
@riverpod
Stream<int> userCurrentRound(UserCurrentRoundRef ref, String sessionId) async* {
  // 1. 세션 상태 감시
  final session = ref.watch(gameSessionStreamProvider(sessionId)).valueOrNull;
  if (session == null || session.isWaiting) {
    yield 1;
    return;
  }

  // Live Mode: 관리자의 currentRound를 따름
  if (session.isLiveMode) {
    yield session.currentRound;
    return;
  }

  // Speed Mode: 본인의 제출 기록에 따라 실시간 계산
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    yield 1;
    return;
  }

  // 내부 계산 함수
  Future<int> calculateNextRound() async {
    final response = await supabase
        .from('submissions')
        .select('round_number')
        .eq('session_id', sessionId)
        .eq('user_id', userId)
        .eq('is_final', true)
        .order('round_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return 1;
    final lastRound = response['round_number'] as int;
    return (lastRound + 1).clamp(1, session.totalRounds + 1);
  }

  // A) 최초 로드 시점 전송
  yield await calculateNextRound();

  // B) 본인의 제출 기록 또는 세션 라운드 변화를 Realtime 구독
  // .stream()에 .eq() 필터가 가끔 누락되는 이슈를 대비하여 세션 아이디로만 필터링 후 
  // 내부에서 본인 기록인지 확인
  await for (final _ in supabase
      .from('submissions')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)) {
    
    // 이 리스트의 어떠한 변화라도 감지되면 라운드를 재계산하여 전송
    yield await calculateNextRound();
  }
}

// ──────────────────────────────────────────────────────
// 실시간 참가자 현황 (리더보드용)
// ──────────────────────────────────────────────────────
@riverpod
Stream<List<Submission>> submissionsStream(
  SubmissionsStreamRef ref,
  String sessionId,
  int roundNumber,
) async* {
  final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  if (!uuidRegex.hasMatch(sessionId)) {
    yield [];
    return;
  }

  // 1) 초기 데이터 즉시 로드 (JOIN 포함)
  final initialResponse = await supabase
      .from('submissions')
      .select('*, profiles(*)')
      .eq('session_id', sessionId)
      .eq('round_number', roundNumber);
  
  yield (initialResponse as List)
      .map((row) => Submission.fromJson(row))
      .toList()
    ..sort((a, b) {
      if (b.accuracyScore != a.accuracyScore) return b.accuracyScore.compareTo(a.accuracyScore);
      final t1 = a.submittedAt ?? a.createdAt;
      final t2 = b.submittedAt ?? b.createdAt;
      return t1.compareTo(t2);
    });

  // 2) submissions 테이블의 변화를 감지하여 재조회 (Realtime 트리거)
  await for (final _ in supabase
      .from('submissions')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)) {
    
    final updatedResponse = await supabase
        .from('submissions')
        .select('*, profiles(*)')
        .eq('session_id', sessionId)
        .eq('round_number', roundNumber);

    yield (updatedResponse as List)
        .map((row) => Submission.fromJson(row))
        .toList()
      ..sort((a, b) {
        if (b.accuracyScore != a.accuracyScore) return b.accuracyScore.compareTo(a.accuracyScore);
        final t1 = a.submittedAt ?? a.createdAt;
        final t2 = b.submittedAt ?? b.createdAt;
        return t1.compareTo(t2);
      });
  }
}

// ──────────────────────────────────────────────────────
// 특정 유저의 모든 라운드 제출 내역 (상세 결과용)
// ──────────────────────────────────────────────────────
@riverpod
Future<List<Submission>> userSubmissions(
  UserSubmissionsRef ref,
  String sessionId,
  String userId,
) async {
  final response = await supabase
      .from('submissions')
      .select('*, profiles(*)')
      .eq('session_id', sessionId)
      .eq('user_id', userId)
      .eq('is_final', true)
      .order('round_number', ascending: true);

  return (response as List).map((row) => Submission.fromJson(row)).toList();
}

// ──────────────────────────────────────────────────────
// 모든 라운드 제출 현황 (스피드 모드 리더보드용)
// ──────────────────────────────────────────────────────
final allSubmissionsStreamProvider = StreamProvider.family<List<Submission>, String>((ref, sessionId) async * {
  final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  if (!uuidRegex.hasMatch(sessionId)) {
    yield [];
    return;
  }

  // 초기 데이터
  final initial = await supabase
      .from('submissions')
      .select('*, profiles(*)')
      .eq('session_id', sessionId);
  
  yield (initial as List).map((row) => Submission.fromJson(row)).toList();

  // 리얼타임 구독
  await for (final _ in supabase
      .from('submissions')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)) {
    
    final updated = await supabase
        .from('submissions')
        .select('*, profiles(*)')
        .eq('session_id', sessionId);

    yield (updated as List).map((row) => Submission.fromJson(row)).toList();
  }
});

// ──────────────────────────────────────────────────────
// 전체 구절 목록 (관리자 구절 선택용)
// ──────────────────────────────────────────────────────
@riverpod
Future<List<Verse>> allVerses(AllVersesRef ref) async {
  final response = await supabase
      .from('verses_pool')
      .select()
      .order('difficulty')
      .order('id');

  return (response as List)
      .map((e) => Verse.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ──────────────────────────────────────────────────────
// 관리자 라운드 제어 Notifier
// ──────────────────────────────────────────────────────
@riverpod
class AdminController extends _$AdminController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 세션 시작 (waiting → round_active)
  Future<void> startSession(String sessionId) async {
    state = const AsyncLoading();
    try {
      // 1. 상태 변경 RPC 호출 (DB 트리거 등 실행)
      final result = await supabase.rpc('admin_start_session', params: {
        'p_session_id': sessionId,
      });
      if (result != null && result is Map && result['error'] != null) {
        throw result['error'];
      }
      
      // 2. 세션 정보 조회하여 모드 확인 (필요한 경우 로직 추가 가능)
      await supabase.from('game_sessions').select('game_mode').eq('id', sessionId).single();

      // 3. 상태 및 시작 시간 명시적 기록 (RPC 버그 방어 및 모드별 상태 설정)
      final status = (result != null && result is Map && result['p_game_mode'] == 'speed')
          ? 'round_active'
          : 'round_locked'; // 실시간 모드는 구절 선택을 위해 round_locked로 시작

      await supabase.from('game_sessions').update({
        'status': status,
        'current_round': 1,
        'started_at': DateTime.now().toIso8601String(),
        'is_paused': false,
      }).eq('id', sessionId);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 구절 지정 후 라운드 활성화 (round_locked → round_active)
  Future<void> activateRound(String sessionId, int verseId) async {
    state = const AsyncLoading();
    try {
      final result = await supabase.rpc('admin_activate_round', params: {
        'p_session_id': sessionId,
        'p_verse_id': verseId,
      });
      if (result != null && result is Map && result['error'] != null) {
        throw result['error'];
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 다음 라운드로 전환 (round_active → round_locked, 미제출 일괄 확정)
  Future<void> advanceRound(String sessionId) async {
    state = const AsyncLoading();
    try {
      final result = await supabase.rpc('admin_advance_round', params: {
        'p_session_id': sessionId,
      });
      if (result != null && result is Map && result['error'] != null) {
        throw result['error'];
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 세션 생성
  Future<String?> createSession(int totalRounds, String title, bool sttEnabled, String gameMode) async {
    state = const AsyncLoading();
    try {
      final user = supabase.auth.currentUser;
      final result = await supabase
          .from('game_sessions')
          .insert({
            'total_rounds': totalRounds,
            'title': title,
            'stt_enabled': sttEnabled,
            'game_mode': gameMode,
            'created_by': user?.id,
          })
          .select('id')
          .single();
      state = const AsyncData(null);
      return result['id'] as String;
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ Supabase Error (createSession): $e');
        print('Stacktrace: $st');
      }
      state = AsyncError(e, st);
      return null;
    }
  }

  /// 스피드 모드: 모든 라운드 구절 미리 지정
  Future<void> preAssignVerses(String sessionId, List<int> verseIds) async {
    state = const AsyncLoading();
    try {
      final List<Map<String, dynamic>> inserts = [];
      for (int i = 0; i < verseIds.length; i++) {
        inserts.add({
          'session_id': sessionId,
          'round_number': i + 1,
          'verse_id': verseIds[i],
        });
      }
      await supabase.from('session_questions').insert(inserts);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 세션 초기화 (완전 삭제)
  Future<void> resetSession(String sessionId) async {
    state = const AsyncLoading();
    try {
      // CASCADE 설정이 안되어 있을 경우를 대비해 수동으로 삭제 순서 제어
      await supabase.from('submissions').delete().eq('session_id', sessionId);
      await supabase.from('session_questions').delete().eq('session_id', sessionId);
      await supabase.from('game_sessions').delete().eq('id', sessionId);
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 구절 추가
  Future<void> addVerse(String reference, String content, int difficulty, {String? theme}) async {
    state = const AsyncLoading();
    try {
      await supabase.from('verses_pool').insert({
        'reference': reference,
        'content': content,
        'difficulty': difficulty,
        'theme': theme,
        'created_by': supabase.auth.currentUser?.id,
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 참가자 점수 수동 수정 (관리자 채점)
  Future<void> updateSubmissionScore(int submissionId, double newScore) async {
    state = const AsyncLoading();
    try {
      await supabase
          .from('submissions')
          .update({
            'accuracy_score': newScore,
            'is_final': true, // 관리자가 채점하면 최종본으로 간주
          })
          .eq('id', submissionId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 세션 종료 (모든 모드 공용)
  Future<void> endSession(String sessionId) async {
    state = const AsyncLoading();
    try {
      await supabase.from('game_sessions').update({
        'status': 'finished',
        'finished_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 채점 완료 처리 및 결과 공개
  Future<void> completeGrading(String sessionId) async {
    state = const AsyncLoading();
    try {
      await supabase
          .from('game_sessions')
          .update({'grading_completed': true})
          .eq('id', sessionId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
