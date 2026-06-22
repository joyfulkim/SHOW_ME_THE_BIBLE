import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'admin_provider.dart';
import '../../core/app_shell.dart';
import '../../main.dart';
import '../../shared/models.dart';

class VerseSelectorScreen extends ConsumerStatefulWidget {
  const VerseSelectorScreen({
    super.key,
    this.onVerseSelected,
    this.onVersesSelected,
    this.sessionId,
    this.isMultiSelect = false,
    this.requiredCount,
  });

  final void Function(Verse verse)? onVerseSelected;
  final void Function(List<Verse> verses)? onVersesSelected;
  final String? sessionId;
  final bool isMultiSelect;
  final int? requiredCount;

  @override
  ConsumerState<VerseSelectorScreen> createState() =>
      _VerseSelectorScreenState();
}

class _VerseSelectorScreenState extends ConsumerState<VerseSelectorScreen> {
  final _refCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _themeCtrl = TextEditingController();
  int _difficulty = 3;
  String _search = '';
  bool _showAddForm = false;
  Verse? _editingVerse;
  final List<Verse> _selectedVerses = [];

  @override
  void dispose() {
    _refCtrl.dispose();
    _contentCtrl.dispose();
    _themeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versesAsync = ref.watch(versesListProvider);
    final verseManager = ref.watch(verseManagerProvider);

    // 이미 사용된 구절 ID 목록 가져오기
    final usedIdsAsync = widget.sessionId != null
        ? ref.watch(usedVerseIdsProvider(widget.sessionId!))
        : const AsyncData<List<int>>([]);

    return Scaffold(
      backgroundColor: BibleColors.navyDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.requiredCount != null
            ? '구절 선택 (${_selectedVerses.length}/${widget.requiredCount})'
            : '구절 선택'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
            icon: Icon(
              _showAddForm ? Icons.close : Icons.add_circle,
              color: BibleColors.gold,
              size: 28,
            ),
          ),
          if (widget.isMultiSelect)
            TextButton(
              onPressed: (widget.requiredCount != null
                      ? _selectedVerses.length != widget.requiredCount
                      : _selectedVerses.isEmpty)
                  ? null
                  : () => widget.onVersesSelected!(_selectedVerses),
              child: Text(
                widget.requiredCount != null
                    ? '완료'
                    : '확인 (${_selectedVerses.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (widget.requiredCount != null
                          ? _selectedVerses.length != widget.requiredCount
                          : _selectedVerses.isEmpty)
                      ? Colors.white30
                      : BibleColors.gold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── 구절 추가 폼 ──
          if (_showAddForm) ...[
            _buildAddForm(theme, verseManager),
            const Divider(height: 1),
          ],

          // ── 검색 ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: '구절 검색 (책·내용·주제)',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.search, color: BibleColors.ink),
                fillColor: BibleColors.cream,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCDD0E3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCDD0E3)),
                ),
              ),
            ),
          ),

          // ── 구절 목록 ──
          Expanded(
            child: versesAsync.when(
              data: (verses) {
                final filtered = _search.isEmpty
                    ? verses
                    : verses
                        .where((v) =>
                            v.reference.toLowerCase().contains(_search) ||
                            v.content.toLowerCase().contains(_search) ||
                            (v.theme?.toLowerCase().contains(_search) ?? false))
                        .toList();

                final usedIds = usedIdsAsync.valueOrNull ?? [];

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      '구절이 없습니다.\n상단의 + 버튼으로 추가하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final verse = filtered[index];
                    final isUsed = usedIds.contains(verse.id);
                    final isSelected =
                        _selectedVerses.any((v) => v.id == verse.id);

                    return _VerseCard(
                      verse: verse,
                      isUsed: isUsed,
                      isSelected: isSelected,
                      onTap: () {
                        if (widget.isMultiSelect) {
                          setState(() {
                            if (isSelected) {
                              _selectedVerses
                                  .removeWhere((v) => v.id == verse.id);
                            } else {
                              _selectedVerses.add(verse);
                            }
                          });
                        } else {
                          widget.onVerseSelected!(verse);
                        }
                      },
                      onLongPress: () {
                        setState(() {
                          _showAddForm = true;
                          _editingVerse = verse;
                          _refCtrl.text = verse.reference;
                          _contentCtrl.text = verse.content;
                          _themeCtrl.text = verse.theme ?? '';
                          _difficulty = verse.difficulty;
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: BibleColors.gold),
              ),
              error: (e, _) => Center(
                child: Text('오류: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm(ThemeData theme, AsyncValue<void> state) {
    return Container(
      color: BibleColors.cream,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_editingVerse == null ? '새 구절 추가' : '구절 내용 수정',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )),
              if (_editingVerse != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _editingVerse = null;
                      _refCtrl.clear();
                      _contentCtrl.clear();
                      _themeCtrl.clear();
                      _difficulty = 3;
                    });
                  },
                  child:
                      const Text('취소', style: TextStyle(color: Colors.black45)),
                ),
            ],
          ),
          const Gap(12),
          TextField(
            controller: _refCtrl,
            decoration: const InputDecoration(
              labelText: '참조 (예: 창세기 1:1)',
            ),
          ),
          const Gap(8),
          TextField(
            controller: _themeCtrl,
            decoration: const InputDecoration(
              labelText: '주제 (예: 믿음, 사랑)',
            ),
          ),
          const Gap(8),
          TextField(
            controller: _contentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '본문 내용',
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded, color: AppTheme.kNavy),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    setState(() {
                      _contentCtrl.text = data!.text!;
                    });
                  }
                },
                tooltip: '클립보드에서 붙여넣기',
              ),
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Text('난이도: $_difficulty  ',
                  style: const TextStyle(
                      color: AppTheme.kNavy, fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _difficulty.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_difficulty',
                  activeColor: AppTheme.kNavy,
                  inactiveColor: const Color(0xFFCDD0E3),
                  onChanged: (v) => setState(() => _difficulty = v.round()),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      if (_refCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
                        return;
                      }

                      if (_editingVerse == null) {
                        await ref.read(verseManagerProvider.notifier).addVerse(
                              reference: _refCtrl.text.trim(),
                              content: _contentCtrl.text.trim(),
                              difficulty: _difficulty,
                              theme: _themeCtrl.text.trim().isEmpty
                                  ? null
                                  : _themeCtrl.text.trim(),
                            );
                      } else {
                        await ref
                            .read(verseManagerProvider.notifier)
                            .updateVerse(
                              id: _editingVerse!.id,
                              reference: _refCtrl.text.trim(),
                              content: _contentCtrl.text.trim(),
                              difficulty: _difficulty,
                              theme: _themeCtrl.text.trim().isEmpty
                                  ? null
                                  : _themeCtrl.text.trim(),
                            );
                      }

                      _refCtrl.clear();
                      _contentCtrl.clear();
                      _themeCtrl.clear();
                      setState(() {
                        _difficulty = 3;
                        _showAddForm = false;
                        _editingVerse = null;
                      });
                    },
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_editingVerse == null ? '추가' : '수정 완료'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.isUsed,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
  });

  final Verse verse;
  final bool isUsed;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final stars = '⭐' * verse.difficulty;

    return Opacity(
      opacity: isUsed ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: isUsed ? Colors.grey.shade50 : AppTheme.kSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? AppTheme.kGold
                : (isUsed ? Colors.grey.shade300 : const Color(0xFFCDD0E3)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: (isUsed && !isSelected)
              ? null
              : onTap, // 이미 사용된 구절은 선택 불가 (필요시 수정 가능)
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUsed
                            ? Colors.grey.shade200
                            : AppTheme.kNavy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        verse.reference,
                        style: TextStyle(
                          color: isUsed ? Colors.black38 : AppTheme.kNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUsed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '이미 선택됨',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (verse.theme != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          verse.theme!,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.kGold, size: 20)
                    else
                      Text(stars, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const Gap(12),
                Text(
                  verse.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUsed ? Colors.black26 : Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                    decoration: isUsed ? TextDecoration.lineThrough : null,
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
