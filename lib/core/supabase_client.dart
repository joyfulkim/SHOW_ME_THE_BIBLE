import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 접속 정보 상수 (main.dart에서도 참조)
const String supabaseUrl = 'https://mimankxkzinajnypeabo.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pbWFua3hremluYWpueXBlYWJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzNDk1MjMsImV4cCI6MjA4ODkyNTUyM30.d9vXi8w0npTRO3AoQPj_GZvXz-WSf_nQ1hkHr3p4wqg';

/// Supabase 클라이언트 - 항상 싱글톤에서 가져옴 (세션 공유 보장)
/// main.dart에서 Supabase.initialize()가 완료된 후에만 호출됩니다.
SupabaseClient get supabase => Supabase.instance.client;
