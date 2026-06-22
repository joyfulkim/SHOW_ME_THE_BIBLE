import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui_utils.dart';
import '../../main.dart';

class EntryModeSelectionScreen extends StatelessWidget {
  const EntryModeSelectionScreen({super.key});

  static const _blue = Color(0xFF164B9F);
  static const _blueDark = Color(0xFF0E3475);
  static const _blueSoft = Color(0xFFEAF1FF);
  static const _mint = Color(0xFF28B486);
  static const _ink = Color(0xFF16243A);
  static const _muted = Color(0xFF6B7688);
  static const _surface = Color(0xFFF3F6FC);
  static const _line = Color(0xFFE2E8F3);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await handleDoubleTapExit(context);
      },
      child: Scaffold(
        backgroundColor: _surface,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                const _BlueHeader(),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TopIdentity(
                                onAdminLogin: () => context.push('/login'),
                              ),
                              const Gap(22),
                              _QuickActions(
                                onJoin: () => context.push('/login'),
                                onPractice: () =>
                                    context.push('/practice-lobby'),
                              ),
                              const Gap(22),
                              _HomePanel(
                                onJoin: () => context.push('/login'),
                                onPractice: () =>
                                    context.push('/practice-lobby'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: _BottomDock(
                        onJoin: () => context.push('/login'),
                        onPractice: () => context.push('/practice-lobby'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlueHeader extends StatelessWidget {
  const _BlueHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EntryModeSelectionScreen._blue,
            EntryModeSelectionScreen._blueDark,
          ],
        ),
      ),
    );
  }
}

class _TopIdentity extends StatelessWidget {
  const _TopIdentity({required this.onAdminLogin});

  final VoidCallback onAdminLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onAdminLogin,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.36),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
        const Gap(22),
        const Text(
          'SHOW ME',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 0.95,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'THE BIBLE',
          style: TextStyle(
            color: Color(0xFFD8E7FF),
            fontSize: 34,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Gap(8),
        Text(
          '2026 성경 암송대회',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onJoin,
    required this.onPractice,
  });

  final VoidCallback onJoin;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.emoji_events_rounded,
            label: '대회',
            onTap: onJoin,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _QuickAction(
            icon: Icons.edit_note_rounded,
            label: '연습',
            onTap: onPractice,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _QuickAction(
            icon: Icons.menu_book_rounded,
            label: '구절',
            onTap: onPractice,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _QuickAction(
            icon: Icons.mic_rounded,
            label: '말하기',
            onTap: onPractice,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: EntryModeSelectionScreen._blue, size: 25),
          ),
          const Gap(8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.onJoin,
    required this.onPractice,
  });

  final VoidCallback onJoin;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3D74).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '오늘의 암송 준비',
                  style: TextStyle(
                    color: EntryModeSelectionScreen._ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: EntryModeSelectionScreen._blueSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '11구절',
                  style: TextStyle(
                    color: EntryModeSelectionScreen._blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          const _VersePreviewCard(),
          const Gap(18),
          _PrimaryModeCard(
            title: '대회 참가하기',
            subtitle: '로그인 후 실시간 암송 대회 입장',
            icon: Icons.emoji_events_rounded,
            color: EntryModeSelectionScreen._blue,
            onTap: onJoin,
          ),
          const Gap(12),
          _PrimaryModeCard(
            title: '혼자 연습하기',
            subtitle: '구절을 선택하고 쓰거나 말하기',
            icon: Icons.record_voice_over_rounded,
            color: EntryModeSelectionScreen._mint,
            onTap: onPractice,
          ),
          const Gap(18),
          const _FeatureStrip(),
        ],
      ),
    );
  }
}

class _VersePreviewCard extends StatelessWidget {
  const _VersePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF203D70),
            Color(0xFF102B59),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102B59).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: AppTheme.kGold),
              Gap(8),
              Text(
                '0. 주기도문',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Gap(12),
          Text(
            '하늘에 계신 우리 아버지여 이름이 거룩히 여김을 받으시오며...',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFD7E5FF),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryModeCard extends StatelessWidget {
  const _PrimaryModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EntryModeSelectionScreen._surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EntryModeSelectionScreen._line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: EntryModeSelectionScreen._ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EntryModeSelectionScreen._muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA7BA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _FeaturePill(
            icon: Icons.spellcheck_rounded,
            label: '정확도',
          ),
        ),
        Gap(8),
        Expanded(
          child: _FeaturePill(
            icon: Icons.mic_external_on_rounded,
            label: '음성입력',
          ),
        ),
        Gap(8),
        Expanded(
          child: _FeaturePill(
            icon: Icons.leaderboard_rounded,
            label: '순위',
          ),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: EntryModeSelectionScreen._blueSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: EntryModeSelectionScreen._blue, size: 16),
          const Gap(5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EntryModeSelectionScreen._blue,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.onJoin,
    required this.onPractice,
  });

  final VoidCallback onJoin;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: _DockItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: true,
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.emoji_events_outlined,
              label: 'Contest',
              onTap: onJoin,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              onTap: onPractice,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: EntryModeSelectionScreen._blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    const Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.edit_note_rounded,
              label: 'Practice',
              onTap: onPractice,
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Admin',
              onTap: onJoin,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? EntryModeSelectionScreen._blue : const Color(0xFF8B97AA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
