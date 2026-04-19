import 'package:fuzzywuzzy/fuzzywuzzy.dart';

/// Helper class for fuzzy string matching
/// Used to match Stock names with VipItem names despite variations
class FuzzyMatcher {
  /// Normalizes a string for matching:
  /// - Removes accents/diacritics
  /// - Converts to uppercase
  /// - Trims whitespace
  /// - Normalizes punctuation
  static String normalize(String text) {
    // Remove accents
    String normalized = _removeAccents(text);

    // Uppercase and trim
    normalized = normalized.toUpperCase().trim();

    // Normalize common variations
    normalized = normalized
        .replaceAll(',', '.') // "4,5" -> "4.5"
        .replaceAll(RegExp(r'\s+'), ' '); // Multiple spaces -> single space

    return normalized;
  }

  /// Removes accent marks from characters
  static String _removeAccents(String text) {
    const withAccents = 'ÁáÓóÉéÍíÚÜú';
    const withoutAccents = 'AaOoEeIiUUu';

    String result = text;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Calculates similarity between two strings using Levenshtein ratio
  /// Returns 0-100 (100 = identical)
  static int similarity(String a, String b) {
    final normalizedA = normalize(a);
    final normalizedB = normalize(b);

    return ratio(normalizedA, normalizedB);
  }

  /// Finds the best match for a query string from a list of candidates
  /// Returns null if no match meets the minimum confidence threshold
  static MatchResult? findBestMatch(
    String query,
    List<String> candidates, {
    int minConfidence = 90,
  }) {
    if (candidates.isEmpty) return null;

    final normalizedQuery = normalize(query);

    int bestScore = 0;
    String? bestMatch;
    int? bestIndex;

    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final normalizedCandidate = normalize(candidate);
      final score = ratio(normalizedQuery, normalizedCandidate);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = candidate;
        bestIndex = i;
      }
    }

    if (bestScore >= minConfidence && bestMatch != null) {
      return MatchResult(
        match: bestMatch,
        score: bestScore,
        index: bestIndex!,
      );
    }

    return null;
  }

  /// Partial ratio matching - useful for matching substrings
  /// "CORDON 4.5mm NEGRO" vs "CORDON 4.5" -> high score
  static int partialSimilarity(String a, String b) {
    final normalizedA = normalize(a);
    final normalizedB = normalize(b);

    return partialRatio(normalizedA, normalizedB);
  }

  /// Token sort ratio - ignores word order
  /// "NEGRO CORDON 4.5" vs "CORDON 4.5 NEGRO" -> 100
  static int tokenSortSimilarity(String a, String b) {
    final normalizedA = normalize(a);
    final normalizedB = normalize(b);

    return tokenSortPartialRatio(normalizedA, normalizedB);
  }

  /// Weighted match combining multiple strategies
  /// Returns the highest score from different matching approaches
  static int weightedSimilarity(String a, String b) {
    final scores = [
      similarity(a, b),
      partialSimilarity(a, b),
      tokenSortSimilarity(a, b),
    ];

    return scores.reduce((max, score) => score > max ? score : max);
  }
}

/// Result of a fuzzy match operation
class MatchResult {
  final String match;
  final int score; // 0-100
  final int index; // Index in original candidates list

  MatchResult({
    required this.match,
    required this.score,
    required this.index,
  });

  @override
  String toString() => 'MatchResult(match: $match, score: $score, index: $index)';
}
