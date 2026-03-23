import 'dart:math';

/// NLP 기반 정확도 계산기
/// 개역개정 정답 원문과 사용자 입력값을 비교하여 0~100점 반환
class AccuracyCalculator {
  /// 메인 정확도 계산 함수
  /// [answer]: 개역개정 정답 원문
  /// [userInput]: 사용자 입력값
  static double calculate(String answer, String userInput) {
    if (userInput.trim().isEmpty) return 0.0;

    final normalizedAnswer = _normalize(answer);
    final normalizedInput = _normalize(userInput);

    // 완전 일치
    if (normalizedAnswer == normalizedInput) return 100.0;

    // 입력이 정답보다 훨씬 길면 패널티
    if (normalizedInput.length > normalizedAnswer.length * 2) {
      return 0.0;
    }

    // 토큰 F1 Score (단어 단위, 70% 가중치)
    final tokenScore = _tokenF1Score(normalizedAnswer, normalizedInput);

    // Levenshtein 유사도 (문자 단위, 30% 가중치)
    final editScore =
        _levenshteinSimilarity(normalizedAnswer, normalizedInput);

    // 가중 평균
    final score = tokenScore * 0.7 + editScore * 0.3;
    return score.clamp(0.0, 100.0);
  }

  /// 실시간 진행도 계산 (0.0 ~ 1.0)
  /// 입력 길이 / 정답 길이 기반
  static double calculateProgress(String answer, String userInput) {
    if (answer.isEmpty) return 0.0;
    final ratio = userInput.trim().length / answer.trim().length;
    return ratio.clamp(0.0, 1.0);
  }

  /// 텍스트 전처리
  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s가-힣ㄱ-ㅎㅏ-ㅣ]'), '') // 특수문자 제거
        .replaceAll(RegExp(r'\s+'), ' ') // 연속 공백 → 단일 공백
        .trim()
        .toLowerCase();
  }

  /// 토큰 기반 F1 Score (단어 순서 무관 정확도)
  static double _tokenF1Score(String answer, String input) {
    final answerTokens = answer.split(' ').where((t) => t.isNotEmpty).toList();
    final inputTokens = input.split(' ').where((t) => t.isNotEmpty).toList();

    if (answerTokens.isEmpty || inputTokens.isEmpty) return 0.0;

    // 부분 일치 허용 (오타 1~2자 관대)
    int matches = 0;
    final usedAnswerIndices = <int>{};

    for (final inputToken in inputTokens) {
      for (int i = 0; i < answerTokens.length; i++) {
        if (usedAnswerIndices.contains(i)) continue;
        final similarity = _tokenSimilarity(inputToken, answerTokens[i]);
        if (similarity >= 0.75) {
          // 75% 이상 유사하면 일치 처리
          matches++;
          usedAnswerIndices.add(i);
          break;
        }
      }
    }

    if (matches == 0) return 0.0;

    final precision = matches / inputTokens.length;
    final recall = matches / answerTokens.length;
    return 2 * precision * recall / (precision + recall) * 100;
  }

  /// 토큰 단위 유사도 (0.0 ~ 1.0)
  static double _tokenSimilarity(String a, String b) {
    if (a == b) return 1.0;
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 1.0;
    final distance = _levenshteinDistance(a, b);
    return 1 - distance / maxLen;
  }

  /// 문자 기반 Levenshtein 유사도 (0.0 ~ 100.0)
  static double _levenshteinSimilarity(String a, String b) {
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 100.0;
    final distance = _levenshteinDistance(a, b);
    return (1 - distance / maxLen) * 100;
  }

  /// Levenshtein 편집 거리
  static int _levenshteinDistance(String s, String t) {
    final m = s.length;
    final n = t.length;

    if (m == 0) return n;
    if (n == 0) return m;

    // 성능 최적화: 길이가 너무 다르면 최대값 반환
    if ((m - n).abs() > max(m, n) * 0.5) return max(m, n);

    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (s[i - 1] == t[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                  .reduce(min);
        }
      }
    }

    return dp[m][n];
  }
}
