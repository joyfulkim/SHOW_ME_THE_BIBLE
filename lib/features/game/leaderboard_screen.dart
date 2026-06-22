import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:show_me_bible/features/auth/auth_provider.dart';

import 'package:show_me_bible/core/app_shell.dart';
import 'package:show_me_bible/main.dart';
import '../../core/admin_config.dart';
import '../../core/supabase_client.dart';
import '../../shared/accuracy_calculator.dart';
import '../../shared/models.dart';
import '../game/game_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(gameSessionStreamProvider(sessionId));

    return BiblePageFrame(
      bottomNavigationBar: BibleBottomNav(
        active: 'ranking',
        onHome: () => context.go('/mode-selection'),
        onPractice: () => context.push('/practice-lobby'),
        onRanking: () {},
        onSettings: () => context.push('/settings'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: BibleTopBar(
                title: '랭킹',
                sideWidth: 104,
                leading: BibleHomeLeading(
                  showBack: true,
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go('/mode-selection'),
                ),
              ),
            ),
            Expanded(
              child: sessionAsync.when(
                data: (session) {
                  if (session == null) {
                    return const Center(
                      child: Text(
                        '세션 없음',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return _LeaderboardBody(
                    sessionId: sessionId,
                    session: session,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BibleColors.gold),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '오류: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardBody extends ConsumerWidget {
  const _LeaderboardBody({
    required this.sessionId,
    required this.session,
  });
  final String sessionId;
  final GameSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final submissionsAsync = session.isSpeedMode
        ? ref.watch(allSubmissionsStreamProvider(sessionId))
        : ref.watch(submissionsStreamProvider(sessionId, session.currentRound));
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;

    // 관리자 여부 판단 (role이 admin이거나 등록된 관리자 이메일인 경우)
    final currentUserEmail = supabase.auth.currentUser?.email;
    final isAdmin =
        profile?.role == 'admin' || isConfiguredAdminEmail(currentUserEmail);

    return Column(
      children: [
        // ── 라운드 헤더 ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          child: BibleGlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.isSpeedMode
                            ? '전체 진행 현황'
                            : 'ROUND ${session.currentRound} / ${session.totalRounds}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        session.isSpeedMode
                            ? '스피드 레이스 모드'
                            : _statusLabel(session),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                submissionsAsync.when(
                  data: (subs) {
                    final uniqueUsers =
                        subs.map((s) => s.userId).toSet().length;
                    final submittedAll = subs
                        .where((s) =>
                            s.roundNumber == session.totalRounds && s.isFinal)
                        .length;
                    return Column(
                      children: [
                        Text(
                          session.isSpeedMode
                              ? '$submittedAll / $uniqueUsers'
                              : '${subs.where((s) => s.isFinal).length}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: BibleColors.success,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          session.isSpeedMode ? '완주 인원' : '제출 완료',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(
                    color: BibleColors.gold,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // ── 참가자 목록 ──
        Expanded(
          child: submissionsAsync.when(
            data: (submissions) {
              if (submissions.isEmpty) {
                return _buildEmpty();
              }

              if (session.isSpeedMode) {
                return _buildSpeedLeaderboard(submissions, isAdmin);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 116),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submission = submissions[index];
                  final questionAsync = ref.read(currentQuestionStreamProvider(
                      sessionId, session.currentRound));
                  final verseContent =
                      questionAsync.valueOrNull?.verse?.content ?? '';

                  return _LeaderboardTile(
                    rank: index + 1,
                    submission: submission,
                    isRoundActive: session.isRoundActive,
                    verseContent: verseContent,
                    onTap: () {
                      if (isAdmin) {
                        context.push(
                          '/grading?submissionId=${submission.id}&sessionId=$sessionId&roundNumber=${session.currentRound}',
                        );
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BibleColors.panelLight.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: const Text('⏳', style: TextStyle(fontSize: 40)),
        ),
        const Gap(16),
        Text(
          '아직 입력 중인 참가자가 없습니다.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSpeedLeaderboard(List<Submission> submissions, bool isAdmin) {
    // 유저별 데이터 집계
    final userStats = <String, Map<String, dynamic>>{};
    for (final s in submissions) {
      if (!userStats.containsKey(s.userId)) {
        userStats[s.userId] = {
          'profile': s.profile,
          'max_round': 0,
          'total_accuracy': 0.0,
          'completed_count': 0,
          'is_finished': false,
          'last_submission': s,
        };
      }

      final stats = userStats[s.userId]!;
      if (s.isFinal) {
        if (s.roundNumber > stats['max_round']) {
          stats['max_round'] = s.roundNumber;
        }
        stats['total_accuracy'] += s.accuracyScore;
        stats['completed_count'] += 1;
        if (s.roundNumber == session.totalRounds) {
          stats['is_finished'] = true;
        }
      }

      // 최신 정보 유지를 위해 덮어쓰기 (프로필 등)
      if (s.roundNumber >=
          (stats['last_submission'] as Submission).roundNumber) {
        stats['last_submission'] = s;
      }
    }

    final sortedList = userStats.values.toList()
      ..sort((a, b) {
        // 1. 총 정확도 합계 (내림차순)
        final s1 = a['total_accuracy'] as double;
        final s2 = b['total_accuracy'] as double;
        if (s2 != s1) return s2.compareTo(s1);

        // 2. 마지막 제출 시간 (오름차순 - 동일 점수면 먼저 제출한 사람)
        final sub1 = a['last_submission'] as Submission;
        final sub2 = b['last_submission'] as Submission;
        final t1 = sub1.submittedAt ?? sub1.createdAt;
        final t2 = sub2.submittedAt ?? sub2.createdAt;
        return t1.compareTo(t2);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 116),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final stats = sortedList[index];
        final profile = stats['profile'] as Profile?;
        final avgAccuracy = (stats['total_accuracy'] as double) /
            (stats['completed_count'] > 0 ? stats['completed_count'] : 1);

        return _SpeedLeaderboardTile(
          rank: index + 1,
          profile: profile,
          completedRounds: stats['completed_count'],
          totalRounds: session.totalRounds,
          avgAccuracy: avgAccuracy,
          isFinished: stats['is_finished'],
          onTap: isAdmin
              ? () {
                  context.push(
                    '/user-result?sessionId=$sessionId&targetUserId=${profile?.id}',
                  );
                }
              : null,
        );
      },
    );
  }

  String _statusLabel(GameSession s) {
    return switch (s.status) {
      'waiting' => '대기 중',
      'round_active' => s.isPaused ? '일시 정지' : '진행 중 🟢',
      'round_locked' => '라운드 전환 중 🔒',
      'finished' => '게임 종료 🏁',
      _ => '',
    };
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.submission,
    required this.isRoundActive,
    required this.verseContent,
    required this.onTap,
  });
  final int rank;
  final Submission submission;
  final bool isRoundActive;
  final String verseContent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nickname = submission.profile?.nickname ?? '참가자';

    // 진행도 색상
    final progressColor = submission.isFinal
        ? const Color(0xFF1E7D4F)
        : submission.progressRate >= 0.8
            ? const Color(0xFF1E7D4F)
            : submission.progressRate >= 0.4
                ? Colors.amber.shade700
                : Colors.black26;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: submission.isFinal
                    ? const Color(0xFF1E7D4F).withOpacity(0.3)
                    : const Color(0xFFCDD0E3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // 순위
                SizedBox(
                  width: 32,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rank <= 3 ? AppTheme.kNavy : Colors.black26,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Gap(12),

                // 닉네임 + 진행바
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            nickname,
                            style: const TextStyle(
                              color: AppTheme.kNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Gap(8),
                          if (submission.isFinal)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF1E7D4F), size: 16),
                        ],
                      ),
                      const Gap(8),
                      // 입력 진행도 바
                      if (!submission.isFinal && isRoundActive) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: submission.progressRate,
                            backgroundColor: const Color(0xFFDDE2F0),
                            valueColor: AlwaysStoppedAnimation(progressColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(16),

                // 점수/진행도 표시
                if (submission.isFinal)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E7D4F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('최종 정확도',
                            style:
                                TextStyle(color: Colors.black38, fontSize: 9)),
                        Text(
                          '${submission.accuracyScore.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Color(0xFF1E7D4F),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isRoundActive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('실시간 정확도',
                          style: TextStyle(color: Colors.black38, fontSize: 9)),
                      Text(
                        '${AccuracyCalculator.calculate(verseContent, submission.content).toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: AppTheme.kNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      const Gap(2),
                      Text(
                        '진행 ${(submission.progressRate * 100).round()}%',
                        style: const TextStyle(
                            color: Colors.black26, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedLeaderboardTile extends StatelessWidget {
  const _SpeedLeaderboardTile({
    required this.rank,
    required this.profile,
    required this.completedRounds,
    required this.totalRounds,
    required this.avgAccuracy,
    required this.isFinished,
    this.onTap,
  });

  final int rank;
  final Profile? profile;
  final int completedRounds;
  final int totalRounds;
  final double avgAccuracy;
  final bool isFinished;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kSurface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFinished
                    ? const Color(0xFF1E7D4F).withOpacity(0.3)
                    : const Color(0xFFCDD0E3),
                width: isFinished ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rank <= 3 ? AppTheme.kNavy : Colors.black26,
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
                            profile?.nickname ?? '참가자',
                            style: const TextStyle(
                              color: AppTheme.kNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Gap(8),
                          if (isFinished)
                            const Icon(Icons.stars_rounded,
                                color: AppTheme.kGold, size: 18),
                        ],
                      ),
                      const Gap(8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: completedRounds / totalRounds,
                          backgroundColor: const Color(0xFFDDE2F0),
                          valueColor: AlwaysStoppedAnimation(isFinished
                              ? const Color(0xFF1E7D4F)
                              : AppTheme.kNavy),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$completedRounds / $totalRounds',
                      style: const TextStyle(
                        color: AppTheme.kNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '평균 ${avgAccuracy.toStringAsFixed(1)}%',
                      style:
                          const TextStyle(color: Colors.black45, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
