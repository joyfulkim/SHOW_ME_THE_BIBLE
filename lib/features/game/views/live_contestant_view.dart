import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models.dart';
import '../../../shared/accuracy_calculator.dart';
import '../game_provider.dart';
import '../submission_provider.dart';
import '../widgets/game_widgets.dart';

class LiveContestantView extends ConsumerStatefulWidget {
  const LiveContestantView({
    super.key,
    required this.sessionId,
    required this.session,
    this.profile, // Changed to optional as it's not used
  });

  final String sessionId;
  final GameSession session;
  final Profile? profile;

  @override
  ConsumerState<LiveContestantView> createState() => _LiveContestantViewState();
}

class _LiveContestantViewState extends ConsumerState<LiveContestantView> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _autoSaveTimer;
  Timer? _countDownTimer;
  int _secondsRemaining = 0;
  int _lastRound = -1;

  @override
  void initState() {
    super.initState();
    _autoSaveTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _autoSave());
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _countDownTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _autoSave() {
    if (!widget.session.canInput) return;

    final round = widget.session.currentRound;

    // 최종 제출 여부 확인
    final mySub =
        ref.read(mySubmissionProvider(widget.sessionId, round)).valueOrNull;
    if (mySub?.isFinal == true) return;

    final text = _textController.text;
    if (text.isEmpty) return;

    final question = ref
        .read(currentQuestionStreamProvider(widget.sessionId, round))
        .valueOrNull;

    ref.read(submissionControllerProvider.notifier).autoSave(
          sessionId: widget.sessionId,
          roundNumber: round,
          inputText: text,
          answerContent: question?.verse?.content,
        );
  }

  void _resumeTimer(int round) {
    _countDownTimer?.cancel();
    _countDownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 일시 정지 중이면 타이머 감소 중단
      if (widget.session.isPaused) return;

      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _handleTimeUp(round);
      }
    });
  }

  void _handleTimeUp(int round) {
    if (widget.session.canInput) {
      _handleSubmit(widget.session, round);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시간이 종료되어 자동 제출되었습니다.')),
      );
    }
  }

  Future<void> _handleSubmit(GameSession session, int round) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final question =
        await ref.read(currentQuestionProvider(widget.sessionId, round).future);
    if (question?.verse == null) return;

    final accuracy =
        AccuracyCalculator.calculate(question!.verse!.content, text);

    await ref.read(submissionControllerProvider.notifier).submitFinal(
          sessionId: widget.sessionId,
          roundNumber: round,
          inputText: text,
          accuracyScore: accuracy,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = widget.session.currentRound;

    // 라운드 변경 감지 및 초기화
    if (currentRound != _lastRound) {
      _lastRound = currentRound;
      _secondsRemaining = 0; // 초기화
      _countDownTimer?.cancel();
      _countDownTimer = null; // null로 설정하여 다음 구절 로드 시 타이머가 시작되도록 함
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textController.clear();
      });
    }

    // 구절 로드 감지 및 타이머 시작 로직
    ref.listen<AsyncValue<SessionQuestion?>>(
      currentQuestionStreamProvider(widget.sessionId, currentRound),
      (prev, next) {
        final question = next.valueOrNull;
        if (question?.verse != null &&
            _secondsRemaining == 0 &&
            _countDownTimer == null) {
          setState(() {
            _secondsRemaining = (question!.verse!.difficulty * 60);
          });
          _resumeTimer(currentRound);
        }
      },
    );

    if (widget.session.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/result?sessionId=${widget.sessionId}');
      });
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gameSessionStreamProvider(widget.sessionId));
          ref.invalidate(
              currentQuestionStreamProvider(widget.sessionId, currentRound));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: Column(
          children: [
            StatusBanner(
                session: widget.session, secondsRemaining: _secondsRemaining),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    RoundIndicator(
                        current: currentRound,
                        total: widget.session.totalRounds),
                    const Gap(24),
                    CurrentVerse(
                      sessionId: widget.sessionId,
                      roundNumber: currentRound,
                      isLocked: !widget.session.canInput,
                    ),
                    const Gap(24),
                    InputArea(
                      controller: _textController,
                      focusNode: _focusNode,
                      sessionId: widget.sessionId,
                      session: widget.session,
                      currentRound: currentRound,
                      onSubmit: (s) => _handleSubmit(s, currentRound),
                    ),
                    const Gap(124),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
