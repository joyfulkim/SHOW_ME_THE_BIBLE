import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../shared/models.dart';

part 'auth_provider.g.dart';

// ──────────────────────────────────────────
// Auth State (로그인 세션)
// ──────────────────────────────────────────
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return supabase.auth.onAuthStateChange;
}

// ──────────────────────────────────────────
// 현재 사용자 프로필
// ──────────────────────────────────────────
@riverpod
Future<Profile?> currentProfile(CurrentProfileRef ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      // profiles 행이 없으면 user metadata로 폴백
      print('Profile row not found, using metadata fallback');
      return _profileFromUser(user);
    }
    return Profile.fromJson(response);
  } catch (e) {
    // RLS 에러, 500 에러 등 - user metadata로 폴백
    print('Profile fetch failed ($e), using metadata fallback');
    return _profileFromUser(user);
  }
}

Profile _profileFromUser(dynamic user) {
  final meta = user.userMetadata as Map<String, dynamic>? ?? {};
  return Profile(
    id: user.id as String,
    nickname: meta['nickname'] as String? ?? (user.email as String? ?? 'User'),
    role: meta['role'] as String? ?? 'user',
    totalScore: 0.0,
    createdAt: DateTime.now(),
  );
}

// ──────────────────────────────────────────
// Auth Actions Notifier
// ──────────────────────────────────────────
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUpWithEmail(
      String email, String password, String nickname) async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nickname': nickname},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await supabase.auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
