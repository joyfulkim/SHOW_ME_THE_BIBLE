import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:show_me_bible/core/app_shell.dart';
import 'package:show_me_bible/shared/models.dart';
import 'package:show_me_bible/features/game/game_provider.dart';
import 'package:show_me_bible/features/auth/auth_provider.dart';

import 'views/live_contestant_view.dart';
import 'views/speed_contestant_view.dart';

class ContestantScreen extends ConsumerWidget {
  const ContestantScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(gameSessionStreamProvider(sessionId));
    final profileAsync = ref.watch(currentProfileProvider);

    // 세션이 삭제되었거나 상태가 변경된 경우 처리
    ref.listen<AsyncValue<GameSession?>>(
      gameSessionStreamProvider(sessionId),
      (prev, next) {
        final nextSession = next.valueOrNull;

        if (next is AsyncData && nextSession == null) {
          if (context.mounted) {
            context.go('/mode-selection');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('진행 중인 세션이 종료되었거나 초기화되었습니다.')),
            );
          }
        }
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('나가기 확인'),
            content: const Text('현재 진행 중인 성경 암송 세션에서 나가시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('나가기',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          context.go('/mode-selection');
        }
      },
      child: BiblePageFrame(
        bottomNavigationBar: BibleBottomNav(
          active: 'practice',
          onHome: () =>
              _confirmLeave(context, () => context.go('/mode-selection')),
          onPractice: () {},
          onRanking: () => context.push('/leaderboard?sessionId=$sessionId'),
          onSettings: () => context.push('/settings'),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                child: BibleTopBar(
                  title: profileAsync.when(
                    data: (profile) => profile?.nickname ?? 'R_BIBLE',
                    loading: () => '로드 중',
                    error: (_, __) => 'R_BIBLE',
                  ),
                  sideWidth: 116,
                  leading: BibleIconButton(
                    icon: Icons.home_outlined,
                    tooltip: '홈으로',
                    onTap: () => _confirmLeave(
                        context, () => context.go('/mode-selection')),
                  ),
                  actions: [
                    BibleIconButton(
                      icon: Icons.leaderboard_outlined,
                      tooltip: '실시간 현황',
                      onTap: () =>
                          context.push('/leaderboard?sessionId=$sessionId'),
                    ),
                    BibleIconButton(
                      icon: Icons.logout_rounded,
                      tooltip: '로그아웃',
                      color: BibleColors.gold,
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('로그아웃'),
                            content: const Text('정말 로그아웃 하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  '로그아웃',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: sessionAsync.when(
                  data: (session) {
                    if (session == null) {
                      return _buildSessionEndedView(context);
                    }

                    final profile = profileAsync.valueOrNull;

                    if (session.isSpeedMode) {
                      return SpeedContestantView(
                        sessionId: sessionId,
                        session: session,
                        profile: profile,
                      );
                    } else {
                      return LiveContestantView(
                        sessionId: sessionId,
                        session: session,
                        profile: profile,
                      );
                    }
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
      ),
    );
  }

  Future<void> _confirmLeave(
      BuildContext context, VoidCallback onConfirmed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('홈으로 이동'),
        content: const Text('현재 대회를 나가고 홈 화면으로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('이동', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onConfirmed();
    }
  }

  Widget _buildSessionEndedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: BibleColors.gold),
            const Gap(24),
            const Text(
              '세션이 종료되었거나\n삭제되었습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Gap(12),
            const Text(
              '관리자가 프로젝트를 초기화했거나\n대회가 완료되었습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const Gap(40),
            ElevatedButton(
              onPressed: () => context.go('/mode-selection'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
