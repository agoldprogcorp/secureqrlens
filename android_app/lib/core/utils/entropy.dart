import 'dart:math';

double calculateEntropy(String s) {
  if (s.isEmpty) return 0;
  
  Map<String, int> freq = {};
  for (var c in s.split('')) {
    freq[c] = (freq[c] ?? 0) + 1;
  }
  
  double ent = 0;
  for (var count in freq.values) {
    double p = count / s.length;
    ent -= p * (log(p) / log(2));
  }
  return ent;
}
