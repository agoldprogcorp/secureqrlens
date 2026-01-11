import requests
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

YANDEX_SB_ENDPOINT = "https://sba.yandex.net/v4/threatMatches:find"


def check_url_safety(url, api_key=None):
    """
    Проверяет URL через Yandex Safe Browsing API.
    
    Args:
        url: URL для проверки
        api_key: API-ключ Yandex Safe Browsing (или из env)
    
    Returns:
        dict: {
            'safe': True/False/None,
            'threats': список угроз,
            'error': None или текст ошибки
        }
    """
    if api_key is None:
        api_key = os.getenv('YANDEX_SB_API_KEY')
    
    if not api_key:
        logger.warning("API-ключ Yandex Safe Browsing не настроен")
        return {
            'safe': None,
            'threats': [],
            'error': 'API-ключ не настроен'
        }
    
    payload = {
        "client": {
            "clientId": "secureqrlens",
            "clientVersion": "1.0.0"
        },
        "threatInfo": {
            "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE"],
            "platformTypes": ["ANY_PLATFORM"],
            "threatEntryTypes": ["URL"],
            "threatEntries": [
                {"url": url}
            ]
        }
    }
    
    try:
        response = requests.post(
            YANDEX_SB_ENDPOINT,
            json=payload,
            params={'key': api_key},
            timeout=10,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            data = response.json()
            
            if 'matches' in data and len(data['matches']) > 0:
                threats = [match.get('threatType', 'UNKNOWN') for match in data['matches']]
                logger.warning(f"Обнаружены угрозы для {url}: {threats}")
                return {
                    'safe': False,
                    'threats': threats,
                    'error': None
                }
            else:
                logger.info(f"URL безопасен: {url}")
                return {
                    'safe': True,
                    'threats': [],
                    'error': None
                }
        
        elif response.status_code == 400:
            logger.error(f"Неверный запрос к API: {response.text}")
            return {
                'safe': None,
                'threats': [],
                'error': 'Неверный запрос'
            }
        
        elif response.status_code == 403:
            logger.error("Неверный API-ключ")
            return {
                'safe': None,
                'threats': [],
                'error': 'Неверный API-ключ'
            }
        
        else:
            logger.error(f"Ошибка API: {response.status_code}")
            return {
                'safe': None,
                'threats': [],
                'error': f'HTTP {response.status_code}'
            }
            
    except requests.exceptions.Timeout:
        logger.error("Таймаут запроса к Yandex Safe Browsing")
        return {
            'safe': None,
            'threats': [],
            'error': 'Таймаут запроса'
        }
    
    except requests.exceptions.ConnectionError:
        logger.error("Не удалось подключиться к Yandex Safe Browsing")
        return {
            'safe': None,
            'threats': [],
            'error': 'API недоступен'
        }
    
    except Exception as e:
        logger.error(f"Ошибка: {e}")
        return {
            'safe': None,
            'threats': [],
            'error': str(e)
        }


def check_urls_batch(urls, api_key=None):
    """
    Проверяет несколько URL за один запрос.
    
    Args:
        urls: список URL
        api_key: API-ключ
    
    Returns:
        dict: {url: результат проверки}
    """
    results = {}
    for url in urls:
        results[url] = check_url_safety(url, api_key)
    return results


if __name__ == '__main__':
    test_urls = [
        "https://google.com",
        "https://sberbank.ru",
        "https://example-phishing-test.com"
    ]
    
    api_key = os.getenv('YANDEX_SB_API_KEY')
    
    if not api_key:
        print("Установите YANDEX_SB_API_KEY для тестирования")
        print("Пример: set YANDEX_SB_API_KEY=ваш_ключ")
    else:
        for url in test_urls:
            print(f"\nПроверка: {url}")
            result = check_url_safety(url, api_key)
            print(f"Безопасен: {result['safe']}")
            if result['threats']:
                print(f"Угрозы: {result['threats']}")
            if result['error']:
                print(f"Ошибка: {result['error']}")
