import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/competition_verses.dart';
import '../../core/ui_utils.dart';
import '../../main.dart';
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

        // 내부 내비게이션(다이얼로그 등)이 있으면 이전으로
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        await handleDoubleTapExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('혼자 연습하기'),
          centerTitle: true,
          actions: [
            TextButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_voice_rounded, size: 18),
              label: const Text('음성설정'),
            ),
            const Gap(8),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: competitionVerseSeeds.length,
          separatorBuilder: (context, index) => const Gap(12),
          itemBuilder: (context, index) {
            final seed = competitionVerseSeeds[index];
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.kNavyBg,
                  foregroundColor: AppTheme.kNavy,
                  child: Text(
                    '$index',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  seed.reference,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNavy,
                  ),
                ),
                subtitle: seed.theme.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          seed.theme,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.kText.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                trailing:
                    const Icon(Icons.chevron_right, color: AppTheme.kGold),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
