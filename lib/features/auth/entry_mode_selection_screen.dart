import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui_utils.dart';

class EntryModeSelectionScreen extends StatelessWidget {
  const EntryModeSelectionScreen({super.key});

  static const _navyTop = Color(0xFF071B52);
  static const _navy = Color(0xFF102B6C);
  static const _navyDeep = Color(0xFF071542);
  static const _panel = Color(0xFF122A66);
  static const _panelLine = Color(0xFF405C9B);
  static const _gold = Color(0xFFEAC24C);
  static const _goldDark = Color(0xFFC9951D);
  static const _cream = Color(0xFFFFFDF8);
  static const _ink = Color(0xFF0E255B);
  static const _muted = Color(0xFF617098);
  static const _softWhite = Color(0xFFE7EDFF);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await handleDoubleTapExit(context);
      },
      child: Scaffold(
        backgroundColor: _navyDeep,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                const Positioned.fill(child: _MidnightBackdrop()),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeroHeader(
                                onAdminLogin: () => context.push('/login'),
                              ),
                              const Gap(28),
                              _PrimaryActionCard(
                                icon: Icons.emoji_events_rounded,
                                iconColor: _goldDark,
                                title: '대회 참가하기',
                                subtitle: '실시간 암송 서바이벌 경쟁',
                                onTap: () => context.push('/login'),
                              ),
                              const Gap(14),
                              _PrimaryActionCard(
                                icon: Icons.person_rounded,
                                iconColor: _navy,
                                title: '혼자 연습하기',
                                subtitle: '암송구절을 선택하고 쓰거나 말하기',
                                onTap: () => context.push('/practice-lobby'),
                              ),
                              const Gap(20),
                              _TodayVerseCard(
                                onTap: () => context.push('/practice-lobby'),
                              ),
                              const Gap(14),
                              _ProgressCard(
                                onTap: () => context.push('/practice-lobby'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: _BottomNavigation(
                          onPractice: () => context.push('/practice-lobby'),
                          onAdmin: () => context.push('/login'),
                        ),
                      ),
                    ],
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

class _MidnightBackdrop extends StatelessWidget {
  const _MidnightBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            EntryModeSelectionScreen._navyTop,
            EntryModeSelectionScreen._navy,
            EntryModeSelectionScreen._navyDeep,
          ],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 62,
            left: 54,
            child: _TinyStar(size: 4, opacity: 0.38),
          ),
          Positioned(
            top: 110,
            right: 70,
            child: _TinyStar(size: 5, opacity: 0.28),
          ),
          Positioned(
            top: 164,
            left: 24,
            child: _TinyStar(size: 6, opacity: 0.2),
          ),
          Positioned(
            top: 220,
            right: -30,
            child: _CloudCluster(alignment: Alignment.centerRight),
          ),
          Positioned(
            top: 220,
            left: -44,
            child: _CloudCluster(alignment: Alignment.centerLeft),
          ),
        ],
      ),
    );
  }
}

class _TinyStar extends StatelessWidget {
  const _TinyStar({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: Colors.white.withValues(alpha: opacity),
      size: size + 8,
    );
  }
}

class _CloudCluster extends StatelessWidget {
  const _CloudCluster({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      height: 42,
      child: Stack(
        alignment: alignment,
        children: const [
          _CloudBubble(width: 58, height: 34, left: 8, bottom: 0),
          _CloudBubble(width: 42, height: 30, left: 44, bottom: 4),
          _CloudBubble(width: 34, height: 24, left: 0, bottom: 2),
        ],
      ),
    );
  }
}

class _CloudBubble extends StatelessWidget {
  const _CloudBubble({
    required this.width,
    required this.height,
    required this.left,
    required this.bottom,
  });

  final double width;
  final double height;
  final double left;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onAdminLogin});

  final VoidCallback onAdminLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: onAdminLogin,
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.4,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: EntryModeSelectionScreen._gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(8),
        const _BibleMark(),
        const Gap(12),
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'SHOW ME THE BIBLE',
            maxLines: 1,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              shadows: [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        const Gap(6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoldRule(),
            Gap(8),
            Text(
              '성경 암송의 즐거움',
              style: TextStyle(
                color: EntryModeSelectionScreen._softWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Gap(8),
            _GoldRule(),
          ],
        ),
      ],
    );
  }
}

