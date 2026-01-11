import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from modules.heuristics import HeuristicsAnalyzer


def main():
    print("=" * 60)
    print("ДЕМОНСТРАЦИЯ ЭВРИСТИЧЕСКИХ ПРАВИЛ")
    print("=" * 60)

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    analyzer = HeuristicsAnalyzer(data_dir=os.path.join(base_dir, 'data'))

    test_cases = [
        ("https://sberrbank.ru/login", "Typosquatting"),
        ("sber://transfer?account=79001234567&sum=50000", "Deep Link"),
        ("https://xn--80ak6aa92e.com/login", "Punycode"),
        ("https://x7k2m9pq.com/malware", "DGA-домен"),
        ("https://qr.nspk.ru/BD100004S43DMVH01JB9CKJL8V8Q1TU9?type=01", "СБП"),
        ("https://malware-site.com/virus.apk", "Malware extension"),
        ("tg://resolve?domain=scam_bot", "Telegram Deep Link"),
        ("https://alfabannk.ru/auth", "Typosquatting Альфа-банк"),
    ]

    for i, (url, desc) in enumerate(test_cases, 1):
        print(f"\n{'-' * 60}")
        print(f"ТЕСТ #{i}: {desc}")
        print(f"{'-' * 60}")
        print(f"URL: {url}")
        result = analyzer.analyze(url)
        print(f"Вердикт: {result['verdict']}")
        print(f"Детали: {result['details']}")
        print(f"Время: {result['time_ms']:.2f} мс")

    print(f"\n{'=' * 60}")
    print("ЗАВЕРШЕНО")
    print("=" * 60)


if __name__ == '__main__':
    main()
