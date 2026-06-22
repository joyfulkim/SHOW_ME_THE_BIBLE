import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router.dart';


import 'core/supabase_client.dart'; // 우리가 만든 직접 생성 클라이언트 불러오기

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 공식 초기화 (세션 관리용)
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // 화면 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 보안 모드 (개발 단계에서는 비활성화)
  /*
  try {
    await ScreenSecurity.enableSecureMode();
  } catch (e) {
    print('Security mode not supported on this platform: $e');
  }
  */

  runApp(
    const ProviderScope(
      child: ShowMeBibleApp(),
    ),
  );
}

class ShowMeBibleApp extends ConsumerWidget {
  const ShowMeBibleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SHOW ME THE BIBLE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}

class AppTheme {
  // ─── 네이비 포인트 색상 팔레트 ───
  static const kNavy = Color(0xFF1B2B6B); // 주 포인트
  static const kNavyLight = Color(0xFF2E4BAB); // hover·보조
  static const kNavyBg = Color(0xFFEEF1FB); // 카드 배경 연파랑
  static const kGold = Color(0xFFD4AF37); // 구절 제목 강조
  static const kSurface = Color(0xFFF5F6FA); // 카드/서피스 배경
  static const kText = Color(0xFF1A1A2A); // 본문 글씨

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kNavy,
          brightness: Brightness.light,
          primary: kNavy,
          secondary: kNavyLight,
          surface: kSurface,
          onSurface: kText,
        ),
        scaffoldBackgroundColor: Colors.white,
        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kNavy,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 52, // 상단 영역 줄임
          titleTextStyle: TextStyle(
            color: kNavy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: kNavy),
        ),
        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kNavy,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        // TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kNavy),
        ),
        // InputDecoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFCDD0E3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFCDD0E3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: kNavy, width: 2),
          ),
          hintStyle: TextStyle(color: Color(0xFFABB0CC)),
          labelStyle: TextStyle(color: kNavy),
        ),
        // Card
        cardTheme: CardThemeData(
          color: kSurface,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE0E3F0),
          thickness: 1,
        ),
        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: kNavyBg,
          labelStyle: const TextStyle(color: kNavy, fontSize: 12),
          side: const BorderSide(color: Color(0xFFCDD0E3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
}
