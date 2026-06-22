import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/app_shell.dart';
import '../../main.dart';
import '../../core/ui_utils.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _storage.read(key: 'saved_email');
    final savedPassword = await _storage.read(key: 'saved_password');
    final rememberMeStr = await _storage.read(key: 'remember_me');

    if (rememberMeStr == 'true') {
      setState(() {
        _rememberMe = true;
        if (savedEmail != null) _emailCtrl.text = savedEmail;
        if (savedPassword != null) _passwordCtrl.text = savedPassword;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    if (_isSignUp) {
      await notifier.signUpWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _nicknameCtrl.text.trim(),
      );
    } else {
      await notifier.signInWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
    }

    final state = ref.read(authNotifierProvider);
    if (mounted && state is AsyncData) {
      // 로그인 성공 시 정보 저장 처리
      if (_rememberMe) {
        await _storage.write(key: 'saved_email', value: _emailCtrl.text.trim());
        await _storage.write(key: 'saved_password', value: _passwordCtrl.text);
        await _storage.write(key: 'remember_me', value: 'true');
      } else {
        await _storage.delete(key: 'saved_email');
        await _storage.delete(key: 'saved_password');
        await _storage.write(key: 'remember_me', value: 'false');
      }
      if (!mounted) return;
      context.go('/lobby');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_formatError(next.error.toString())),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '닫기',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. 내부 내비게이션 스택(다이얼로그 등)이 있다면 이전으로 이동
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        // 2. 최상단 화면일 경우 두 번 눌러 종료 처리
        await handleDoubleTapExit(context);
      },
      child: BiblePageFrame(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 18,
                child: BibleHomeButton(
                  onTap: () => context.go('/mode-selection'),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: BibleCreamCard(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 로고 영역
                        const _LogoSection(),
                        const Gap(40),

                        // 이메일
                        _NavyInputField(
                          controller: _emailCtrl,
                          label: '이메일',
                          hint: 'example@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const Gap(14),

                        // 닉네임 (회원가입 시만)
                        if (_isSignUp) ...[
                          _NavyInputField(
                            controller: _nicknameCtrl,
                            label: '닉네임',
                            hint: '표시될 이름을 입력하세요',
                          ),
                          const Gap(14),
                        ],

                        // 비밀번호
                        _NavyInputField(
                          controller: _passwordCtrl,
                          label: '비밀번호',
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.kNavy,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const Gap(10),

                        // 아이디/비밀번호 저장 체크박스
                        if (!_isSignUp)
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppTheme.kNavy,
                                  onChanged: (val) => setState(
                                      () => _rememberMe = val ?? false),
                                ),
                              ),
                              const Gap(8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: const Text(
                                  '아이디/비밀번호 저장',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.kNavy,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const Gap(28),

                        // 제출 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isSignUp ? '회원가입' : '로그인'),
                          ),
                        ),
                        const Gap(12),

                        // 전환 버튼
                        TextButton(
                          onPressed: () =>
                              setState(() => _isSignUp = !_isSignUp),
                          child: Text(
                            _isSignUp ? '이미 계정이 있으신가요? 로그인' : '계정이 없으신가요? 회원가입',
                          ),
                        ),

                        const Gap(32),
                        const Divider(),
                        const Gap(12),
                        const _LoginFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatError(String error) {
    if (error.contains('Email not confirmed')) {
      return '이메일 인증이 완료되지 않았습니다. 메일을 확인하거나 Supabase에서 Confirm User를 눌러주세요.';
    }
    if (error.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 틀렸습니다';
    }
    if (error.contains('already registered')) return '이미 등록된 이메일입니다';
    if (error.contains('Password should')) return '비밀번호는 6자 이상이어야 합니다';
    if (error.contains('network_error')) return '네트워크 오류: 인터넷 연결을 확인하세요.';
    return '오류가 발생했습니다: $error';
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '꿈을심는교회',
          style: TextStyle(
            color: Colors.black45,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Gap(12),
        Expanded(
          child: Text(
            'Copyright © 안요한. All Rights Reserved.',
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black45,
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.kNavy,
            boxShadow: [
              BoxShadow(
                color: AppTheme.kNavy.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const Gap(18),
        Text(
          'SHOW ME THE BIBLE',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.kNavy,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
        const Gap(6),
        Text(
          '실시간 성경 암송 서바이벌',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black45,
              ),
        ),
      ],
    );
  }
}

class _NavyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _NavyInputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.kNavy,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const Gap(6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enableInteractiveSelection: false,
          contextMenuBuilder: (ctx, editableTextState) {
            return const SizedBox.shrink();
          },
          style: const TextStyle(color: AppTheme.kText, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
