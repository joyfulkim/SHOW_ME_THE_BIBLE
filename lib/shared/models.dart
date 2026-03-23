/// 사용자 프로필 모델
class Profile {
  final String id;
  final String nickname;
  final String role; // 'admin' | 'contestant'
  final double totalScore;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.nickname,
    required this.role,
    required this.totalScore,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String? ?? '',
        nickname: json['nickname'] as String? ?? 'User',
        role: json['role'] as String? ?? 'contestant',
        totalScore: (json['total_score'] as num?)?.toDouble() ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'role': role,
        'total_score': totalScore,
        'created_at': createdAt.toIso8601String(),
      };
}

/// 게임 세션 모델
class GameSession {
  final String id;
  final String? title;
  final String status; // 'waiting' | 'round_active' | 'round_locked' | 'finished'
  final String gameMode; // 'live' | 'speed'
  final int currentRound;
  final int totalRounds;
  final bool isPaused;
  final bool sttEnabled;
  final bool gradingCompleted;
  final String? createdBy;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;

  const GameSession({
    required this.id,
    this.title,
    required this.status,
    required this.gameMode,
    required this.currentRound,
    required this.totalRounds,
    required this.isPaused,
    required this.sttEnabled,
    required this.gradingCompleted,
    this.createdBy,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
  });

  bool get isWaiting => status == 'waiting';
  bool get isRoundActive => status == 'round_active';
  bool get isRoundLocked => status == 'round_locked';
  bool get isFinished => status == 'finished';
  bool get canInput => isRoundActive && !isPaused;
  bool get isLiveMode => gameMode == 'live';
  bool get isSpeedMode => gameMode == 'speed';

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
        id: json['id'] as String? ?? '',
        title: json['title'] as String?,
        status: json['status'] as String? ?? 'waiting',
        gameMode: json['game_mode'] as String? ?? 'live',
        currentRound: (json['current_round'] as num?)?.toInt() ?? 1,
        totalRounds: (json['total_rounds'] as num?)?.toInt() ?? 1,
        isPaused: json['is_paused'] as bool? ?? false,
        sttEnabled: json['stt_enabled'] as bool? ?? true,
        gradingCompleted: json['grading_completed'] as bool? ?? false,
        createdBy: json['created_by'] as String?,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        finishedAt: json['finished_at'] != null
            ? DateTime.parse(json['finished_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

/// 구절 (문제) 모델
class Verse {
  final int id;
  final String reference;
  final String content;
  final int difficulty;
  final String? theme;

  const Verse({
    required this.id,
    required this.reference,
    required this.content,
    required this.difficulty,
    this.theme,
  });

  factory Verse.fromJson(Map<String, dynamic> json) => Verse(
        id: (json['id'] as num?)?.toInt() ?? 0,
        reference: json['reference'] as String? ?? '',
        content: json['content'] as String? ?? '',
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        theme: json['theme'] as String?,
      );
}

/// 세션 문제 모델 (구절 포함)
class SessionQuestion {
  final int id;
  final String sessionId;
  final int roundNumber;
  final int verseId;
  final Verse? verse; // JOIN 결과

  const SessionQuestion({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    required this.verseId,
    this.verse,
  });

  factory SessionQuestion.fromJson(Map<String, dynamic> json) =>
      SessionQuestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        sessionId: json['session_id'] as String? ?? '',
        roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
        verseId: (json['verse_id'] as num?)?.toInt() ?? 0,
        verse: json['verses_pool'] != null
            ? Verse.fromJson(json['verses_pool'] as Map<String, dynamic>)
            : null,
      );

  SessionQuestion copyWith({Verse? verse}) {
    return SessionQuestion(
      id: id,
      sessionId: sessionId,
      roundNumber: roundNumber,
      verseId: verseId,
      verse: verse ?? this.verse,
    );
  }
}

/// 제출 모델
class Submission {
  final int id;
  final String sessionId;
  final int roundNumber;
  final String userId;
  final String content;
  final double accuracyScore;
  final double progressRate;
  final bool isFinal;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final Profile? profile; // JOIN 결과

  const Submission({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    required this.userId,
    required this.content,
    required this.accuracyScore,
    required this.progressRate,
    required this.isFinal,
    required this.createdAt,
    this.submittedAt,
    this.profile,
  });

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
        id: (json['id'] as num?)?.toInt() ?? 0,
        sessionId: json['session_id'] as String? ?? '',
        roundNumber: (json['round_number'] as num?)?.toInt() ?? 1,
        userId: json['user_id'] as String? ?? '',
        content: json['input_text'] as String? ?? '',
        accuracyScore: (json['accuracy_score'] as num?)?.toDouble() ?? 0,
        progressRate: (json['progress_rate'] as num?)?.toDouble() ?? 0,
        isFinal: json['is_final'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        profile: json['profiles'] != null
            ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
            : null,
      );
}
