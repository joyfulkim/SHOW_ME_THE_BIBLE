import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/admin/admin_panel_screen.dart';
import '../features/game/contestant_screen.dart';
import '../features/game/leaderboard_screen.dart';
import '../features/game/join_session_screen.dart';
import '../features/result/user_result_detail_screen.dart';
import '../features/admin/grading_details_screen.dart';
import '../features/result/final_result_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/game/game_provider.dart';
import '../features/auth/entry_mode_selection_screen.dart';
import '../features/practice/practice_lobby_screen.dart';
import '../features/settings/settings_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final matchedLocation = state.matchedLocation;

      // ── 인증 없이 접근 가능한 경로 ──
      final publicPaths = ['/splash', '/mode-selection', '/practice-lobby'];
      final isPublic = publicPaths.contains(matchedLocation);

      if (isPublic) return null;

      // ── 로그인 안된 경우 대회 참여 관련 경로는 로그인으로 이동 ──
      if (!isLoggedIn) {
        return '/login';
      }

      // ── 로그인 된 상태에서 로그인 페이지 접근 시 로비로 이동 ──
      if (isLoggedIn && matchedLocation == '/login') {
        return '/lobby';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/mode-selection',
        builder: (context, state) => const EntryModeSelectionScreen(),
      ),
      GoRoute(
        path: '/practice-lobby',
        builder: (context, state) => const PracticeLobbyScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinSessionScreen(),
      ),
      GoRoute(
        path: '/lobby',
        builder: (context, state) => const LobbyRedirectScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? 'default';
          return AdminPanelScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? 'default';
          return ContestantScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? 'default';
          return LeaderboardScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? 'default';
          return FinalResultScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/grading',
        builder: (context, state) {
          final submissionId = int.tryParse(state.uri.queryParameters['submissionId'] ?? '') ?? 0;
          final sessionId = state.uri.queryParameters['sessionId'] ?? 'default';
          final roundNumber = int.tryParse(state.uri.queryParameters['roundNumber'] ?? '') ?? 1;
          return GradingDetailsScreen(
            submissionId: submissionId,
            sessionId: sessionId,
            roundNumber: roundNumber,
          );
        },
      ),
      GoRoute(
        path: '/user-result',
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? 'default';
          final targetUserId = state.uri.queryParameters['targetUserId'] ?? '';
          return UserResultDetailScreen(
            sessionId: sessionId,
            targetUserId: targetUserId,
          );
        },
      ),
    ],
  );
}

/// 로그인 후 역할(role)에 따라 적절한 화면으로 리다이렉트
class LobbyRedirectScreen extends ConsumerWidget {
  const LobbyRedirectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final latestSessionAsync = ref.watch(latestActiveSessionProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 사용자의 역할에 따른 이동 처리
        return latestSessionAsync.when(
          data: (session) {
            final targetSessionId = session?.id ?? 'default';
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (profile.role == 'admin') {
                context.go('/admin?sessionId=$targetSessionId');
              } else if (session?.status == 'finished') {
                context.go('/join');
              } else {
                context.go('/join');
              }
            });

            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('세션 조회 오류: $e'))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('프로필 조회 오류: $e'))),
    );
  }
}
