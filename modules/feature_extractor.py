import re
import math
import os
from urllib.parse import urlparse

try:
    from Levenshtein import distance as levenshtein_distance
except ImportError:
    def levenshtein_distance(s1, s2):
        if len(s1) < len(s2):
            return levenshtein_distance(s2, s1)
        if len(s2) == 0:
            return len(s1)
        previous_row = range(len(s2) + 1)
        for i, c1 in enumerate(s1):
            current_row = [i + 1]
            for j, c2 in enumerate(s2):
                insertions = previous_row[j + 1] + 1
                deletions = current_row[j] + 1
                substitutions = previous_row[j] + (c1 != c2)
                current_row.append(min(insertions, deletions, substitutions))
            previous_row = current_row
        return previous_row[-1]


class FeatureExtractor:
    SPECIAL_CHARS = ['-', '_', '@', '&', '=', '?', '%']
    IP_PATTERN = re.compile(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')
    DEEP_LINK_SCHEMES = ['tg://', 'sber://', 'bank://', 'ton://',
                         'whatsapp://', 'tinkoff://', 'alfa://',
                         'vtb://', 'sberpay://']

    def __init__(self, data_dir='data'):
        self.data_dir = data_dir
        self.brand_whitelist = self._load_whitelist('whitelist_brands.txt')

    def _load_whitelist(self, filename):
        filepath = os.path.join(self.data_dir, filename)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return [line.strip().lower() for line in f if line.strip()]
        except FileNotFoundError:
            return []

    def _extract_domain(self, url):
        try:
            url_lower = url.lower()
            for scheme in self.DEEP_LINK_SCHEMES:
                if url_lower.startswith(scheme):
                    return url.split('://')[1].split('/')[0].split('?')[0]
            parsed = urlparse(url)
            domain = parsed.netloc or parsed.path.split('/')[0]
            if ':' in domain:
                domain = domain.split(':')[0]
            return domain.lower()
        except Exception:
            return url.split('/')[0].lower()

    def _calculate_entropy(self, text):
        if not text:
            return 0.0
        freq = {}
        for char in text:
            freq[char] = freq.get(char, 0) + 1
        entropy = 0.0
        length = len(text)
        for count in freq.values():
            p = count / length
            entropy -= p * math.log2(p)
        return entropy

    def extract(self, url):
        domain = self._extract_domain(url)
        parts = domain.split('.')
        domain_name = parts[0] if len(parts) > 1 else domain

        clean_domain = domain.replace('www.', '')
        min_dist = float('inf')
        for brand in self.brand_whitelist:
            dist = levenshtein_distance(clean_domain, brand)
            if dist < min_dist:
                min_dist = dist

        return [
            len(url) / 200.0,
            domain.count('.'),
            sum(url.count(c) for c in self.SPECIAL_CHARS),
            1 if self.IP_PATTERN.match(domain) else 0,
            self._calculate_entropy(domain_name),
            min_dist if min_dist != float('inf') else 10
        ]

    def get_feature_names(self):
        return ['url_length', 'dots_count', 'special_chars', 'has_ip', 'entropy', 'levenshtein_min']


if __name__ == '__main__':
    extractor = FeatureExtractor()
    test_urls = [
        "https://sberbank.ru/login",
        "https://sberrbank.ru/login",
        "https://192.168.1.1/admin",
        "https://x7k2m9pq.com/malware",
        "sber://transfer?account=79001234567&sum=50000"
    ]
    print("Признаки:", extractor.get_feature_names())
    for url in test_urls:
        print(f"\nURL: {url}")
        print(f"Признаки: {extractor.extract(url)}")
