import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from modules.ml_classifier import MLClassifier


def main():
    print("=" * 60)
    print("ДЕМОНСТРАЦИЯ ML-КЛАССИФИКАТОРА")
    print("=" * 60)

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    try:
        classifier = MLClassifier(
            models_dir=os.path.join(base_dir, 'models'),
            data_dir=os.path.join(base_dir, 'data')
        )
    except RuntimeError as e:
        print(f"\nОшибка: {e}")
        print("\nСначала обучите модель: python models/train_model.py")
        return

    test_cases = [
        ("https://alfabannk.ru/login", "Typosquatting"),
        ("https://gooogle.com/auth", "Typosquatting Google"),
        ("https://sberbank.ru/personal", "Легитимный"),
        ("https://gosuslugi.ru/login", "Легитимный"),
        ("https://192.168.1.1/admin/panel", "IP-адрес"),
        ("https://qw3rt7y9.xyz/download", "Подозрительный"),
    ]

    for i, (url, desc) in enumerate(test_cases, 1):
        print(f"\n{'-' * 60}")
        print(f"ТЕСТ #{i}: {desc}")
        print(f"{'-' * 60}")
        print(f"URL: {url}")
        result = classifier.predict(url)
        print(f"Вердикт: {result['verdict'].upper()}")
        print("Вероятности:")
        for label, prob in sorted(result['probabilities'].items()):
            bar = '#' * int(prob * 20)
            print(f"  {label:12s}: {prob:.3f} {bar}")
        print(f"Время: {result['time_ms']:.2f} мс")

    print(f"\n{'=' * 60}")
    print("ЗАВЕРШЕНО")
    print("=" * 60)


if __name__ == '__main__':
    main()
