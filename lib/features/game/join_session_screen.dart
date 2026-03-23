import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui_utils.dart';
import '../../main.dart';
import '../../shared/models.dart';
import '../auth/auth_provider.dart';
import 'game_provider.dart';

class JoinSessionScreen extends ConsumerWidget {
  const JoinSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final sessionAsync = ref.watch(latestActiveSessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // 1. 내부 내비게이션 스택이 있다면 이전 화면으로 이동
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        // 2. 최상단 화면일 경우 두 번 눌러 종료 처리
        await handleDoubleTapExit(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: profileAsync.when(
            data: (profile) => Text(profile?.nickname ?? 'R_BIBLE'),
            loading: () => const Text('로드 중...'),
            error: (_, __) => const Text('R_BIBLE'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, color: AppTheme.kNavy),
              onPressed: () => context.go('/mode-selection'),
              tooltip: '홈으로 이동',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.kNavy),
              onPressed: () => _performLogout(context, ref),
              tooltip: '로그아웃',
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 64, color: AppTheme.kNavy),
                const Gap(16),
                const Text(
                  '프로젝트 참 여',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNavy,
                    letterSpacing: 2,
                  ),
                ),
                const Gap(40),
                sessionAsync.when(
                  data: (session) {
                    if (session == null) {
                      return _buildNoActiveSession(context, ref);
                    }
                    return _buildSessionCard(context, session);
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('오류 발생: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoActiveSession(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Text(
          '현재 진행 중인 프로젝트가 없습니다.',
          style: TextStyle(color: Colors.black54),
        ),
        const Gap(24),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(latestActiveSessionProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('새로고침'),
        ),
      ],
    );
  }

  Widget _buildSessionCard(BuildContext context, GameSession session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.kNavy.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.kNavyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '진행 중인 프로젝트',
              style: TextStyle(
                color: AppTheme.kNavy,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(20),
          Text(
            session.title ?? '성경 암송 프로젝트',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.kNavy,
            ),
          ),
          const Gap(12),
          Text(
            '총 ${session.totalRounds}라운드 중 ${session.currentRound}라운드 진행 중',
            style: const TextStyle(color: Colors.black45),
          ),
          const Gap(32),
          ElevatedButton(
            onPressed: () {
              if (session.status == 'finished') {
                context.go('/result?sessionId=${session.id}');
              } else {
                context.go('/game?sessionId=${session.id}');
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              backgroundColor: session.status == 'finished' ? Colors.grey.shade700 : null,
            ),
            child: Text(
              session.status == 'finished' ? '종료된 대회 결과 보기' : '입장하여 참여하기',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }
}
