import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_shell.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/game/game_provider.dart';
import '../../main.dart';
import '../../shared/models.dart';

class UserResultDetailScreen extends ConsumerWidget {
  const UserResultDetailScreen({
    super.key,
    required this.sessionId,
    required this.targetUserId,
  });

  final String sessionId;
  final String targetUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final submissionsAsync =
        ref.watch(userSubmissionsProvider(sessionId, targetUserId));

    return BiblePageFrame(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: BibleTopBar(
                title: '상세 결과',
                leading: BibleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: '뒤로',
                  onTap: () => context.pop(),
                ),
              ),
            ),
            Expanded(
              child: submissionsAsync.when(
                data: (submissions) {
                  if (submissions.isEmpty) {
                    return const Center(
                      child: Text(
                        '제출 내역이 없습니다.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final profileAsync = ref.watch(currentProfileProvider);
                  final profile = profileAsync.valueOrNull;
                  final isAdmin = profile?.role == 'admin';

                  final totalScore = submissions.fold<double>(
                      0, (prev, s) => prev + s.accuracyScore);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: _buildUserSummary(
                          theme,
                          profile,
                          totalScore,
                          submissions.length,
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                          itemCount: submissions.length,
                          separatorBuilder: (_, __) => const Gap(16),
                          itemBuilder: (context, index) {
                            return _RoundResultCard(
                              submission: submissions[index],
                              isAdmin: isAdmin,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: BibleColors.gold),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '오류 발생: $e',
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

  Widget _buildUserSummary(
      ThemeData theme, Profile? profile, double total, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BibleColors.cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BibleColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.kNavy,
            child: Text(
              (profile?.nickname ?? '?').characters.firstOrNull ?? '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.nickname ?? '알 수 없음',
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.kNavy, fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                Text(
                  '총 $count개 라운드 참여',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('최종 합계',
                  style: TextStyle(color: Colors.black38, fontSize: 11)),
              Text(
                '${total.toStringAsFixed(1)}점',
                style: const TextStyle(
                  color: AppTheme.kNavy,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundResultCard extends ConsumerWidget {
  const _RoundResultCard({required this.submission, required this.isAdmin});
  final Submission submission;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: isAdmin
          ? () {
              context.push(
                  '/grading?submissionId=${submission.id}&sessionId=${submission.sessionId}&roundNumber=${submission.roundNumber}');
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCDD0E3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.kNavy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ROUND ${submission.roundNumber}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${submission.accuracyScore.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF1E7D4F),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Gap(16),
            _VerseContent(
                sessionId: submission.sessionId,
                roundNumber: submission.roundNumber),
            const Gap(12),
            const Text('내 입력 내역:',
                style: TextStyle(color: Colors.black38, fontSize: 12)),
            const Gap(6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Text(
                submission.content.isEmpty ? '(데이터 없음)' : submission.content,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseContent extends ConsumerWidget {
  const _VerseContent({required this.sessionId, required this.roundNumber});
  final String sessionId;
  final int roundNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync =
        ref.watch(currentQuestionProvider(sessionId, roundNumber));

    return questionAsync.when(
      data: (question) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question?.verse?.reference ?? '구절 정보 없음',
            style: const TextStyle(
                color: AppTheme.kNavy,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const Gap(4),
          Text(
            question?.verse?.content ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
        ],
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
