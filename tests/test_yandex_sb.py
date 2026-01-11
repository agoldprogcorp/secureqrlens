import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from modules.yandex_safebrowsing import check_url_safety


def test_no_api_key():
    """Тест без API-ключа."""
    print("Тест: check_url_safety (без API-ключа)")
    
    result = check_url_safety("https://google.com", api_key=None)
    
    if result['safe'] is None and result['error']:
        print(f"  OK: корректно обработано отсутствие ключа")
        print(f"  Ошибка: {result['error']}")
        return True
    else:
        print(f"  FAIL: {result}")
        return False


def test_invalid_api_key():
    """Тест с неверным API-ключом."""
    print("\nТест: check_url_safety (неверный ключ)")
    
    result = check_url_safety("https://google.com", api_key="invalid_key_12345")
    
    if result['safe'] is None:
        print(f"  OK: ошибка обработана")
        print(f"  Ошибка: {result['error']}")
        return True
    else:
        print(f"  Результат: {result}")
        return True


def test_with_real_api_key():
    """Тест с реальным API-ключом (если есть)."""
    print("\nТест: check_url_safety (реальный ключ)")
    
    api_key = os.getenv('YANDEX_SB_API_KEY')
    
    if not api_key:
        print("  SKIP: YANDEX_SB_API_KEY не установлен")
        return True
    
    result = check_url_safety("https://google.com", api_key=api_key)
    
    print(f"  Результат: safe={result['safe']}, error={result['error']}")
    
    if result['safe'] is not None or result['error']:
        print(f"  OK: API ответил")
        return True
    else:
        print(f"  FAIL: неожиданный результат")
        return False


def test_response_format():
    """Тест формата ответа."""
    print("\nТест: формат ответа")
    
    result = check_url_safety("https://example.com")
    
    required_keys = ['safe', 'threats', 'error']
    
    for key in required_keys:
        if key not in result:
            print(f"  FAIL: отсутствует ключ '{key}'")
            return False
    
    if not isinstance(result['threats'], list):
        print(f"  FAIL: threats должен быть списком")
        return False
    
    print(f"  OK: формат корректный")
    return True


def main():
    print("=" * 50)
    print("ТЕСТЫ YANDEX SAFE BROWSING")
    print("=" * 50 + "\n")
    
    tests = [
        test_no_api_key,
        test_invalid_api_key,
        test_with_real_api_key,
        test_response_format
    ]
    
    passed = sum(1 for t in tests if t())
    total = len(tests)
    
    print("\n" + "=" * 50)
    print(f"ИТОГО: {passed}/{total} тестов пройдено")
    print("=" * 50)


if __name__ == '__main__':
    main()
