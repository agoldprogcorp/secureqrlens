import requests
import logging
from urllib.parse import urlparse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def resolve_redirects(url, max_depth=5, timeout=5):
    """
    Раскрывает цепочку редиректов для URL.
    
    Args:
        url: начальный URL
        max_depth: максимальная глубина редиректов
        timeout: таймаут на каждый запрос в секундах
    
    Returns:
        dict: {
            'chain': список URL в цепочке,
            'final_url': финальный URL,
            'error': None или текст ошибки
        }
    """
    chain = [url]
    current_url = url
    visited = set()
    
    for depth in range(max_depth):
        if current_url in visited:
            logger.warning(f"Обнаружен циклический редирект: {current_url}")
            return {
                'chain': chain,
                'final_url': chain[-1],
                'error': 'Циклический редирект'
            }
        
        visited.add(current_url)
        
        try:
            parsed = urlparse(current_url)
            if parsed.scheme not in ('http', 'https'):
                return {
                    'chain': chain,
                    'final_url': current_url,
                    'error': None
                }
            
            response = requests.head(
                current_url,
                allow_redirects=False,
                timeout=timeout,
                headers={'User-Agent': 'SecureQRLens/1.0'}
            )
            
            if response.status_code in (301, 302, 303, 307, 308):
                next_url = response.headers.get('Location')
                if not next_url:
                    break
                
                if not next_url.startswith(('http://', 'https://')):
                    base = f"{parsed.scheme}://{parsed.netloc}"
                    next_url = base + next_url if next_url.startswith('/') else base + '/' + next_url
                
                chain.append(next_url)
                current_url = next_url
                logger.info(f"Редирект {depth + 1}: {next_url}")
            else:
                break
                
        except requests.exceptions.Timeout:
            logger.error(f"Таймаут при запросе: {current_url}")
            return {
                'chain': chain,
                'final_url': chain[-1],
                'error': 'Таймаут запроса'
            }
        except requests.exceptions.ConnectionError:
            logger.error(f"Ошибка соединения: {current_url}")
            return {
                'chain': chain,
                'final_url': chain[-1],
                'error': 'Сеть недоступна'
            }
        except requests.exceptions.RequestException as e:
            logger.error(f"Ошибка запроса: {e}")
            return {
                'chain': chain,
                'final_url': chain[-1],
                'error': str(e)
            }
    
    return {
        'chain': chain,
        'final_url': chain[-1],
        'error': None
    }


def is_shortened_url(url):
    """
    Проверяет, является ли URL сокращённой ссылкой.
    """
    shorteners = [
        # Российские
        'clck.ru', 'vk.cc', 'vk.me', 'ok.me', 't.me', 'ya.ru', 'go.mail.ru',
        # Международные
        'bit.ly', 'bitly.com', 'goo.gl', 'g.co', 't.co', 'ow.ly', 
        'tinyurl.com', 'is.gd', 'v.gd', 'rebrand.ly', 'short.io', 'cutt.ly',
        # Корпоративные
        'aka.ms', 'amzn.to', 'youtu.be', 'fb.me', 'instagr.am', 'lnkd.in', 'redd.it'
    ]
    try:
        domain = urlparse(url).netloc.lower()
        return any(s in domain for s in shorteners)
    except:
        return False


if __name__ == '__main__':
    test_urls = [
        "https://clck.ru/3D9bWL",
        "https://bit.ly/3xK9mPq",
        "https://google.com"
    ]
    
    for url in test_urls:
        print(f"\nURL: {url}")
        result = resolve_redirects(url)
        print(f"Цепочка: {result['chain']}")
        print(f"Финальный: {result['final_url']}")
        if result['error']:
            print(f"Ошибка: {result['error']}")