class _BibleMark extends StatelessWidget {
  const _BibleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: EntryModeSelectionScreen._gold,
            size: 64,
          ),
          Positioned(
            left: 23,
            top: 17,
            child: Container(
              width: 4,
              height: 21,
              color: EntryModeSelectionScreen._navyTop,
            ),
          ),
          Positioned(
            left: 14,
            top: 26,
            child: Container(
              width: 20,
              height: 4,
              color: EntryModeSelectionScreen._navyTop,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 2,
          decoration: BoxDecoration(
            color: EntryModeSelectionScreen._gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const Gap(5),
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: EntryModeSelectionScreen._gold,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EntryModeSelectionScreen._cream,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F1E2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EntryModeSelectionScreen._gold
                          .withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EntryModeSelectionScreen._ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EntryModeSelectionScreen._muted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),
              const Icon(
                Icons.chevron_right_rounded,
                color: EntryModeSelectionScreen._goldDark,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayVerseCard extends StatelessWidget {
  const _TodayVerseCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: EntryModeSelectionScreen._gold,
                size: 20,
              ),
              const Gap(9),
              const Expanded(
                child: Text(
                  '오늘의 암송 구절',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallGhostButton(label: '구절 보기', onTap: onTap),
            ],
          ),
          const Gap(15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '“',
                style: TextStyle(
                  color: EntryModeSelectionScreen._gold,
                  fontSize: 44,
                  height: 0.82,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '너는 마음을 다하여 여호와를 신뢰하고\n네 명철을 의지하지 말라',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.55,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      '잠언 3:5',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.56),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallGhostButton extends StatelessWidget {
  const _SmallGhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: EntryModeSelectionScreen._softWhite,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(2),
            const Icon(
              Icons.chevron_right_rounded,
              color: EntryModeSelectionScreen._softWhite,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: EntryModeSelectionScreen._gold,
                size: 23,
              ),
              const Gap(9),
              const Expanded(
                child: Text(
                  '내 진행 현황',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '상세 보기',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.66),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.72),
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(20),
          const Row(
            children: [
              Expanded(
                child: _ProgressStat(
                  icon: Icons.menu_book_rounded,
                  label: '암송한 구절',
                  value: '24',
                  unit: '개',
                  tone: Color(0xFF5278DB),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _ProgressStat(
                  icon: Icons.local_fire_department_rounded,
                  label: '연속 암송',
                  value: '7',
                  unit: '일',
                  tone: EntryModeSelectionScreen._goldDark,
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _ProgressGoal(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EntryModeSelectionScreen._panel.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EntryModeSelectionScreen._panelLine.withValues(alpha: 0.88),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.96),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 25),
        ),
        const Gap(9),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(fontSize: 28, height: 1),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressGoal extends StatelessWidget {
  const _ProgressGoal();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF5572C8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.track_changes_rounded,
              color: Colors.white, size: 27),
        ),
        const Gap(9),
        Text(
          '이번 주 목표',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            children: [
              const TextSpan(
                text: '4',
                style: TextStyle(fontSize: 28, height: 1),
              ),
              TextSpan(
                text: ' / 7',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const Gap(9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: 4 / 7,
            minHeight: 6,
            color: EntryModeSelectionScreen._gold,
            backgroundColor: Colors.black.withValues(alpha: 0.22),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 76,
      margin: const EdgeInsets.symmetric(horizontal: 9),
      color: Colors.white.withValues(alpha: 0.13),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.onPractice,
    required this.onAdmin,
  });

  final VoidCallback onPractice;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: EntryModeSelectionScreen._panel.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: EntryModeSelectionScreen._panelLine.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: _NavItem(
              icon: Icons.home_rounded,
              label: '홈',
              active: true,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.menu_book_outlined,
              label: '암송',
              onTap: onPractice,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.emoji_events_outlined,
              label: '랭킹',
              onTap: onAdmin,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.settings_outlined,
              label: '관리',
              onTap: onAdmin,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final color = active
        ? EntryModeSelectionScreen._gold
        : Colors.white.withValues(alpha: 0.74);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const Gap(4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (active)
              Positioned(
                bottom: 1,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EntryModeSelectionScreen._gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
