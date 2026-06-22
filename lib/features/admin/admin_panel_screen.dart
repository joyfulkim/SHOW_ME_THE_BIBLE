import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../shared/models.dart';
import '../game/game_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/ui_utils.dart';
import 'verse_selector_screen.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  bool _isManaging = false; // Dashboard vs Management view toggle

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(gameSessionStreamProvider(widget.sessionId));
    final adminCtrl = ref.watch(adminControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. 관리 모드일 경우 대시보드로 먼저 돌아감
        if (_isManaging) {
          setState(() => _isManaging = false);
          return;
        }

        // 2. 내부 내비게이션 스택이 있다면 이전 화면으로 이동
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        // 3. 최상단 화면일 경우 종료 여부 확인
        final confirmed = await showExitConfirmationDialog(context);
        if (confirmed == true) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('관리자'),
          leading: _isManaging
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.kNavy),
                  onPressed: () {
                    // 앱바의 뒤로가기 버튼도 동일한 로직 수행
                    setState(() => _isManaging = false);
                  },
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.book_outlined, color: AppTheme.kNavy),
              tooltip: '말씀 등록/관리',
              onPressed: () => _showVerseSelector(context, ref, null),
            ),
            IconButton(
              icon:
                  const Icon(Icons.leaderboard_outlined, color: AppTheme.kNavy),
              tooltip: '실시간 리더보드',
              onPressed: () =>
                  context.push('/leaderboard?sessionId=${widget.sessionId}'),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.kNavy),
              tooltip: '로그아웃',
              onPressed: () => _performLogout(context, ref),
            ),
          ],
        ),
        body: sessionAsync.when(
          data: (session) {
            if (session == null) {
              return _buildCreateSession(context, ref, adminCtrl);
            }
            if (!_isManaging) {
              return _buildDashboard(context, theme, ref, session, adminCtrl);
            }
            return _buildSessionControl(
                context, theme, ref, session, adminCtrl);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류: $e')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showVerseSelector(context, ref, null),
          backgroundColor: AppTheme.kNavy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('구절 등록'),
        ),
      ),
    );
  }

  // --- Dashboard (Summary View) ---
  Widget _buildDashboard(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    GameSession session,
    AsyncValue<void> ctrl,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.dashboard_customize_outlined,
                size: 64, color: AppTheme.kNavy),
            const Gap(16),
            const Text(
              '관리 대시보드',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kNavy),
            ),
            const Gap(20),
            _SessionSummaryCard(
              session: session,
              onManage: () => setState(() => _isManaging = true),
            ),
            if (session.isSpeedMode) ...[
              const Gap(20),
              const _ParticipantProgressSummary(),
            ],
            const Gap(12),
            const Text('⚠️ 프로젝트 초기화',
                style: TextStyle(
                    color: Colors.black26,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: ctrl.isLoading
                    ? null
                    : () => _showResetConfirm(context, ref, session.id),
                icon: ctrl.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.redAccent))
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('모든 데이터 삭제 후 초기화'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Create Session View ---
  Widget _buildCreateSession(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<void> ctrl,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.kNavyBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.kNavy.withOpacity(0.2), width: 2),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  size: 40, color: AppTheme.kNavy),
            ),
            const Gap(20),
            Text(
              'SHOW ME THE BIBLE',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.kNavy,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Gap(6),
            const Text('현재 활성화된 프로젝트가 없습니다.',
                style: TextStyle(color: Colors.black45)),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: ctrl.isLoading
                    ? null
                    : () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add_circle_outline),
                label: ctrl.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('새 프로젝트 생성'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Session Management (Round Control) ---
  Widget _buildSessionControl(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    GameSession session,
    AsyncValue<void> ctrl,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _isManaging = false),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('대시보드로 돌아가기'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.kNavy),
            ),
            const Gap(8),
            _SessionStatusCard(session: session, sessionId: widget.sessionId),
            const Gap(16),
            _RoundControlCard(
              session: session,
              sessionId: widget.sessionId,
              ref: ref,
              ctrl: ctrl,
              onSelectVerse: () => _showVerseSelector(context, ref, session),
              onSelectVersesForSpeed: () => _showMultiVerseSelector(
                  context, ref, session, session.totalRounds),
            ),
            const Gap(24),
            if (ctrl.hasError)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '오류: ${ctrl.error}',
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                ),
              ),
            if (session.isFinished) ...[
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.go('/result?sessionId=${widget.sessionId}'),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('최종 결과 보기'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: '새 성경 암송 프로젝트');
    final roundsController = TextEditingController(text: '10');
    bool sttEnabled = true;
    String gameMode = 'live';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('새 프로젝트 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('프로젝트 이름과 라운드 수를 설정해 주세요.',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              const Gap(16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '프로젝트 이름',
                  hintText: '예: 2024 여름 성경학교 암송 대회',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(16),
              TextField(
                controller: roundsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '전체 라운드 수',
                  border: OutlineInputBorder(),
                  suffixText: '라운드',
                ),
              ),
              const Gap(16),
              SwitchListTile(
                title:
                    const Text('음성 인식(STT) 사용', style: TextStyle(fontSize: 14)),
                subtitle: const Text('참가자가 마이크로 입력할 수 있게 허용합니다.',
                    style: TextStyle(fontSize: 12)),
                value: sttEnabled,
                onChanged: (val) => setDialogState(() => sttEnabled = val),
                activeColor: AppTheme.kNavy,
                contentPadding: EdgeInsets.zero,
              ),
              const Gap(16),
              const Text('게임 모드 선택',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kNavy)),
              const Gap(8),
              _ModeSelectionToggle(
                selectedMode: gameMode,
                onChanged: (val) => setDialogState(() => gameMode = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final rounds = int.tryParse(roundsController.text) ?? 10;
                if (title.isEmpty) return;

                Navigator.pop(ctx);
                final newSessionId = await ref
                    .read(adminControllerProvider.notifier)
                    .createSession(rounds, title, sttEnabled, gameMode);

                if (newSessionId != null && context.mounted) {
                  if (gameMode == 'speed') {
                    // 스피드 모드이면 즉시 구절 선택창 띄우기
                    _showMultiVerseSelector(
                        context, ref, null, rounds, newSessionId);
                  } else {
                    context.pushReplacement('/admin?sessionId=$newSessionId');
                  }
                } else if (context.mounted) {
                  // 에러 메시지 가져오기
                  final error = ref.read(adminControllerProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('프로젝트 생성 실패: ${error ?? "알 수 없는 에러"}'),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('생성 시작'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirm(
      BuildContext context, WidgetRef ref, String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로젝트 초기화'),
        content: const Text(
            '현재 프로젝트의 모든 제출 내역과 성경 구절 정보가 삭제됩니다. 정말 처음부터 다시 시작하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('초기화 실행', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. 초기화 작업 수행
      await ref.read(adminControllerProvider.notifier).resetSession(sessionId);

      // 2. 결과 확인
      final adminState = ref.read(adminControllerProvider);

      if (adminState.hasError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('초기화 실패: ${adminState.error}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        if (context.mounted) {
          setState(() => _isManaging = false);
          // 세션이 삭제되었으므로 URL에서 sessionId를 제거하고 화면을 새로고침하기 위해 리다이렉트
          context.go('/admin');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로젝트가 초기화되었습니다.')),
          );
        }
      }
    }
  }

  void _performLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }

  void _showMultiVerseSelector(BuildContext context, WidgetRef ref,
      GameSession? session, int requiredCount,
      [String? manualSessionId]) {
    final targetSessionId = manualSessionId ?? widget.sessionId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // 강제 선택 유도
      enableDrag: false,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => VerseSelectorScreen(
          sessionId: targetSessionId,
          isMultiSelect: true,
          requiredCount: requiredCount,
          onVersesSelected: (verses) async {
            Navigator.of(ctx).pop();
            final verseIds = verses.map((v) => v.id).toList();
            await ref
                .read(adminControllerProvider.notifier)
                .preAssignVerses(targetSessionId, verseIds);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${verses.length}개의 구절이 등록되었습니다.')),
              );
              if (manualSessionId != null) {
                // 프로젝트 생성 단계에서 온 경우 관리 패널로 이동
                context.pushReplacement('/admin?sessionId=$manualSessionId');
              }
            }
          },
        ),
      ),
    );
  }

  void _showVerseSelector(
      BuildContext context, WidgetRef ref, GameSession? session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 투명으로 변경하여 내부의 흰색 배경과 조화
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => VerseSelectorScreen(
          sessionId: widget.sessionId, // sessionId 전달 추가
          onVerseSelected: (verse) async {
            if (session == null) {
              Navigator.of(ctx).pop();
              return;
            }
            Navigator.of(ctx).pop();
            await ref
                .read(adminControllerProvider.notifier)
                .activateRound(widget.sessionId, verse.id);
          },
        ),
      ),
    );
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session, required this.onManage});
  final GameSession session;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCDD0E3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.kNavyBg,
                borderRadius: BorderRadius.circular(10)),
            child: const Text('현재 프로젝트 진행 현황',
                style: TextStyle(
                    color: AppTheme.kNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const Gap(20),
          Text(
            session.isSpeedMode
                ? '스피드 레이스 모드'
                : '${session.currentRound} / ${session.totalRounds} ROUND',
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.kNavy),
          ),
          const Gap(8),
          Text(
            _statusText(session),
            style: TextStyle(
                color: Colors.green.shade700, fontWeight: FontWeight.w600),
          ),
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onManage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kNavy,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('⚙️  프로젝트 관리하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(GameSession s) {
    return switch (s.status) {
      'waiting' => '입장 대기 중...',
      'round_active' => '말씀 입력 진행 중!',
      'round_locked' => '다음 라운드 준비 중',
      'finished' => '모든 라운드 종료',
      _ => '상태 확인 중',
    };
  }
}

