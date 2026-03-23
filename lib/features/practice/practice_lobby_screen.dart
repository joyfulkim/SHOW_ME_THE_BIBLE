import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui_utils.dart';
import '../../main.dart';
import 'practice_provider.dart';
import 'verse_registration_screen.dart';
import 'practice_session_screen.dart';

class PracticeLobbyScreen extends ConsumerWidget {
  const PracticeLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesAsync = ref.watch(practiceVerseNotifierProvider);

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
        ),
        body: versesAsync.when(
          data: (verses) {
            if (verses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined, size: 64, color: AppTheme.kNavy.withOpacity(0.2)),
                    const Gap(16),
                    Text(
                      '등록된 구절이 없습니다.\n새 구절을 등록해 보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.kNavy.withOpacity(0.5)),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: verses.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final verse = verses[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      verse.reference,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kNavy),
                    ),
                    subtitle: Text(
                      verse.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.kText.withOpacity(0.7)),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.kGold),
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('구절 관리'),
                          content: Text('${verse.reference} 구절을 어떻게 하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VerseRegistrationScreen(verse: verse),
                                  ),
                                );
                              },
                              child: const Text('수정'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(practiceVerseNotifierProvider.notifier).deleteVerse(verse.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text('삭제', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PracticeSessionScreen(verse: verse),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류 발생: $e')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VerseRegistrationScreen()),
            );
          },
          backgroundColor: AppTheme.kNavy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('구절 등록'),
        ),
      ),
    );
  }
}
