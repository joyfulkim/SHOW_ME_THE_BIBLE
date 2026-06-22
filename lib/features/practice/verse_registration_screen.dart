import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_shell.dart';
import 'practice_provider.dart';
import 'practice_verse.dart';

class VerseRegistrationScreen extends ConsumerStatefulWidget {
  final PracticeVerse? verse;
  const VerseRegistrationScreen({super.key, this.verse});

  @override
  ConsumerState<VerseRegistrationScreen> createState() =>
      _VerseRegistrationScreenState();
}

class _VerseRegistrationScreenState
    extends ConsumerState<VerseRegistrationScreen> {
  late final TextEditingController _contentCtrl;
  late final TextEditingController _referenceCtrl;

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.verse?.content);
    _referenceCtrl = TextEditingController(text: widget.verse?.reference);
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    final reference = _referenceCtrl.text.trim();

    if (content.isEmpty || reference.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해 주세요.')),
      );
      return;
    }

    if (widget.verse != null) {
      await ref.read(practiceVerseNotifierProvider.notifier).updateVerse(
            widget.verse!.id,
            content,
            reference,
          );
    } else {
      await ref
          .read(practiceVerseNotifierProvider.notifier)
          .addVerse(content, reference);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.verse != null;
    return BiblePageFrame(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: BibleTopBar(
                title: isEdit ? '구절 수정' : '구절 등록',
                sideWidth: 104,
                leading: BibleHomeLeading(
                  showBack: true,
                  onBack: () => Navigator.pop(context),
                  onHome: () => context.go('/mode-selection'),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                child: BibleCreamCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? '구절의 내용을 수정하세요.' : '연습하고 싶은 구절을 입력하세요.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: BibleColors.ink,
                        ),
                      ),
                      const Gap(24),
                      TextFormField(
                        controller: _referenceCtrl,
                        decoration: const InputDecoration(
                          labelText: '출처 (예: 요한복음 3:16)',
                          hintText: '구절 위치를 입력하세요',
                        ),
                      ),
                      const Gap(16),
                      TextFormField(
                        controller: _contentCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: '성경 말씀',
                          hintText: '말씀 전체를 오타 없이 입력해 주세요.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const Gap(32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(isEdit ? '수정 완료' : '저장하기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
