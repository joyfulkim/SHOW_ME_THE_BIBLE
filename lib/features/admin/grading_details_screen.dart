import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../shared/accuracy_calculator.dart';
import '../../shared/models.dart';
import '../game/game_provider.dart';

class GradingDetailsScreen extends ConsumerWidget {
  const GradingDetailsScreen({
    super.key,
    required this.submissionId,
    required this.sessionId,
    required this.roundNumber,
  });

  final int submissionId;
  final String sessionId;
  final int roundNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 세션 및 구절 정보 가져오기
    final questionAsync = ref.watch(currentQuestionStreamProvider(sessionId, roundNumber));
    
    // 이 현황 리스트에서 해당 제출물 찾기 (실시간 스트림 활용)
    final submissionsAsync = ref.watch(submissionsStreamProvider(sessionId, roundNumber));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('상세 채점 및 비교'),
      ),
      body: submissionsAsync.when(
        data: (subs) {
          final submission = subs.firstWhere(
            (s) => s.id == submissionId,
            orElse: () => throw Exception('제출 정보를 찾을 수 없습니다.'),
          );

          return questionAsync.when(
            data: (question) {
              final original = question?.verse?.content ?? '';
              return _GradingBody(
                submission: submission,
                originalText: original,
                sessionId: sessionId,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('구절 로드시 오류: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('제출 정보 로드시 오류: $e')),
      ),
    );
  }
}

class _GradingBody extends ConsumerStatefulWidget {
  const _GradingBody({
    required this.submission,
    required this.originalText,
    required this.sessionId,
  });

  final Submission submission;
  final String originalText;
  final String sessionId;

  @override
  ConsumerState<_GradingBody> createState() => _GradingBodyState();
}

class _GradingBodyState extends ConsumerState<_GradingBody> {
  late double _customScore;

  @override
  void initState() {
    super.initState();
    _customScore = widget.submission.accuracyScore;
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 상단 프로필 요약 ──
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.kNavyBg,
                child: Text(
                  widget.submission.profile?.nickname.characters.first ?? '?',
                  style: const TextStyle(color: AppTheme.kNavy, fontWeight: FontWeight.bold),
                ),
              ),
              const Gap(12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.submission.profile?.nickname ?? '참가자',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.kNavy),
                  ),
                  Text(
                    '제출 일시: ${widget.submission.createdAt.toLocal().toString().substring(0, 19)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.kNavy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  () {
                    final isFinal = widget.submission.isFinal;
                    var score = widget.submission.accuracyScore;

                    if (!isFinal && score == 0.0 && widget.submission.content.isNotEmpty) {
                      score = AccuracyCalculator.calculate(widget.originalText, widget.submission.content);
                      return '실시간 정확도: ${score.toStringAsFixed(1)}%';
                    }
                    
                    return isFinal ? '최종 점수: ${score.toStringAsFixed(1)}%' : '현재 정확도: ${score.toStringAsFixed(1)}%';
                  }(),
                  style: const TextStyle(color: AppTheme.kNavy, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const Gap(32),

          // ── 원본 구절 ──
          const _SectionHeader(icon: Icons.menu_book, title: '성경 원본 (정답)'),
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Text(
              widget.originalText,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ),
          const Gap(32),

          // ── 참가자 제출 (Diff 강조) ──
          const _SectionHeader(icon: Icons.edit_note, title: '참가자 제출 답안 (비교)'),
          const Gap(12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.kNavyBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCDD0E3)),
            ),
            child: _buildDiffText(widget.originalText, widget.submission.content),
          ),
          const Gap(40),

          // ── 채점 액션 ──
          const Divider(),
          const Gap(24),
          const Text('⚖️ 최종 판정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.kNavy)),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _ScoreButton(
                  label: '틀림 (0점)',
                  color: Colors.red.shade400,
                  onPressed: () => _updateScore(0),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _ScoreButton(
                  label: '정답 (100점)',
                  color: const Color(0xFF1E7D4F),
                  onPressed: () => _updateScore(100),
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              const Text('수동 점수 설정:', style: TextStyle(color: Colors.black54)),
              const Gap(12),
              Expanded(
                child: Slider(
                  value: _customScore,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: AppTheme.kNavy,
                  label: '${_customScore.round()}',
                  onChanged: (v) => setState(() => _customScore = v),
                ),
              ),
              const Gap(12),
              Text('${_customScore.round()}점', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _updateScore(_customScore.round().toDouble()),
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.kNavy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 간단한 단어 단위 Diff 하이라이트 구현
  Widget _buildDiffText(String original, String input) {
    if (input.isEmpty) {
      return const Text('(내용 없음)', style: TextStyle(color: Colors.black26, fontStyle: FontStyle.italic));
    }

    final inputWords = input.split(' ');
    final List<TextSpan> spans = [];

    // 매우 단순한 비교 로직 (더 정교하게 하려면 diff_match_patch 같은 라이브러리 필요)
    for (int i = 0; i < inputWords.length; i++) {
      final word = inputWords[i];
      bool matchFound = false;
      
      // 원본에 해당 단어가 포함되어 있는지 확인 (순서 무관 단순 포함 확인은 한계가 있으나 가시성 제공)
      if (original.contains(word) && word.length > 1) {
        matchFound = true;
      }

      spans.add(TextSpan(
        text: '$word ',
        style: TextStyle(
          color: matchFound ? Colors.black87 : Colors.red,
          fontWeight: matchFound ? FontWeight.normal : FontWeight.bold,
          decoration: matchFound ? null : TextDecoration.underline,
          fontSize: 16,
          height: 1.6,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _updateScore(double score) async {
    try {
      await ref.read(adminControllerProvider.notifier).updateSubmissionScore(widget.submission.id, score);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('점수가 ${score.round()}점으로 반영되었습니다.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.kNavy.withOpacity(0.6)),
        const Gap(8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({required this.label, required this.color, required this.onPressed});
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
