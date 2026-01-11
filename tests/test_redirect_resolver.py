import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from modules.redirect_resolver import resolve_redirects, is_shortened_url


def test_is_shortened_url():
    """Тест определения сокращённых ссылок."""
    print("Тест: is_shortened_url")
    
    shortened = [
        "https://bit.ly/abc123",
        "https://clck.ru/xyz",
        "https://t.co/abc",
        "https://tinyurl.com/test"
    ]
    
    not_shortened = [
        "https://google.com",
        "https://sberbank.ru/login",
        "https://example.com/page"
    ]
    
    passed = 0
    failed = 0
    
    for url in shortened:
        if is_shortened_url(url):
            print(f"  OK: {url} -> сокращённая")
            passed += 1
        else:
            print(f"  FAIL: {url} должна быть сокращённой")
            failed += 1
    
    for url in not_shortened:
        if not is_shortened_url(url):
            print(f"  OK: {url} -> обычная")
            passed += 1
        else:
            print(f"  FAIL: {url} не должна быть сокращённой")
            failed += 1
    
    print(f"Результат: {passed} passed, {failed} failed\n")
    return failed == 0


def test_resolve_redirects_no_redirect():
    """Тест URL без редиректов."""
    print("Тест: resolve_redirects (без редиректов)")
    
    result = resolve_redirects("https://google.com", timeout=3)
    
    if result['final_url'] and result['error'] is None:
        print(f"  OK: финальный URL получен")
        print(f"  Цепочка: {result['chain']}")
        return True
    else:
        print(f"  FAIL: {result}")
        return False


def test_resolve_redirects_invalid_url():
    """Тест невалидного URL."""
    print("\nТест: resolve_redirects (невалидный URL)")
    
    result = resolve_redirects("not-a-valid-url")
    
    print(f"  Результат: {result}")
    print(f"  OK: функция не упала")
    return True


def test_resolve_redirects_deep_link():
    """Тест Deep Link (не HTTP)."""
    print("\nТест: resolve_redirects (Deep Link)")
    
    result = resolve_redirects("tg://resolve?domain=test")
    
    if result['chain'] == ["tg://resolve?domain=test"]:
        print(f"  OK: Deep Link не обрабатывается как HTTP")
        return True
    else:
        print(f"  FAIL: {result}")
        return False


def main():
    print("=" * 50)
    print("ТЕСТЫ REDIRECT RESOLVER")
    print("=" * 50 + "\n")
    
    tests = [
        test_is_shortened_url,
        test_resolve_redirects_no_redirect,
        test_resolve_redirects_invalid_url,
        test_resolve_redirects_deep_link
    ]
    
    passed = sum(1 for t in tests if t())
    total = len(tests)
    
    print("=" * 50)
    print(f"ИТОГО: {passed}/{total} тестов пройдено")
    print("=" * 50)


if __name__ == '__main__':
    main()
