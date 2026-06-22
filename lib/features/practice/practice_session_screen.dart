import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/services/stt_service.dart';
import '../../main.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('암송 연습'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Card(
              color: AppTheme.kNavyBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.kNavy.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Gap(48), // Left spacing for symmetry
                        Expanded(
                          child: Text(
                            widget.verse.reference,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.kNavy,
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
                                    ? Icons.stop_circle
                                    : Icons.volume_up,
                                color: _isSpeaking
                                    ? Colors.redAccent
                                    : AppTheme.kNavy.withOpacity(0.6),
                              ),
                              tooltip: _isSpeaking ? '중지' : '읽어주기',
                            ),
                            IconButton(
                              onPressed: () => setState(
                                  () => _showVerseContent = !_showVerseContent),
                              icon: Icon(
                                _showVerseContent
                                    ? Icons.menu_book
                                    : Icons.menu_book_outlined,
                                color: AppTheme.kNavy.withOpacity(0.6),
                              ),
                              tooltip: _showVerseContent ? '본문 숨기기' : '본문 보기',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Gap(8),
                    const Divider(color: AppTheme.kGold),
                    const Gap(12),
                    if (_showVerseContent) ...[
                      Text(
                        widget.verse.content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.kNavy,
                          height: 1.6,
                        ),
                      ),
                      const Gap(16),
                    ] else ...[
                      const Text(
                        '성경 구절이 숨겨져 있습니다.\n오른쪽 상단 책 아이콘을 눌러 확인하세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Gap(16),
                    ],
                    const Text(
                      '위 구절을 암기하여 아래에 입력하세요.',
                      style: TextStyle(
                        color: AppTheme.kNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '내 암송',
                  style: TextStyle(
                    color: AppTheme.kNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                MicButton(onResult: _setSpeechInput),
              ],
            ),
            const Gap(8),
            TextField(
              controller: _inputCtrl,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '여기에 말씀을 입력하세요...',
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(20),
              ),
              onChanged: (_) {
                if (_isChecked) setState(() => _isChecked = false);
              },
            ),
            const Gap(24),
            if (_isChecked) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: _accuracy >= 90
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _accuracy >= 90
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _accuracy >= 90
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: _accuracy >= 90 ? Colors.green : Colors.orange,
                    ),
                    const Gap(12),
                    Text(
                      '정확도: ${_accuracy.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _accuracy >= 90
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _checkAccuracy,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('정확도 확인하기',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
