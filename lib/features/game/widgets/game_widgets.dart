import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/models.dart';
import '../../../shared/secure_text_field.dart';
import '../../../core/app_shell.dart';
import '../game_provider.dart';
import '../submission_provider.dart';
import '../../../core/services/stt_service.dart';

// ── 상태 배너 ──
class StatusBanner extends StatelessWidget {
  const StatusBanner(
      {super.key, required this.session, required this.secondsRemaining});
  final GameSession session;
  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon, label) = switch (session.status) {
      'waiting' => (Colors.white, BibleColors.panelLight, '⏳', '대기 중...'),
      'round_active' => session.isPaused
          ? (Colors.white, Colors.orange.shade700, '⏸️', '일시 정지')
          : (
              Colors.white,
              const Color(0xFF1E7D4F),
              session.isSpeedMode ? '⚡' : '🟢',
              session.isSpeedMode ? '스피드 레이스 진행 중' : '입력 가능'
            ),
      'round_locked' => (
          Colors.white,
          const Color(0xFFB45309),
          '🔒',
          '라운드 전환 중'
        ),
      'finished' => (Colors.white, BibleColors.panel, '🏁', '게임 종료'),
      _ => (Colors.white, Colors.grey.shade600, '❓', '알 수 없음'),
    };

    String timeStr = "";
    if (session.isRoundActive && !session.isFinished) {
      final mins = secondsRemaining ~/ 60;
      final secs = secondsRemaining % 60;
      timeStr =
          " | ⏱️ ${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: BibleColors.panelLine.withValues(alpha: 0.4)),
          bottom:
              BorderSide(color: BibleColors.panelLine.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const Gap(6),
          Text(
            "$label$timeStr",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 라운드 인디케이터 ──
class RoundIndicator extends StatelessWidget {
  const RoundIndicator({super.key, required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ROUND $current / $total',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${((current / total) * 100).round()}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Gap(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            valueColor: const AlwaysStoppedAnimation(BibleColors.gold),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ── 현재 구절 표시 ──
class CurrentVerse extends ConsumerWidget {
  const CurrentVerse({
    super.key,
    required this.sessionId,
    required this.roundNumber,
    required this.isLocked,
  });
  final String sessionId;
  final int roundNumber;
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(gameSessionStreamProvider(sessionId));
    final isSpeedMode = sessionAsync.valueOrNull?.isSpeedMode ?? false;

    final questionAsync =
        ref.watch(currentQuestionStreamProvider(sessionId, roundNumber));

    return questionAsync.when(
      data: (question) {
        if (question == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BibleColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCDD0E3)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BibleColors.gold,
                  ),
                  const Gap(16),
                  Text(
                    isSpeedMode
                        ? '게임이 곧 시작됩니다. 잠시만 기다려 주세요...'
                        : '관리자가 구절을 선택하고 있습니다...',
                    style: const TextStyle(color: BibleColors.ink),
                  ),
                ],
              ),
            ),
          );
        }

        final verse = question.verse;
        if (verse == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: BibleColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BibleColors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: BibleColors.gold,
                  ),
                  const Gap(20),
                  Text(
                    roundNumber > 1
                        ? '다음 구절을 준비하고 있습니다...'
                        : '구절 정보를 불러오는 중...',
                    style: const TextStyle(
                      color: BibleColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: BibleColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCDD0E3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (verse.theme != null && verse.theme!.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BibleColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BibleColors.navy.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.label_outline,
                        size: 14,
                        color: BibleColors.ink,
                      ),
                      const Gap(6),
                      Text(
                        '주제: ${verse.theme}',
                        style: const TextStyle(
                          color: BibleColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      verse.reference,
                      style: const TextStyle(
                        color: BibleColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (isLocked)
                    const Icon(Icons.lock_outline,
                        color: Colors.orange, size: 22)
                  else
                    const Icon(
                      Icons.menu_book_outlined,
                      color: BibleColors.ink,
                      size: 22,
                    ),
                ],
              ),
              const Gap(14),
              const Divider(height: 1),
              const Gap(14),
              Row(
                children: [
                  const Icon(Icons.edit_note, size: 14, color: Colors.black38),
                  const Gap(6),
                  const Text(
                    '위 구절의 내용을 아래 입력창에 작성하세요.',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

// ── 입력 영역 ──
class InputArea extends ConsumerWidget {
  const InputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sessionId,
    required this.session,
    required this.currentRound,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String sessionId;
  final GameSession session;
  final int currentRound;
  final Future<void> Function(GameSession) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final submissionState = ref.watch(submissionControllerProvider);
    final mySubmission = ref.watch(
      mySubmissionProvider(sessionId, currentRound),
    );

    // 최종 제출 완료 시 잠금
    final isSubmitted = mySubmission.valueOrNull?.isFinal ?? false;
    final canInput = session.canInput && !isSubmitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '내 답안',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (canInput && session.sttEnabled)
              MicButton(
                onResult: (text) {
                  controller.text = text;
                },
              ),
          ],
        ),
        const Gap(8),

        // 텍스트 입력
        SecureTextField(
          controller: controller,
          focusNode: focusNode,
          hintText: canInput
              ? '성경 구절을 암송하여 입력하세요...'
              : isSubmitted
                  ? '최종 제출이 완료되었습니다.'
                  : '현재 입력할 수 없습니다.',
          enabled: canInput,
        ),
        const Gap(12),

        // 제출 버튼
        if (!isSubmitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (canInput && !submissionState.isLoading)
                  ? () => onSubmit(session)
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: BibleColors.gold,
                foregroundColor: BibleColors.ink,
              ),
              child: submissionState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('✅ 제출'),
            ),
          ),
      ],
    );
  }
}

class MicButton extends ConsumerWidget {
  const MicButton({super.key, required this.onResult});
  final Function(String) onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening = ref.watch(sttControllerProvider);

    return InkWell(
      onTap: () async {
        if (isListening) {
          await ref.read(sttControllerProvider.notifier).stopListening();
        } else {
          // 마이크 권한 체크
          final status = await Permission.microphone.status;
          if (status.isPermanentlyDenied) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('마이크 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.'),
                  action: SnackBarAction(
                    label: '설정',
                    onPressed: openAppSettings,
                  ),
                ),
              );
            }
            return;
          }

          await ref.read(sttControllerProvider.notifier).startListening(
                onResult: onResult,
              );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isListening
              ? BibleColors.danger.withValues(alpha: 0.14)
              : BibleColors.panelLight.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isListening
                ? BibleColors.danger.withValues(alpha: 0.55)
                : BibleColors.panelLine.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListening ? Icons.mic : Icons.mic_none,
              size: 16,
              color: isListening ? BibleColors.danger : BibleColors.gold,
            ),
            const Gap(6),
            Text(
              isListening ? '듣고 있어요...' : '음성 입력',
              style: TextStyle(
                fontSize: 12,
                color: isListening ? BibleColors.danger : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
