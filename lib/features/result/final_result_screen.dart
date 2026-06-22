import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/app_shell.dart';
import '../../main.dart';

import '../../core/supabase_client.dart';
import '../../shared/models.dart';
import '../../features/auth/auth_provider.dart';
import '../game/game_provider.dart';

part 'final_result_screen.g.dart';

// ──────────────────────────────────────────────────────
// 최종 결과 Provider
// ──────────────────────────────────────────────────────
@riverpod
Future<List<FinalRanking>> finalRankings(
  FinalRankingsRef ref,
  String sessionId,
) async {
  // 세션 정보 (시작 시간 및 모드 확인용)
  final sessionRow = await supabase
      .from('game_sessions')
      .select()
      .eq('id', sessionId)
      .maybeSingle();
  if (sessionRow == null) return [];
  final session = GameSession.fromJson(sessionRow);

  // 모든 라운드의 제출을 불러와 유저별 합산
  final subs = await supabase
      .from('submissions')
      .select('*, profiles(nickname)')
      .eq('session_id', sessionId)
      .eq('is_final', true);

  final Map<String, _UserScore> map = {};
  for (final row in subs as List) {
    final userId = row['user_id'] as String;
    final score = (row['accuracy_score'] as num).toDouble();
    final subAt = DateTime.parse(row['submitted_at'] as String);
    final nickname = (row['profiles'] as Map?)?['nickname'] as String? ?? '?';

    map.putIfAbsent(userId, () => _UserScore(userId, nickname));
    map[userId]!.totalScore += score;
    map[userId]!.roundCount++;
    if (map[userId]!.lastSubmittedAt == null ||
        subAt.isAfter(map[userId]!.lastSubmittedAt!)) {
      map[userId]!.lastSubmittedAt = subAt;
    }
  }

  final rankings = map.values.map((u) {
    Duration? duration;
    if (session.startedAt != null && u.lastSubmittedAt != null) {
      duration = u.lastSubmittedAt!.difference(session.startedAt!);
    }

    return FinalRanking(
      userId: u.userId,
      nickname: u.nickname,
      totalScore: u.totalScore,
      avgScore: u.roundCount > 0 ? u.totalScore / u.roundCount : 0,
      roundCount: u.roundCount,
      duration: duration,
      isFinished: u.roundCount == session.totalRounds,
    );
  }).toList();

  // 공통 랭킹 로직: 1. 총점(내림차순) -> 2. 소요 시간(오름차순, 먼저 끝낸 사람)
  rankings.sort((a, b) {
    if (b.totalScore != a.totalScore) {
      return b.totalScore.compareTo(a.totalScore);
    }
    if (a.duration != null && b.duration != null) {
      return a.duration!.compareTo(b.duration!);
    }
    return 0;
  });

  return rankings;
}

class _UserScore {
  final String userId;
  final String nickname;
  double totalScore = 0;
  int roundCount = 0;
  DateTime? lastSubmittedAt;
  _UserScore(this.userId, this.nickname);
}

class FinalRanking {
  final String userId;
  final String nickname;
  final double totalScore;
  final double avgScore;
  final int roundCount;
  final Duration? duration;
  final bool isFinished;

  const FinalRanking({
    required this.userId,
    required this.nickname,
    required this.totalScore,
    required this.avgScore,
    required this.roundCount,
    this.duration,
    required this.isFinished,
  });
}

// ──────────────────────────────────────────────────────
// 최종 결과 화면
// ──────────────────────────────────────────────────────
class FinalResultScreen extends ConsumerWidget {
  const FinalResultScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rankingsAsync = ref.watch(finalRankingsProvider(sessionId));
    final sessionAsync = ref.watch(gameSessionStreamProvider(sessionId));

