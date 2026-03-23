import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui_utils.dart';
import '../../main.dart';

class EntryModeSelectionScreen extends StatelessWidget {
  const EntryModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await handleDoubleTapExit(context);
      },
      child: Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.kNavy,
              AppTheme.kNavy.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Settings Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white70, size: 28),
                      onPressed: () => context.push('/settings'),
                      tooltip: '음성 설정',
                    ),
                  ],
                ),
                const Gap(20),
                
                // Logo/Title Area
                const Icon(
                  Icons.menu_book_rounded,
                  size: 80,
                  color: AppTheme.kGold,
                ),
                const Gap(24),
                const Text(
                  'SHOW ME THE BIBLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Gap(8),
                const Text(
                  '성경 암송의 즐거움',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const Gap(60),

                // Selection Buttons
                _SelectionCard(
                  title: '대회 참가하기',
                  subtitle: '실시간 암송 서바이벌 경쟁',
                  icon: Icons.emoji_events_rounded,
                  onTap: () => context.push('/login'),
                ),
                const Gap(20),
                _SelectionCard(
                  title: '혼자 연습하기',
                  subtitle: '나만의 구절을 등록하고 외우기',
                  icon: Icons.person_rounded,
                  onTap: () => context.push('/practice-lobby'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: Colors.black45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.kGold.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.kNavyBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.kNavy, size: 30),
              ),
              const Gap(20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.kNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.kNavy.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.kGold, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
