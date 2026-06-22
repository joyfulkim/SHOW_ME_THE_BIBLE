import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/competition_verses.dart';
import '../../core/supabase_client.dart';
import '../../shared/models.dart';

part 'admin_provider.g.dart';

// ──────────────────────────────────────────────────────
// 관리자 전용 제출 현황 스트림 (전체 참가자)
// ──────────────────────────────────────────────────────
@riverpod
Stream<List<Submission>> allSubmissionsStream(
  AllSubmissionsStreamRef ref,
  String sessionId,
  int roundNumber,
) async* {
  // 1) 초기 데이터 로드 (JOIN 포함)
  final initialResponse = await supabase
      .from('submissions')
      .select('*, profiles(*)')
      .eq('session_id', sessionId)
      .eq('round_number', roundNumber);

  yield (initialResponse as List)
      .map((row) => Submission.fromJson(row))
      .toList()
    ..sort((a, b) {
      if (b.accuracyScore != a.accuracyScore)
        return b.accuracyScore.compareTo(a.accuracyScore);
      final t1 = a.submittedAt ?? a.createdAt;
      final t2 = b.submittedAt ?? b.createdAt;
      return t1.compareTo(t2);
    });

  // 2) Realtime 변화 감지 및 재조회
  await for (final _ in supabase
      .from('submissions')
      .stream(primaryKey: ['id']).eq('session_id', sessionId)) {
    final updatedResponse = await supabase
        .from('submissions')
        .select('*, profiles(*)')
        .eq('session_id', sessionId)
        .eq('round_number', roundNumber);

    yield (updatedResponse as List)
        .map((row) => Submission.fromJson(row))
        .toList()
      ..sort((a, b) {
        if (b.accuracyScore != a.accuracyScore)
          return b.accuracyScore.compareTo(a.accuracyScore);
        final t1 = a.submittedAt ?? a.createdAt;
        final t2 = b.submittedAt ?? b.createdAt;
        return t1.compareTo(t2);
      });
  }
}

// ──────────────────────────────────────────────────────
// 관리자: 구절 추가/조회
// ──────────────────────────────────────────────────────
@riverpod
Future<List<Verse>> versesList(VersesListRef ref) async {
  await ensureCompetitionVersesRegistered();
  final response = await supabase
      .from('verses_pool')
      .select()
      .order('difficulty')
      .order('reference');
  return (response as List)
      .map((e) => Verse.fromJson(e as Map<String, dynamic>))
      .toList();
}

// ──────────────────────────────────────────────────────
// 관리자: 해당 세션에서 이미 선택된 구절 ID들
// ──────────────────────────────────────────────────────
@riverpod
Future<List<int>> usedVerseIds(UsedVerseIdsRef ref, String sessionId) async {
  if (sessionId == 'default') return [];

  final response = await supabase
      .from('session_questions')
      .select('verse_id')
      .eq('session_id', sessionId);

  return (response as List).map((e) => e['verse_id'] as int).toList();
}

@riverpod
class VerseManager extends _$VerseManager {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 구절 추가
  Future<void> addVerse({
    required String reference,
    required String content,
    required int difficulty,
    String? theme,
  }) async {
    state = const AsyncLoading();
    try {
      await supabase.from('verses_pool').insert({
        'reference': reference,
        'content': content,
        'difficulty': difficulty,
        'theme': theme,
        'created_by': supabase.auth.currentUser?.id,
      });
      ref.invalidate(versesListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// 구절 수정
  Future<void> updateVerse({
    required int id,
    required String reference,
    required String content,
    required int difficulty,
    String? theme,
  }) async {
    state = const AsyncLoading();
    try {
      await supabase.from('verses_pool').update({
        'reference': reference,
        'content': content,
        'difficulty': difficulty,
        'theme': theme,
      }).eq('id', id);
      ref.invalidate(versesListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
