int levenshtein(String s1, String s2) {
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  List<List<int>> matrix = List.generate(
    s1.length + 1,
    (i) => List.generate(s2.length + 1, (j) => i == 0 ? j : (j == 0 ? i : 0)),
  );

  for (int i = 1; i <= s1.length; i++) {
    for (int j = 1; j <= s2.length; j++) {
      int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  return matrix[s1.length][s2.length];
}