    return BiblePageFrame(
      child: SafeArea(
        child: sessionAsync.when(
          data: (session) {
            if (session == null) return const SizedBox.shrink();

            final profileAsync = ref.watch(currentProfileProvider);
            final profile = profileAsync.valueOrNull;
            final isAdmin = profile?.role == 'admin';

            // 아직 채점이 진행 중이라면 (관리자 제외)
            if (!session.gradingCompleted && !isAdmin) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: BibleCreamCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fact_check_outlined,
                          size: 62,
                          color: BibleColors.goldDark,
                        ),
                        const Gap(24),
                        const Text(
                          '최종 채점이 진행 중입니다.',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: BibleColors.ink,
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          '관리자가 모든 채점을 완료할 때까지\n잠시만 기다려주세요...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45),
                        ),
                        const Gap(32),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/mode-selection'),
                          icon: const Icon(Icons.home),
                          label: const Text('홈으로'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return rankingsAsync.when(
              data: (rankings) => _buildResult(context, theme, rankings),
              loading: () => const Center(
                child: CircularProgressIndicator(color: BibleColors.gold),
              ),
              error: (e, _) => Center(
                child: Text(
                  '오류: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: BibleColors.gold),
          ),
          error: (e, _) => Center(
            child: Text(
              '세션 로딩 오류: $e',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    ThemeData theme,
    List<FinalRanking> rankings,
  ) {
    return CustomScrollView(
      slivers: [
        // ── 헤더 ──
        SliverToBoxAdapter(
          child: _buildHeader(theme),
        ),

        // ── 시상대 (Top 3) ──
        if (rankings.length >= 3)
          SliverToBoxAdapter(
            child: _buildPodium(theme, rankings),
          ),

        // ── 전체 순위 ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final rank = rankings[index];
                final position = index + 1;
                return _RankingTile(
                  sessionId: sessionId,
                  position: position,
                  ranking: rank,
                  isMine: rank.userId == supabase.auth.currentUser?.id,
                );
              },
              childCount: rankings.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: Gap(32)),

        // ── 홈으로 버튼 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/mode-selection'),
              icon: const Icon(Icons.home),
              label: const Text('홈으로'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Gap(96)),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const Gap(16),
          Text(
            'SHOW ME THE BIBLE',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(ThemeData theme, List<FinalRanking> rankings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2등
          _PodiumItem(
            ranking: rankings[1],
            position: 2,
            height: 100,
            color: const Color(0xFFC0C0C0),
            emoji: '🥈',
          ),
          const Gap(8),
          // 1등
          _PodiumItem(
            ranking: rankings[0],
            position: 1,
            height: 140,
            color: const Color(0xFFD4AF37),
            emoji: '🥇',
          ),
          const Gap(8),
          // 3등
          _PodiumItem(
            ranking: rankings[2],
            position: 3,
            height: 80,
            color: const Color(0xFFCD7F32),
            emoji: '🥉',
          ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({
    required this.ranking,
    required this.position,
    required this.height,
    required this.color,
    required this.emoji,
  });

  final FinalRanking ranking;
  final int position;
  final double height;
  final Color color;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const Gap(4),
          Text(
            ranking.nickname,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Gap(4),
          Text(
            ranking.duration != null
                ? '${ranking.duration!.inMinutes}:${(ranking.duration!.inSeconds % 60).toString().padLeft(2, '0')}'
                : '${ranking.totalScore.toStringAsFixed(1)}점',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Gap(6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: color, width: 2),
                left: BorderSide(color: color.withOpacity(0.5)),
                right: BorderSide(color: color.withOpacity(0.5)),
              ),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.sessionId,
    required this.position,
    required this.ranking,
    required this.isMine,
  });

  final String sessionId;
  final int position;
  final FinalRanking ranking;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medalColor = position == 1
        ? const Color(0xFFD4AF37)
        : position == 2
            ? const Color(0xFFC0C0C0)
            : position == 3
                ? const Color(0xFFCD7F32)
                : Colors.black26;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
              '/user-result?sessionId=$sessionId&targetUserId=${ranking.userId}'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMine
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : AppTheme.kSurface,
              borderRadius: BorderRadius.circular(12),
              border: isMine
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3))
                  : Border.all(color: const Color(0xFFCDD0E3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '$position',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: medalColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ranking.nickname,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.kNavy,
                              fontWeight:
                                  isMine ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isMine) ...[
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ME',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '평균 ${ranking.avgScore.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  ranking.duration != null
                      ? '${ranking.duration!.inMinutes}:${(ranking.duration!.inSeconds % 60).toString().padLeft(2, '0')}'
                      : '${ranking.totalScore.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: medalColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(ranking.duration != null ? '' : ' 점',
                    style: const TextStyle(color: Colors.black45)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
