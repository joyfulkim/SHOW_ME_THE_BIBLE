import 'admin_config.dart';
import 'supabase_client.dart';

class CompetitionVerseSeed {
  const CompetitionVerseSeed({
    required this.reference,
    required this.theme,
    required this.content,
    this.difficulty = 3,
  });

  final String reference;
  final String theme;
  final String content;
  final int difficulty;

  Map<String, dynamic> toInsertJson(String? userId,
      {bool includeTheme = true}) {
    return {
      'reference': reference,
      'content': content,
      'difficulty': difficulty,
      if (includeTheme) 'theme': theme,
      'created_by': userId,
    };
  }
}

const competitionVerseSeeds = [
  CompetitionVerseSeed(
    reference: '주기도문',
    theme: '주기도문',
    content:
        '하늘에 계신 우리 아버지여 이름이 거룩히 여김을 받으시오며 나라가 임하시오며 뜻이 하늘에서 이루어진 것 같이 땅에서도 이루어지이다 오늘 우리에게 일용할 양식을 주시옵고 우리가 우리에게 죄 지은 자를 사하여 준 것 같이 우리 죄를 사하여 주시옵고 우리를 시험에 들게 하지 마시옵고 다만 악에서 구하시옵소서 (나라와 권세와 영광이 아버지께 영원히 있사옵나이다 아멘)',
  ),
  CompetitionVerseSeed(
    reference: '로마서 8:1-2',
    theme: '정체성 : 나는 누구인가?',
    content:
        '그러므로 이제 그리스도 예수 안에 있는 자에게는 결코 정죄함이 없나니 이는 그리스도 예수 안에 있는 생명의 성령의 법이 죄와 사망의 법에서 너를 해방하였음이라',
  ),
  CompetitionVerseSeed(
    reference: '에베소서 2:8-9',
    theme: '은혜 : 나는 무엇으로 살고 있는가?',
    content:
        '너희는 그 은혜에 의하여 믿음으로 말미암아 구원을 받았으니 이것은 너희에게서 난 것이 아니요 하나님의 선물이라 행위에서 난 것이 아니니 이는 누구든지 자랑하지 못하게 함이라',
  ),
  CompetitionVerseSeed(
    reference: '로마서 5:8',
    theme: '사랑 : 하나님은 어떤 분인가?',
    content:
        '우리가 아직 죄인 되었을 때에 그리스도께서 우리를 위하여 죽으심으로 하나님께서 우리에 대한 자기의 사랑을 확증하셨느니라',
  ),
  CompetitionVerseSeed(
    reference: '마태복음 6:20-21',
    theme: '우상해체 - 나는 무엇에 의존하는가?',
    content:
        '오직 너희를 위하여 보물을 하늘에 쌓아 두라 거기는 좀이나 동록이 해하지 못하며 도둑이 구멍을 뚫지도 못하고 도둑질도 못하느니라 네 보물 있는 그 곳에는 네 마음도 있느니라',
  ),
  CompetitionVerseSeed(
    reference: '빌립보서 4:6-7',
    theme: '불안 - 나는 무엇을 두려워하는가?',
    content:
        '아무 것도 염려하지 말고 다만 모든 일에 기도와 간구로, 너희 구할 것을 감사함으로 하나님께 아뢰라 그리하면 모든 지각에 뛰어난 하나님의 평강이 그리스도 예수 안에서 너희 마음과 생각을 지키시리라',
  ),
  CompetitionVerseSeed(
    reference: '마태복음 5:16',
    theme: '소명 - 나는 왜 살아가는가?',
    content:
        '이같이 너희 빛이 사람 앞에 비치게 하여 그들로 너희 착한 행실을 보고 하늘에 계신 너희 아버지께 영광을 돌리게 하라',
  ),
  CompetitionVerseSeed(
    reference: '로마서 8:18',
    theme: '고난 - 실패와 고통을 어떻게 해석할 것인가?',
    content: '생각하건대 현재의 고난은 장차 우리에게 나타날 영광과 비교할 수 없도다',
  ),
  CompetitionVerseSeed(
    reference: '고린도후서 5:17',
    theme: '변화 - 어떻게 실제로 변하는가?',
    content: '그런즉 누구든지 그리스도 안에 있으면 새로운 피조물이라 이전 것은 지나갔으니 보라 새 것이 되었도다',
  ),
  CompetitionVerseSeed(
    reference: '미가 6:8',
    theme: '겸손 - 나는 어떤 태도로 살아야 하는가?',
    content:
        '사람아 주께서 선한 것이 무엇임을 네게 보이셨나니 여호와께서 네게 구하시는 것은 오직 정의를 행하며 인자를 사랑하며 겸손하게 네 하나님과 함께 행하는 것이 아니냐',
  ),
  CompetitionVerseSeed(
    reference: '마태복음 28:19-20',
    theme: '사명 - 교회의 존재 이유는 무엇인가?',
    content:
        '그러므로 너희는 가서 모든 민족을 제자로 삼아 아버지와 아들과 성령의 이름으로 침례를 베풀고 내가 너희에게 분부한 모든 것을 가르쳐 지키게 하라 볼지어다 내가 세상 끝날까지 너희와 항상 함께 있으리라 하시니라',
  ),
];

Future<void> ensureCompetitionVersesRegistered() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final profileRows =
      await supabase.from('profiles').select('role').eq('id', user.id).limit(1);
  final profile = profileRows.isNotEmpty ? profileRows.first : null;
  final isConfiguredAdmin = isConfiguredAdminEmail(user.email);
  if (isConfiguredAdmin && profile?['role'] != 'admin') {
    if (profile == null) {
      await supabase.from('profiles').insert({
        'id': user.id,
        'nickname': user.userMetadata?['nickname'] ?? user.email ?? 'Admin',
        'role': 'admin',
      });
    } else {
      await supabase
          .from('profiles')
          .update({'role': 'admin'}).eq('id', user.id);
    }
  }

  final canManageVerses = profile?['role'] == 'admin' || isConfiguredAdmin;
  if (!canManageVerses) return;

  final references =
      competitionVerseSeeds.map((seed) => seed.reference).toSet().toList();
  final existingRows = await supabase
      .from('verses_pool')
      .select('id, reference, content, difficulty, theme')
      .inFilter('reference', references);

  final existingByKey = <String, Map<String, dynamic>>{};
  for (final row in existingRows as List) {
    final map = row as Map<String, dynamic>;
    existingByKey[
        _seedKey(map['reference'] as String?, map['theme'] as String?)] = map;
  }

  final inserts = <Map<String, dynamic>>[];
  for (final seed in competitionVerseSeeds) {
    final existing = existingByKey[_seedKey(seed.reference, seed.theme)];
    if (existing == null) {
      inserts.add(seed.toInsertJson(user.id));
      continue;
    }

    final contentChanged = existing['content'] != seed.content;
    final difficultyChanged = existing['difficulty'] != seed.difficulty;
    if (contentChanged || difficultyChanged) {
      await supabase.from('verses_pool').update({
        'content': seed.content,
        'difficulty': seed.difficulty,
      }).eq('id', existing['id']);
    }
  }

  if (inserts.isEmpty) return;
  try {
    await supabase.from('verses_pool').insert(inserts);
  } catch (error) {
    if (!error.toString().contains('theme')) rethrow;
    await supabase.from('verses_pool').insert(
          inserts
              .map(
                (insert) => Map<String, dynamic>.of(insert)..remove('theme'),
              )
              .toList(),
        );
  }
}

String _seedKey(String? reference, String? theme) =>
    '${reference ?? ''}\u0000${theme ?? ''}';
