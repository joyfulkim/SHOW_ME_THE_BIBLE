import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/admin_config.dart';
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
      final profile = _profileFromUser(user);
      return _ensureConfiguredAdminProfile(profile, user, profileExists: false);
    }
    final profile = Profile.fromJson(response);
    return _ensureConfiguredAdminProfile(profile, user, profileExists: true);
  } catch (e) {
    // RLS 에러, 500 에러 등 - user metadata로 폴백
    print('Profile fetch failed ($e), using metadata fallback');
    final profile = _profileFromUser(user);
    return _ensureConfiguredAdminProfile(profile, user, profileExists: false);
  }
}

Profile _profileFromUser(dynamic user) {
  final meta = user.userMetadata as Map<String, dynamic>? ?? {};
  final email = user.email as String?;
  return Profile(
    id: user.id as String,
    nickname: meta['nickname'] as String? ?? (email ?? 'User'),
    role: isConfiguredAdminEmail(email)
        ? 'admin'
        : (meta['role'] as String? ?? 'contestant'),
    totalScore: 0.0,
    createdAt: DateTime.now(),
  );
}

Future<Profile> _ensureConfiguredAdminProfile(
  Profile profile,
  dynamic user, {
  required bool profileExists,
}) async {
  final email = user.email as String?;
  if (!isConfiguredAdminEmail(email)) return profile;

  if (profile.role != 'admin') {
    try {
      if (profileExists) {
        await supabase
            .from('profiles')
            .update({'role': 'admin'}).eq('id', profile.id);
      } else {
        await supabase.from('profiles').insert({
          'id': profile.id,
          'nickname': profile.nickname,
          'role': 'admin',
        });
      }
    } catch (e) {
      print('Configured admin promotion failed: $e');
    }
  }

  return Profile(
    id: profile.id,
    nickname: profile.nickname,
    role: 'admin',
    totalScore: profile.totalScore,
    createdAt: profile.createdAt,
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