class _SessionStatusCard extends ConsumerWidget {
  const _SessionStatusCard({required this.session, required this.sessionId});
  final GameSession session;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon, label) = switch (session.status) {
      'waiting' => (Colors.blue, '⏳', '대기 중'),
      'round_active' => session.isPaused
          ? (Colors.amber, '⏸️', '일시 정지')
          : (Colors.green, '🟢', '진행 중'),
      'round_locked' => (Colors.orange, '🔒', '전환 중'),
      'finished' => (Colors.purple, '🏁', '종료'),
      _ => (Colors.grey, '❓', '알 수 없음'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('진행 정보',
                  style: TextStyle(color: Colors.black38, fontSize: 12)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$icon $label',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ],
          ),
          const Gap(4),
          Text(session.title ?? '성경 프로젝트',
              style: const TextStyle(
                  color: AppTheme.kNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const Gap(12),
          Row(
            children: [
              _StatChip(
                  label: '게임 모드', value: session.isLiveMode ? '실시간' : '스피드'),
              const Gap(8),
              _StatChip(
                  label: session.isFinished ? '완료 라운드' : '현재 라운드',
                  value: '${session.currentRound} / ${session.totalRounds}'),
              const Gap(8),
              _StatChip(label: '진행율', value: _calculateProgress(ref)),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateProgress(WidgetRef ref) {
    if (session.isFinished) return '100%';
    if (session.isWaiting && session.startedAt == null) return '0%';

    if (session.isSpeedMode) {
      final submissions =
          ref.watch(allSubmissionsStreamProvider(sessionId)).valueOrNull ?? [];
      final uniqueUsers = submissions.map((s) => s.userId).toSet().length;
      if (uniqueUsers == 0) return '0%';

      final totalPossible = uniqueUsers * session.totalRounds;
      final totalCompleted = submissions.where((s) => s.isFinal).length;
      return '${((totalCompleted / totalPossible) * 100).round()}%';
    } else {
      return '${((session.currentRound / session.totalRounds) * 100).round()}%';
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.kNavyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCDD0E3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppTheme.kNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Gap(2),
          Text(label,
              style: const TextStyle(color: Colors.black45, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RoundControlCard extends ConsumerWidget {
  const _RoundControlCard({
    required this.session,
    required this.sessionId,
    required this.ref,
    required this.ctrl,
    required this.onSelectVerse,
    required this.onSelectVersesForSpeed,
  });
  final GameSession session;
  final String sessionId;
  final WidgetRef ref;
  final AsyncValue<void> ctrl;
  final VoidCallback onSelectVerse;
  final VoidCallback onSelectVersesForSpeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentQuestionAsync = ref
        .watch(currentQuestionStreamProvider(sessionId, session.currentRound));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDD0E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('라운드 제어',
              style: TextStyle(
                  color: AppTheme.kNavy,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const Gap(16),

          // ─ 구절 정보 표시 ─
          if (session.isRoundActive || session.isRoundLocked)
            if (session.isSpeedMode)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.kGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.kGold.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: AppTheme.kGold),
                    Gap(12),
                    Expanded(
                      child: Text(
                        '스피드 레이스 진행 중\n참가자들이 각자의 속도로 구절을 암송하고 있습니다.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.kNavy,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              currentQuestionAsync.when(
                data: (question) {
                  if (question?.verse == null) return const SizedBox.shrink();
                  final v = question!.verse!;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.kNavyBg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.kNavy.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.menu_book,
                                size: 16, color: AppTheme.kNavy),
                            const Gap(8),
                            Text(
                              '현재 라운드 구절: ${v.reference}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.kNavy),
                            ),
                          ],
                        ),
                        const Gap(8),
                        Text(
                          v.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

          if (session.isWaiting && session.startedAt == null) ...[
            if (session.isSpeedMode) ...[
              _ActionButton(
                label: '📚  스피드 레이스 구절 전체 등록',
                subtitle: '대회 시작 전 모든 문제를 미리 선택하세요',
                color: AppTheme.kGold,
                isLoading: ctrl.isLoading,
                onTap: onSelectVersesForSpeed,
              ),
              const Gap(12),
            ],
            _ActionButton(
              label: '🚀  게임 시작 (참가자 대기)',
              subtitle: session.isSpeedMode
                  ? '모든 구절 등록 후 시작 버튼을 눌러주세요'
                  : '모든 참가자가 접속하면 버튼을 눌러주세요',
              color: const Color(0xFF1E7D4F),
              isLoading: ctrl.isLoading,
              onTap: () => ref
                  .read(adminControllerProvider.notifier)
                  .startSession(sessionId),
            ),
          ] else if (session.isRoundActive &&
              !session.isFinished &&
              session.isSpeedMode) ...[
            _ActionButton(
              label: '📊  실시간 리더보드 확인',
              subtitle: '참가자들의 스피드 레이스 진행 현황을 확인하세요',
              color: AppTheme.kGold,
              isLoading: false,
              onTap: () => context.push('/leaderboard?sessionId=$sessionId'),
            ),
            const Gap(12),
            _ActionButton(
              label: '🏁  스피드 레이스 종료하기',
              subtitle: '모든 참가자가 완료했다면 레이스를 종료하세요',
              color: Colors.redAccent,
              isLoading: ctrl.isLoading,
              onTap: () => ref
                  .read(adminControllerProvider.notifier)
                  .endSession(sessionId),
            ),
          ] else if (session.isRoundActive &&
              !session.isFinished &&
              !session.isSpeedMode) ...[
            _ActionButton(
              label: '⏩  라운드 종료 및 다음 단계로',
              subtitle: '현재 입력 중인 답안이 즉시 확정됩니다',
              color: Colors.orange.shade700,
              isLoading: ctrl.isLoading,
              onTap: () => ref
                  .read(adminControllerProvider.notifier)
                  .advanceRound(sessionId),
            ),
          ] else if ((session.isRoundLocked ||
                  (session.isWaiting && session.startedAt != null)) &&
              !session.isSpeedMode) ...[
            _ActionButton(
              label: '📖  이번 라운드 구절 선택하기',
              subtitle: '참가자들에게 표시될 성경 구절을 선택하세요',
              color: AppTheme.kNavy,
              isLoading: ctrl.isLoading,
              onTap: onSelectVerse,
            ),
          ],
          if (session.isFinished) ...[
            if (!session.gradingCompleted) ...[
              const Gap(16),
              _ActionButton(
                label: '✅  최종 채점 완료 및 결과 공개',
                subtitle: '모든 참가자의 수동 채점을 마쳤다면 버튼을 눌러주세요',
                color: const Color(0xFF1E7D4F),
                isLoading: ctrl.isLoading,
                onTap: () => ref
                    .read(adminControllerProvider.notifier)
                    .completeGrading(sessionId),
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('🏁 모든 채점과 게임이 종료되었습니다.',
                      style: TextStyle(
                          color: Colors.black38, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null) ...[
          Text(subtitle!,
              style: const TextStyle(color: Colors.black45, fontSize: 12)),
          const Gap(8),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _ModeSelectionToggle extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onChanged;

  const _ModeSelectionToggle({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildOption('live', '실시간 모드', Icons.timer_outlined),
          _buildOption('speed', '스피드 레이스', Icons.bolt_rounded),
        ],
      ),
    );
  }

  Widget _buildOption(String mode, String label, IconData icon) {
    final isSelected = selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.kNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppTheme.kNavy.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: isSelected ? Colors.white : Colors.black45),
              const Gap(8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black45,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantProgressSummary extends ConsumerWidget {
  const _ParticipantProgressSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId =
        (context.findAncestorWidgetOfExactType<AdminPanelScreen>())?.sessionId;
    if (sessionId == null) return const SizedBox.shrink();

    final sessionAsync = ref.watch(gameSessionStreamProvider(sessionId));
    final submissionsAsync = ref.watch(allSubmissionsStreamProvider(sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) return const SizedBox.shrink();

        return submissionsAsync.when(
          data: (subs) {
            final uniqueUsers = subs.map((s) => s.userId).toSet().length;
            final finishedCount = subs
                .where((s) => s.roundNumber == session.totalRounds && s.isFinal)
                .length;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCDD0E3)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.people_alt_outlined,
                          size: 18, color: AppTheme.kNavy),
                      Gap(8),
                      Text('참가자 실시간 현황',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.kNavy)),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: '총 참가 인원', value: '$uniqueUsers명'),
                      _StatItem(
                          label: '최종 완주자',
                          value: '$finishedCount명',
                          valueColor: const Color(0xFF1E7D4F)),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.kNavy)),
        const Gap(4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black45)),
      ],
    );
  }
}
