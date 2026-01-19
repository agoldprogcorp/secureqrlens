String? decodePunycode(String domain) {
  try {
    if (!domain.contains('xn--')) return null;
    
    List<String> parts = domain.split('.');
    List<String> decoded = [];
    
    for (String part in parts) {
      if (part.startsWith('xn--')) {
        String encoded = part.substring(4);
        String? result = _decode(encoded);
        if (result != null) {
          decoded.add(result);
        } else {
          decoded.add(part);
        }
      } else {
        decoded.add(part);
      }
    }
    
    return decoded.join('.');
  } catch (e) {
    return null;
  }
}

String? _decode(String input) {
  try {
    const int base = 36;
    const int tmin = 1;
    const int tmax = 26;
    const int skew = 38;
    const int damp = 700;
    const int initialBias = 72;
    const int initialN = 128;
    
    int n = initialN;
    int i = 0;
    int bias = initialBias;
    List<int> output = [];
    
    int basic = input.lastIndexOf('-');
    if (basic > 0) {
      for (int j = 0; j < basic; j++) {
        output.add(input.codeUnitAt(j));
      }
    }
    basic = basic < 0 ? 0 : basic + 1;
    
    for (int index = basic; index < input.length;) {
      int oldi = i;
      int w = 1;
      
      for (int k = base;; k += base) {
        if (index >= input.length) return null;
        
        int digit = _decodeDigit(input.codeUnitAt(index++));
        if (digit >= base) return null;
        
        i += digit * w;
        int t = k <= bias ? tmin : (k >= bias + tmax ? tmax : k - bias);
        
        if (digit < t) break;
        w *= base - t;
      }
      
      bias = _adapt(i - oldi, output.length + 1, oldi == 0);
      n += i ~/ (output.length + 1);
      i %= (output.length + 1);
      output.insert(i, n);
      i++;
    }
    
    return String.fromCharCodes(output);
  } catch (e) {
    return null;
  }
}

int _decodeDigit(int cp) {
  if (cp >= 48 && cp <= 57) return cp - 22;
  if (cp >= 65 && cp <= 90) return cp - 65;
  if (cp >= 97 && cp <= 122) return cp - 97;
  return 999;
}

int _adapt(int delta, int numPoints, bool firstTime) {
  const int base = 36;
  const int tmin = 1;
  const int tmax = 26;
  const int skew = 38;
  const int damp = 700;
  
  delta = firstTime ? delta ~/ damp : delta >> 1;
  delta += delta ~/ numPoints;
  
  int k = 0;
  while (delta > ((base - tmin) * tmax) ~/ 2) {
    delta ~/= base - tmin;
    k += base;
  }
  
  return k + (((base - tmin + 1) * delta) ~/ (delta + skew));
}
