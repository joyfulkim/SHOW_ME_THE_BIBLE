import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gap/gap.dart';
import '../../main.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: _isLoading || ttsSettingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '읽기 속도 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNavy,
                  ),
                ),
                const Gap(12),
                Card(
                  elevation: 0,
                  color: AppTheme.kNavyBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.kNavy.withOpacity(0.05)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('느림', style: TextStyle(fontSize: 12, color: Colors.black45)),
                            Text(
                              '${currentRate.toStringAsFixed(1)}x',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.kNavy,
                              ),
                            ),
                            const Text('빠름', style: TextStyle(fontSize: 12, color: Colors.black45)),
                          ],
                        ),
                        Slider(
                          value: currentRate,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          activeColor: AppTheme.kGold,
                          inactiveColor: AppTheme.kGold.withOpacity(0.2),
                          onChanged: (value) => ref.read(ttsSettingsProvider.notifier).setSpeechRate(value),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(32),
                const Text(
                  'TTS 목소리 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNavy,
                  ),
                ),
                const Gap(8),
                const Text(
                  '성경 구절을 읽어줄 목소리를 선택하세요.',
                  style: TextStyle(color: Colors.black54),
                ),
                const Gap(20),
                if (_voices.isEmpty)
                  const Center(child: Text('사용 가능한 목소리가 없습니다.'))
                else
                  ..._voices.map((voice) {
                    final name = voice['name'] as String;
                    final isSelected = selectedVoice == name;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? AppTheme.kGold : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          final locale = voice['locale'] as String? ?? 'ko-KR';
                          ref.read(ttsSettingsProvider.notifier).setVoice(name, locale);
                        },
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(isSelected ? '선택됨' : '터치하여 선택'),
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? AppTheme.kGold : AppTheme.kNavyBg,
                          child: Icon(
                            Icons.record_voice_over,
                            color: isSelected ? Colors.white : AppTheme.kNavy,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_circle_outline),
                          onPressed: () {
                            final locale = voice['locale'] as String? ?? 'ko-KR';
                            _testVoice(name, locale, currentRate);
                          },
                          tooltip: '테스트 재생',
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
    );
  }
}
