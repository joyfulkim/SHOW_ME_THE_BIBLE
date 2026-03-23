import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'practice_verse.dart';

part 'practice_provider.g.dart';

@riverpod
class PracticeVerseNotifier extends _$PracticeVerseNotifier {
  static const _storageKey = 'practice_verses';

  @override
  FutureOr<List<PracticeVerse>> build() async {
    return _loadVerses();
  }

  Future<List<PracticeVerse>> _loadVerses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    return jsonList
        .map((jsonStr) => PracticeVerse.fromJson(json.decode(jsonStr)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addVerse(String content, String reference) async {
    final currentState = state.valueOrNull ?? [];
    final newVerse = PracticeVerse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      reference: reference,
      createdAt: DateTime.now(),
    );

    final updatedList = [newVerse, ...currentState];
    await _saveVerses(updatedList);
    state = AsyncData(updatedList);
  }

  Future<void> deleteVerse(String id) async {
    final currentState = state.valueOrNull ?? [];
    final updatedList = currentState.where((v) => v.id != id).toList();
    await _saveVerses(updatedList);
    state = AsyncData(updatedList);
  }

  Future<void> updateVerse(String id, String content, String reference) async {
    final currentState = state.valueOrNull ?? [];
    final updatedList = currentState.map((v) {
      if (v.id == id) {
        return v.copyWith(content: content, reference: reference);
      }
      return v;
    }).toList();
    await _saveVerses(updatedList);
    state = AsyncData(updatedList);
  }

  Future<void> _saveVerses(List<PracticeVerse> verses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = verses.map((v) => json.encode(v.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}
