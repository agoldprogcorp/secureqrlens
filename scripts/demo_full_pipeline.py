import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from modules.heuristics import HeuristicsAnalyzer
from modules.ml_classifier import MLClassifier
from modules.redirect_resolver import resolve_redirects, is_shortened_url
from modules.yandex_safebrowsing import check_url_safety


class SecureQRLens:
    def __init__(self, data_dir='data', models_dir='models'):
        self.heuristics = HeuristicsAnalyzer(data_dir=data_dir)
        self.ml_classifier = None
        self.yandex_api_key = os.getenv('YANDEX_SB_API_KEY')
        
        try:
            self.ml_classifier = MLClassifier(models_dir=models_dir, data_dir=data_dir)
        except RuntimeError:
            print("ML-модель не загружена. Только эвристики.")

    def analyze(self, url):
        start_time = time.time()
        
        result = {
            'url': url,
            'redirect_chain': [url],
            'final_url': url,
            'stage1_verdict': None,
            'stage1_details': None,
            'stage2_used': False,
            'yandex_sb': None,
            'final_verdict': None,
            'final_details': None,
            'total_time_ms': 0
        }
        
        if url.startswith(('http://', 'https://')) and is_shortened_url(url):
            print(f"   Раскрытие редиректов...")
            redirect_result = resolve_redirects(url)
            result['redirect_chain'] = redirect_result['chain']
            result['final_url'] = redirect_result['final_url']
            if redirect_result['error']:
                print(f"   Ошибка: {redirect_result['error']}")
        
        url_to_analyze = result['final_url']
        
        heur_result = self.heuristics.analyze(url_to_analyze)
        result['stage1_verdict'] = heur_result['verdict']
        result['stage1_details'] = heur_result['details']
        result['stage1_time_ms'] = heur_result['time_ms']

        if heur_result['verdict'] != 'UNKNOWN':
            result['final_verdict'] = heur_result['verdict']
            result['final_details'] = heur_result['details']
        elif self.ml_classifier:
            ml_result = self.ml_classifier.predict(url_to_analyze)
            result['stage2_used'] = True
            result['stage2_verdict'] = ml_result['verdict']
            result['stage2_probabilities'] = ml_result['probabilities']
            result['stage2_time_ms'] = ml_result['time_ms']
            result['final_verdict'] = ml_result['verdict'].upper()
            max_prob = max(ml_result['probabilities'].values())
            result['final_details'] = f"ML: {ml_result['verdict']} ({max_prob:.1%})"
        else:
            result['final_verdict'] = 'UNKNOWN'
            result['final_details'] = 'ML-модель не загружена'
        
        if self.yandex_api_key and url_to_analyze.startswith(('http://', 'https://')):
            print(f"   Проверка Yandex Safe Browsing...")
            result['yandex_sb'] = check_url_safety(url_to_analyze, self.yandex_api_key)
        
        result['total_time_ms'] = (time.time() - start_time) * 1000
        return result


def main():
    print("=" * 70)
    print("ПОЛНЫЙ ПАЙПЛАЙН SECURE QR LENS")
    print("Редиректы -> Эвристики -> ML -> Yandex Safe Browsing")
    print("=" * 70)

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    system = SecureQRLens(
        data_dir=os.path.join(base_dir, 'data'),
        models_dir=os.path.join(base_dir, 'models')
    )
    
    yandex_status = "включен" if system.yandex_api_key else "не настроен (установите YANDEX_SB_API_KEY)"
    print(f"\nYandex Safe Browsing: {yandex_status}")

    test_cases = [
        ("https://qr.nspk.ru/BD100004S43DMVH01JB9CKJL8V8Q1TU9", "СБП"),
        ("https://sberrbank.ru/login", "Typosquatting"),
        ("sber://transfer?sum=50000", "Deep Link"),
        ("https://xn--80ak6aa92e.com/login", "Punycode"),
        ("https://bit.ly/3xK9mPq", "Сокращённая ссылка"),
        ("https://legitimate-shop.com/product/123", "Неизвестный домен"),
    ]

    for i, (url, desc) in enumerate(test_cases, 1):
        print(f"\n{'-' * 70}")
        print(f"ТЕСТ #{i}: {desc}")
        print(f"{'-' * 70}")
        print(f"URL: {url}")

        result = system.analyze(url)

        if len(result['redirect_chain']) > 1:
            print(f"\nЦепочка редиректов:")
            for j, rurl in enumerate(result['redirect_chain'], 1):
                print(f"   {j}. {rurl}")

        print(f"\nЭТАП 1 (Эвристики):")
        print(f"   Вердикт: {result['stage1_verdict']}")
        print(f"   Детали: {result['stage1_details']}")

        if result['stage2_used']:
            print(f"\nЭТАП 2 (ML):")
            print(f"   Вердикт: {result['stage2_verdict']}")
            print(f"   Вероятности:")
            for label, prob in sorted(result['stage2_probabilities'].items()):
                bar = '#' * int(prob * 20)
                print(f"      {label:12s}: {prob:.3f} {bar}")
        else:
            print(f"\nЭТАП 2: Не потребовался")

        if result['yandex_sb']:
            sb = result['yandex_sb']
            print(f"\nYandex Safe Browsing:")
            if sb['safe'] is True:
                print(f"   Статус: Безопасен")
            elif sb['safe'] is False:
                print(f"   Статус: УГРОЗЫ ОБНАРУЖЕНЫ")
                print(f"   Угрозы: {', '.join(sb['threats'])}")
            else:
                print(f"   Статус: Не удалось проверить ({sb['error']})")

        print(f"\nФИНАЛЬНЫЙ ВЕРДИКТ: {result['final_verdict']}")
        print(f"   Детали: {result['final_details']}")
        print(f"   Общее время: {result['total_time_ms']:.2f} мс")

    print(f"\n{'=' * 70}")
    print("ЗАВЕРШЕНО")
    print("=" * 70)


if __name__ == '__main__':
    main()
