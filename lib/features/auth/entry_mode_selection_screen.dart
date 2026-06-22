import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui_utils.dart';
import '../../main.dart';

class EntryModeSelectionScreen extends StatelessWidget {
  const EntryModeSelectionScreen({super.key});

  static const _ink = Color(0xFF172033);
  static const _paper = Color(0xFFF7F8FB);
  static const _line = Color(0xFFE0E4EF);
  static const _teal = Color(0xFF166C70);
  static const _posterImage = 'assets/images/splash_bg.png';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await handleDoubleTapExit(context);
      },
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;
              final horizontalPadding = isWide ? 44.0 : 20.0;
              final previewHeight = isWide ? 640.0 : 470.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                  ),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _HomeCopy(
                                onJoin: () => context.push('/login'),
                                onPractice: () =>
                                    context.push('/practice-lobby'),
                                isWide: true,
                              ),
                            ),
                            const Gap(36),
                            Expanded(
                              child: _PreviewPanel(height: previewHeight),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HomeCopy(
                              onJoin: () => context.push('/login'),
                              onPractice: () => context.push('/practice-lobby'),
                              isWide: false,
                            ),
                            const Gap(24),
                            _PreviewPanel(height: previewHeight),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeCopy extends StatelessWidget {
  const _HomeCopy({
    required this.onJoin,
    required this.onPractice,
    required this.isWide,
  });

  final VoidCallback onJoin;
  final VoidCallback onPractice;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final titleSize = isWide ? 52.0 : 38.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Badge(label: '2026 암송대회'),
        const Gap(26),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.kGold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const Gap(22),
        Text(
          'SHOW ME\nTHE BIBLE',
          style: TextStyle(
            color: EntryModeSelectionScreen._ink,
            fontSize: titleSize,
            height: 0.95,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Gap(18),
        const Text(
          '준비된 암송구절로 대회에 참여하고 혼자 연습할 수 있습니다.',
          style: TextStyle(
            color: Color(0xFF5A6475),
            fontSize: 16,
            height: 1.55,
          ),
        ),
        const Gap(22),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(label: '11개 암송구절', filled: true),
            _Badge(label: '쓰기·말하기'),
            _Badge(label: '실시간 대회'),
          ],
        ),
        const Gap(34),
        _ModeAction(
          title: '대회 참가하기',
          subtitle: '로그인 후 실시간 암송 대회로 이동',
          icon: Icons.emoji_events_rounded,
          accentColor: AppTheme.kGold,
          onTap: onJoin,
        ),
        const Gap(12),
        _ModeAction(
          title: '혼자 연습하기',
          subtitle: '암송구절을 선택하고 쓰거나 말하기',
          icon: Icons.record_voice_over_rounded,
          accentColor: EntryModeSelectionScreen._teal,
          onTap: onPractice,
        ),
      ],
    );
  }
}

class _ModeAction extends StatelessWidget {
  const _ModeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: EntryModeSelectionScreen._line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: EntryModeSelectionScreen._ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF637083),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              const Icon(
                Icons.arrow_forward_rounded,
                color: EntryModeSelectionScreen._ink,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EntryModeSelectionScreen._line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            const Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _PosterPreview(),
                    _PracticePreview(),
                    _VoicePreview(),
                  ],
                ),
              ),
            ),
            Container(
              height: 58,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: EntryModeSelectionScreen._line),
                ),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: EntryModeSelectionScreen._ink,
                  borderRadius: BorderRadius.circular(6),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: EntryModeSelectionScreen._ink,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.shield_rounded, size: 17), text: '대회'),
                  Tab(icon: Icon(Icons.list_alt_rounded, size: 17), text: '연습'),
                  Tab(icon: Icon(Icons.mic_rounded, size: 17), text: '음성'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterPreview extends StatelessWidget {
  const _PosterPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101623),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            EntryModeSelectionScreen._posterImage,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _PracticePreview extends StatelessWidget {
  const _PracticePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFC),
      padding: const EdgeInsets.all(18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.menu_book_rounded,
            title: '암송구절',
            tone: EntryModeSelectionScreen._teal,
          ),
          Gap(18),
          _MiniVerse(index: '0', reference: '주기도문', label: '주기도문'),
          Gap(10),
          _MiniVerse(
            index: '1',
            reference: '로마서 8:1-2',
            label: '정체성',
          ),
          Gap(10),
          _MiniVerse(
            index: '5',
            reference: '빌립보서 4:6-7',
            label: '불안',
          ),
          Spacer(),
          _MiniProgress(label: '연습 진행', value: 0.72),
        ],
      ),
    );
  }
}

class _VoicePreview extends StatelessWidget {
  const _VoicePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF192033),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.record_voice_over_rounded,
            title: '말하기 연습',
            tone: AppTheme.kGold,
            inverted: true,
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              child: const Icon(
                Icons.mic_rounded,
                size: 56,
                color: AppTheme.kGold,
              ),
            ),
          ),
          const Gap(24),
          const _Waveform(),
          const Gap(24),
          const _MiniProgress(
            label: '정확도',
            value: 0.91,
            inverted: true,
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.tone,
    this.inverted = false,
  });

  final IconData icon;
  final String title;
  final Color tone;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: inverted ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: tone, size: 22),
        ),
        const Gap(10),
        Text(
          title,
          style: TextStyle(
            color: inverted ? Colors.white : EntryModeSelectionScreen._ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MiniVerse extends StatelessWidget {
  const _MiniVerse({
    required this.index,
    required this.reference,
    required this.label,
  });

  final String index;
  final String reference;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EntryModeSelectionScreen._line),
      ),
      child: Row(
        children: [
          Text(
            index,
            style: const TextStyle(
              color: AppTheme.kGold,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EntryModeSelectionScreen._ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF687386),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BA3B2)),
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({
    required this.label,
    required this.value,
    this.inverted = false,
  });

  final String label;
  final double value;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final textColor = inverted ? Colors.white : EntryModeSelectionScreen._ink;
    final trackColor = inverted
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFE7EAF2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Gap(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: inverted ? AppTheme.kGold : EntryModeSelectionScreen._teal,
            backgroundColor: trackColor,
          ),
        ),
      ],
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  static const _bars = [28.0, 44.0, 66.0, 38.0, 84.0, 52.0, 72.0, 34.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final height in _bars)
            Container(
              width: 16,
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.kGold,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? EntryModeSelectionScreen._ink : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: filled
              ? EntryModeSelectionScreen._ink
              : EntryModeSelectionScreen._line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : EntryModeSelectionScreen._ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
