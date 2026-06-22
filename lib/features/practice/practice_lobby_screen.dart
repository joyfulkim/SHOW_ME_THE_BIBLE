import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_shell.dart';
import '../../core/competition_verses.dart';
import '../../core/ui_utils.dart';
import 'practice_session_screen.dart';
import 'practice_verse.dart';

class PracticeLobbyScreen extends StatelessWidget {
  const PracticeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        await handleDoubleTapExit(context);
      },
      child: BiblePageFrame(
        bottomNavigationBar: BibleBottomNav(
          active: 'practice',
          onHome: () => context.go('/mode-selection'),
          onPractice: () {},
          onRanking: () => context.push('/login'),
          onSettings: () => context.push('/settings'),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                child: BibleTopBar(
                  title: '혼자 연습하기',
                  sideWidth: 118,
                  leading: const BibleHomeLeading(),
                  actions: [
                    InkWell(
                      onTap: () => context.push('/settings'),
                      borderRadius: BorderRadius.circular(18),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mic_none_rounded,
                              color: BibleColors.gold,
                              size: 24,
                            ),
                            Gap(6),
                            Text(
                              '음성설정',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 112),
                  itemCount: competitionVerseSeeds.length,
                  separatorBuilder: (context, index) => const Gap(14),
                  itemBuilder: (context, index) {
                    final seed = competitionVerseSeeds[index];
                    return _PracticeVerseTile(
                      index: index,
                      reference: seed.reference,
                      theme: seed.theme,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PracticeSessionScreen(
                              verse: PracticeVerse(
                                id: 'competition-$index',
                                content: seed.content,
                                reference: seed.reference,
                                createdAt: DateTime.now(),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeVerseTile extends StatelessWidget {
  const _PracticeVerseTile({
    required this.index,
    required this.reference,
    required this.theme,
    required this.onTap,
  });

  final int index;
  final String reference;
  final String theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BibleGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      radius: 22,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BibleColors.panel.withValues(alpha: 0.82),
              border:
                  Border.all(color: BibleColors.gold.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: BibleColors.gold.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: BibleColors.gold,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Gap(18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(7),
                Text(
                  theme.isEmpty ? reference : theme,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          const Icon(
            Icons.chevron_right_rounded,
            color: BibleColors.gold,
            size: 34,
          ),
        ],
      ),
    );
  }
}
