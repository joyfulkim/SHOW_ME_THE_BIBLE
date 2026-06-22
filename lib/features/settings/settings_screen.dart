import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_shell.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  List<dynamic> _voices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      // Filter for Korean voices only
      final krVoices = voices.where((voice) {
        final locale = voice['locale'] as String?;
        return locale != null && locale.contains('ko');
      }).toList();

      setState(() {
        _voices = krVoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testVoice(String voiceName, String locale, double rate) async {
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setVoice({"name": voiceName, "locale": locale});
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.speak("안녕하세요. 선택하신 목소리와 속도입니다.");
  }

  @override
  Widget build(BuildContext context) {
    final ttsSettingsState = ref.watch(ttsSettingsProvider);
    final selectedVoice = ttsSettingsState.valueOrNull?.voiceName;
    final currentRate = ttsSettingsState.valueOrNull?.speechRate ?? 0.5;

    return BiblePageFrame(
      bottomNavigationBar: BibleBottomNav(
        active: 'settings',
        onHome: () => context.go('/mode-selection'),
        onPractice: () => context.push('/practice-lobby'),
        onRanking: () => context.push('/login'),
        onSettings: () {},
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: BibleTopBar(
                title: '음성설정',
                leading: BibleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: '뒤로',
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/practice-lobby'),
                ),
                actions: [
                  BibleIconButton(
                    icon: Icons.home_rounded,
                    tooltip: '홈',
                    color: BibleColors.gold,
                    onTap: () => context.go('/mode-selection'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading || ttsSettingsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: BibleColors.gold,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 116),
                      children: [
                        const BibleSectionTitle(
                          icon: Icons.speed_rounded,
                          title: '읽기 속도 설정',
                        ),
                        const Gap(12),
                        BibleCreamCard(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '느림',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  Text(
                                    '${currentRate.toStringAsFixed(1)}x',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: BibleColors.ink,
                                    ),
                                  ),
                                  const Text(
                                    '빠름',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: currentRate,
                                min: 0.1,
                                max: 1.0,
                                divisions: 9,
                                activeColor: BibleColors.gold,
                                inactiveColor:
                                    BibleColors.gold.withValues(alpha: 0.24),
                                onChanged: (value) => ref
                                    .read(ttsSettingsProvider.notifier)
                                    .setSpeechRate(value),
                              ),
                            ],
                          ),
                        ),
                        const Gap(26),
                        const BibleSectionTitle(
                          icon: Icons.record_voice_over_rounded,
                          title: 'TTS 목소리 선택',
                        ),
                        const Gap(12),
                        if (_voices.isEmpty)
                          const BibleGlassCard(
                            child: Center(
                              child: Text(
                                '사용 가능한 목소리가 없습니다.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        else
                          ..._voices.map((voice) {
                            final name = voice['name'] as String;
                            final locale =
                                voice['locale'] as String? ?? 'ko-KR';
                            final isSelected = selectedVoice == name;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: BibleGlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                borderColor:
                                    isSelected ? BibleColors.gold : null,
                                onTap: () => ref
                                    .read(ttsSettingsProvider.notifier)
                                    .setVoice(name, locale),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isSelected ? '선택됨' : locale,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.62),
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? BibleColors.gold
                                        : Colors.white.withValues(alpha: 0.12),
                                    child: Icon(
                                      Icons.record_voice_over_rounded,
                                      color: isSelected
                                          ? BibleColors.ink
                                          : Colors.white,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: BibleColors.gold,
                                    ),
                                    onPressed: () =>
                                        _testVoice(name, locale, currentRate),
                                    tooltip: '테스트 재생',
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
