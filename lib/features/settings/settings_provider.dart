import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

class TtsSettingsConfig {
  final String? voiceName;
  final String? locale;
  final double speechRate;

  TtsSettingsConfig({this.voiceName, this.locale, this.speechRate = 0.5});

  TtsSettingsConfig copyWith({String? voiceName, String? locale, double? speechRate}) {
    return TtsSettingsConfig(
      voiceName: voiceName ?? this.voiceName,
      locale: locale ?? this.locale,
      speechRate: speechRate ?? this.speechRate,
    );
  }
}

@riverpod
class TtsSettings extends _$TtsSettings {
  static const String _voiceKey = 'selected_tts_voice_name';
  static const String _localeKey = 'selected_tts_voice_locale';
  static const String _rateKey = 'selected_tts_speech_rate';

  @override
  FutureOr<TtsSettingsConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    final voiceName = prefs.getString(_voiceKey);
    final locale = prefs.getString(_localeKey);
    final speechRate = prefs.getDouble(_rateKey) ?? 0.5;
    
    return TtsSettingsConfig(voiceName: voiceName, locale: locale, speechRate: speechRate);
  }

  Future<void> setVoice(String voiceName, String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceKey, voiceName);
    await prefs.setString(_localeKey, locale);
    
    final current = state.valueOrNull ?? TtsSettingsConfig();
    state = AsyncData(current.copyWith(voiceName: voiceName, locale: locale));
  }

  Future<void> setSpeechRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, rate);
    
    final current = state.valueOrNull ?? TtsSettingsConfig();
    state = AsyncData(current.copyWith(speechRate: rate));
  }
}
