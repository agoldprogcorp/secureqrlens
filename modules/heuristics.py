import re
import math
import time
import os
from urllib.parse import urlparse

try:
    import idna
except ImportError:
    idna = None

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


class HeuristicsAnalyzer:
    MALWARE_EXTENSIONS = ['.apk', '.exe', '.scr', '.bat', '.vbs']
    DEEP_LINK_SCHEMES = [
        'tg://', 'sber://', 'bank://', 'ton://', 'whatsapp://',
        'tinkoff://', 'alfa://', 'vtb://', 'sberpay://'
    ]
    ENTROPY_THRESHOLD = 4.5
    LEVENSHTEIN_THRESHOLD = 2

    def __init__(self, data_dir='data'):
        self.data_dir = data_dir
        self.sbp_whitelist = self._load_whitelist('sbp_whitelist.txt')
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
            for scheme in self.DEEP_LINK_SCHEMES:
                if url.lower().startswith(scheme):
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

    def _check_sbp_whitelist(self, domain):
        for sbp_domain in self.sbp_whitelist:
            if domain == sbp_domain or domain.endswith('.' + sbp_domain):
                return True
        return False

    def _check_malware_extension(self, url):
        url_lower = url.lower()
        for ext in self.MALWARE_EXTENSIONS:
            if url_lower.endswith(ext):
                return ext
        return None

    def _check_deep_link(self, url):
        url_lower = url.lower()
        for scheme in self.DEEP_LINK_SCHEMES:
            if url_lower.startswith(scheme):
                return scheme
        return None

    def _check_punycode(self, url, domain):
        if 'xn--' not in url.lower():
            return None
        if idna is None:
            return None
        try:
            decoded_domain = idna.decode(domain)
            has_cyrillic = bool(re.search(r'[а-яА-ЯёЁ]', decoded_domain))
            has_latin = bool(re.search(r'[a-zA-Z]', decoded_domain))
            if has_cyrillic and has_latin:
                return decoded_domain
            if has_cyrillic:
                return decoded_domain
        except Exception:
            pass
        return None

    def _check_typosquatting(self, domain):
        clean_domain = domain.replace('www.', '')
        min_distance = float('inf')
        closest_brand = None
        for brand in self.brand_whitelist:
            if clean_domain == brand:
                return None, None
            dist = levenshtein_distance(clean_domain, brand)
            if dist < min_distance:
                min_distance = dist
                closest_brand = brand
        if 0 < min_distance <= self.LEVENSHTEIN_THRESHOLD:
            return min_distance, closest_brand
        return None, None

    def _check_high_entropy(self, domain):
        parts = domain.split('.')
        domain_name = parts[0] if len(parts) > 1 else domain
        entropy = self._calculate_entropy(domain_name)
        if entropy > self.ENTROPY_THRESHOLD:
            return entropy
        return None

    def analyze(self, url):
        start_time = time.time()
        domain = self._extract_domain(url)

        if self._check_sbp_whitelist(domain):
            return {
                'verdict': 'SAFE',
                'details': f'Домен {domain} в whitelist СБП',
                'time_ms': (time.time() - start_time) * 1000
            }

        malware_ext = self._check_malware_extension(url)
        if malware_ext:
            return {
                'verdict': 'DANGER',
                'details': f'Обнаружено опасное расширение: {malware_ext}',
                'time_ms': (time.time() - start_time) * 1000
            }

        deep_link = self._check_deep_link(url)
        if deep_link:
            return {
                'verdict': 'SUSPICIOUS',
                'details': f'Обнаружена Deep Link схема: {deep_link}',
                'time_ms': (time.time() - start_time) * 1000
            }

        decoded = self._check_punycode(url, domain)
        if decoded:
            return {
                'verdict': 'DANGER',
                'details': f'IDN Homograph Attack: {domain} -> {decoded}',
                'time_ms': (time.time() - start_time) * 1000
            }

        typo_dist, closest = self._check_typosquatting(domain)
        if typo_dist is not None:
            return {
                'verdict': 'DANGER',
                'details': f'Typosquatting: расстояние Левенштейна = {typo_dist} до {closest}',
                'time_ms': (time.time() - start_time) * 1000
            }

        entropy = self._check_high_entropy(domain)
        if entropy is not None:
            return {
                'verdict': 'SUSPICIOUS',
                'details': f'Высокая энтропия домена: {entropy:.2f} (порог {self.ENTROPY_THRESHOLD})',
                'time_ms': (time.time() - start_time) * 1000
            }

        return {
            'verdict': 'UNKNOWN',
            'details': 'Эвристики не определили вердикт, требуется ML-анализ',
            'time_ms': (time.time() - start_time) * 1000
        }


if __name__ == '__main__':
    analyzer = HeuristicsAnalyzer()
    test_urls = [
        "https://qr.nspk.ru/BD100004S43DMVH01JB9CKJL8V8Q1TU9",
        "https://malware.com/virus.apk",
        "sber://transfer?sum=50000",
        "https://xn--80ak6aa92e.com/login",
        "https://sberrbank.ru/login",
        "https://x7k2m9pq.com/malware",
        "https://google.com"
    ]
    for url in test_urls:
        result = analyzer.analyze(url)
        print(f"\nURL: {url}")
        print(f"Вердикт: {result['verdict']}")
        print(f"Детали: {result['details']}")
        print(f"Время: {result['time_ms']:.2f} мс")
