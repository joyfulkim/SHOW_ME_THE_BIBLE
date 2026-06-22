import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_shell.dart';
import '../../core/services/stt_service.dart';
import '../../shared/accuracy_calculator.dart';
import 'practice_verse.dart';
import '../game/widgets/game_widgets.dart';
import '../settings/settings_provider.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  final PracticeVerse verse;
  const PracticeSessionScreen({super.key, required this.verse});

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  final _inputCtrl = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  double _accuracy = 0.0;
  bool _isChecked = false;
  bool _showVerseContent = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    // Only set up handlers here. Voice and rate are applied in _speak for real-time updates.

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    unawaited(ref.read(sttControllerProvider.notifier).stopListening());
    _flutterTts.stop();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      if (widget.verse.content.isNotEmpty) {
        // Wait for settings to be fully loaded
        try {
          final ttsSettings = await ref.read(ttsSettingsProvider.future);
          final selectedVoice = ttsSettings.voiceName;
          final selectedLocale = ttsSettings.locale ?? "ko-KR";
          final speechRate = ttsSettings.speechRate;

          await _flutterTts.setLanguage(selectedLocale);
          if (selectedVoice != null) {
            await _flutterTts
                .setVoice({"name": selectedVoice, "locale": selectedLocale});
          }
          await _flutterTts.setSpeechRate(speechRate);
        } catch (e) {
          debugPrint("Failed to load TTS settings: $e");
          await _flutterTts.setLanguage("ko-KR");
          await _flutterTts.setSpeechRate(0.5);
        }

        await _flutterTts.speak(widget.verse.content);
      }
    }
  }

  void _checkAccuracy() {
    final original = widget.verse.content;
    final input = _inputCtrl.text;

    final score = AccuracyCalculator.calculate(original, input);

    setState(() {
      _accuracy = score;
      _isChecked = true;
    });
  }

  void _setSpeechInput(String text) {
    _inputCtrl.text = text;
    _inputCtrl.selection = TextSelection.collapsed(offset: text.length);
    if (_isChecked) {
      setState(() => _isChecked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BiblePageFrame(
      bottomNavigationBar: BibleBottomNav(
        active: 'practice',
        onHome: () => context.go('/mode-selection'),
        onPractice: () => context.go('/practice-lobby'),
        onRanking: () => context.push('/login'),
        onSettings: () => context.push('/settings'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: BibleTopBar(
                title: '암송 연습',
                sideWidth: 116,
                leading: BibleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: '목록으로',
                  onTap: () => context.pop(),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(
                      Icons.mic_none_rounded,
                      color: BibleColors.gold,
                      size: 20,
                    ),
                    label: const Text(
                      '음성설정',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 116),
                child: Column(
                  children: [
                    BibleCreamCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Gap(48),
                              Expanded(
                                child: Text(
                                  widget.verse.reference,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: BibleColors.ink,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _speak,
                                    icon: Icon(
                                      _isSpeaking
                                          ? Icons.stop_circle_rounded
                                          : Icons.volume_up_rounded,
                                      color: _isSpeaking
                                          ? BibleColors.danger
                                          : BibleColors.ink,
                                    ),
                                    tooltip: _isSpeaking ? '중지' : '읽어주기',
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() =>
                                        _showVerseContent = !_showVerseContent),
                                    icon: Icon(
                                      _showVerseContent
                                          ? Icons.menu_book_rounded
                                          : Icons.menu_book_outlined,
                                      color: BibleColors.ink,
                                    ),
                                    tooltip:
                                        _showVerseContent ? '본문 숨기기' : '본문 보기',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Gap(8),
                          Divider(
                            color: BibleColors.gold.withValues(alpha: 0.7),
                          ),
                          const Gap(12),
                          if (_showVerseContent) ...[
                            Text(
                              widget.verse.content,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: BibleColors.ink,
                                height: 1.65,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(12),
                          ] else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: BibleColors.navy.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '말씀을 떠올리며 암송해 보세요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Gap(12),
                          ],
                        ],
                      ),
                    ),
                    const Gap(24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: BibleColors.gold,
                              size: 22,
                            ),
                            Gap(8),
                            Text(
                              '내 암송',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        MicButton(onResult: _setSpeechInput),
                      ],
                    ),
                    const Gap(10),
                    TextField(
                      controller: _inputCtrl,
                      maxLines: 8,
                      style: const TextStyle(
                        color: BibleColors.ink,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: '암송한 말씀을 입력하세요',
                        fillColor: BibleColors.cream,
                        filled: true,
                        contentPadding: const EdgeInsets.all(20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: BibleColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: BibleColors.gold,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (_isChecked) setState(() => _isChecked = false);
                      },
                    ),
                    const Gap(22),
                    if (_isChecked) ...[
                      BibleGlassCard(
                        borderColor: _accuracy >= 90
                            ? BibleColors.success
                            : BibleColors.gold,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _accuracy >= 90
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              color: _accuracy >= 90
                                  ? BibleColors.success
                                  : BibleColors.gold,
                            ),
                            const Gap(12),
                            Text(
                              '정확도: ${_accuracy.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _accuracy >= 90
                                    ? BibleColors.success
                                    : BibleColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(20),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _checkAccuracy,
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('정확도 확인하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BibleColors.gold,
                          foregroundColor: BibleColors.ink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
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
