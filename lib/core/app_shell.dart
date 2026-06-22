import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class BibleColors {
  const BibleColors._();

  static const navyTop = Color(0xFF071B52);
  static const navy = Color(0xFF102B6C);
  static const navyDeep = Color(0xFF071542);
  static const panel = Color(0xFF122A66);
  static const panelLight = Color(0xFF1B397E);
  static const panelLine = Color(0xFF405C9B);
  static const gold = Color(0xFFEAC24C);
  static const goldDark = Color(0xFFC9951D);
  static const cream = Color(0xFFFFFCF6);
  static const ink = Color(0xFF0E255B);
  static const muted = Color(0xFFB7C2DD);
  static const danger = Color(0xFFFF6B6B);
  static const success = Color(0xFF6ED28B);
}

class BiblePageFrame extends StatelessWidget {
  const BiblePageFrame({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget child;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BibleColors.navyDeep,
      extendBody: true,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              const Positioned.fill(child: BibleBackground()),
              Positioned.fill(child: child),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: bottomNavigationBar,
              ),
            ),
    );
  }
}

class BibleBackground extends StatelessWidget {
  const BibleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BibleColors.navyTop,
            BibleColors.navy,
            BibleColors.navyDeep,
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: 36, left: 56, child: _Star(size: 11, opacity: 0.38)),
          Positioned(top: 92, right: 70, child: _Star(size: 9, opacity: 0.30)),
          Positioned(top: 176, left: 22, child: _Star(size: 13, opacity: 0.20)),
          Positioned(
              top: 210, right: 34, child: _Star(size: 12, opacity: 0.30)),
          Positioned(top: 134, left: -50, child: _CloudCluster()),
          Positioned(top: 134, right: -58, child: _CloudCluster()),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome_rounded,
      color: Colors.white.withValues(alpha: opacity),
      size: size,
    );
  }
}

class _CloudCluster extends StatelessWidget {
  const _CloudCluster();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 50,
      child: Stack(
        children: [
          _CloudBubble(width: 64, height: 36, left: 12, bottom: 0),
          _CloudBubble(width: 48, height: 34, left: 54, bottom: 4),
          _CloudBubble(width: 38, height: 28, left: 0, bottom: 2),
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

class BibleTopBar extends StatelessWidget {
  const BibleTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.sideWidth = 72,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double sideWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          SizedBox(
            width: sideWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: leading,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: sideWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
        ],
      ),
    );
  }
}

class BibleIconButton extends StatelessWidget {
  const BibleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: color, size: 30),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class BibleGlassCard extends StatelessWidget {
  const BibleGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.radius = 22,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: BibleColors.panel.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? BibleColors.panelLine.withValues(alpha: 0.76),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class BibleCreamCard extends StatelessWidget {
  const BibleCreamCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: BibleColors.cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BibleColors.gold.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: content,
      ),
    );
  }
}

class BibleBottomNav extends StatelessWidget {
  const BibleBottomNav({
    super.key,
    required this.active,
    required this.onHome,
    required this.onPractice,
    required this.onRanking,
    required this.onSettings,
  });

  final String active;
  final VoidCallback onHome;
  final VoidCallback onPractice;
  final VoidCallback onRanking;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: BibleColors.panel.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: BibleColors.panelLine.withValues(alpha: 0.9),
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
              Expanded(
                child: _BibleNavItem(
                  icon: Icons.home_rounded,
                  label: '홈',
                  active: active == 'home',
                  onTap: onHome,
                ),
              ),
              Expanded(
                child: _BibleNavItem(
                  icon: Icons.menu_book_outlined,
                  label: '암송',
                  active: active == 'practice',
                  onTap: onPractice,
                ),
              ),
              Expanded(
                child: _BibleNavItem(
                  icon: Icons.emoji_events_outlined,
                  label: '랭킹',
                  active: active == 'ranking',
                  onTap: onRanking,
                ),
              ),
              Expanded(
                child: _BibleNavItem(
                  icon: Icons.settings_outlined,
                  label: '설정',
                  active: active == 'settings',
                  onTap: onSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BibleNavItem extends StatelessWidget {
  const _BibleNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? BibleColors.gold : Colors.white.withValues(alpha: 0.74);

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
                    color: BibleColors.gold,
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

class BibleSectionTitle extends StatelessWidget {
  const BibleSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: BibleColors.gold, size: 22),
        const Gap(8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
