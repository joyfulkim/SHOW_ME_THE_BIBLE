import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

part 'stt_service.g.dart';

@riverpod
class SttController extends _$SttController {
  final SpeechToText _speechToText = SpeechToText();
  
  @override
  bool build() => false; // false = not listening, true = listening

  Future<bool> initialize() async {
    try {
      final hasPermission = await Permission.microphone.request().isGranted;
      if (!hasPermission) return false;

      return await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = false;
          }
        },
        onError: (errorNotification) {
          if (kDebugMode) {
            print('STT Error: ${errorNotification.errorMsg}');
          }
          state = false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('STT Init Error: $e');
      }
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ko_KR',
  }) async {
    if (state) return;

    final available = await initialize();
    if (available) {
      state = true;
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: localeId,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
    }
  }

  Future<void> stopListening() async {
    if (!state) return;
    await _speechToText.stop();
    state = false;
  }
}
