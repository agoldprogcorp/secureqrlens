import sys
import os
import time
import logging
from io import BytesIO

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from telegram import Update
from telegram.ext import ContextTypes

try:
    from pyzbar.pyzbar import decode as decode_qr
    from PIL import Image
    QR_AVAILABLE = True
except ImportError:
    QR_AVAILABLE = False
    print("pyzbar или Pillow не установлены. Декодирование QR недоступно.")

from modules.heuristics import HeuristicsAnalyzer
from modules.ml_classifier import MLClassifier
from modules.redirect_resolver import resolve_redirects, is_shortened_url
from modules.yandex_safebrowsing import check_url_safety
from telegram_bot.config import YANDEX_SB_API_KEY

logger = logging.getLogger(__name__)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, 'data')
MODELS_DIR = os.path.join(BASE_DIR, 'models')

heuristics = HeuristicsAnalyzer(data_dir=DATA_DIR)
ml_classifier = None

try:
    ml_classifier = MLClassifier(models_dir=MODELS_DIR, data_dir=DATA_DIR)
except Exception as e:
    logger.warning(f"ML-модель не загружена: {e}")


def analyze_url(url):
    """Полный анализ URL через все модули."""
    start_time = time.time()
    result = {
        'original_url': url,
        'redirect_chain': [url],
        'final_url': url,
        'verdict': None,
        'reasons': [],
        'yandex_sb': None,
        'time_sec': 0
    }
    
    if url.startswith(('http://', 'https://')) and is_shortened_url(url):
        redirect_result = resolve_redirects(url)
        result['redirect_chain'] = redirect_result['chain']
        result['final_url'] = redirect_result['final_url']
        if redirect_result['error']:
            result['reasons'].append(f"Ошибка редиректов: {redirect_result['error']}")
    
    url_to_analyze = result['final_url']
    
    heur_result = heuristics.analyze(url_to_analyze)
    
    if heur_result['verdict'] != 'UNKNOWN':
        result['verdict'] = heur_result['verdict']
        result['reasons'].append(heur_result['details'])
    elif ml_classifier:
        ml_result = ml_classifier.predict(url_to_analyze)
        result['verdict'] = ml_result['verdict'].upper()
        max_prob = max(ml_result['probabilities'].values())
        result['reasons'].append(f"ML: {ml_result['verdict']} ({max_prob:.1%})")
    else:
        result['verdict'] = 'UNKNOWN'
        result['reasons'].append("ML-модель недоступна")
    
    if YANDEX_SB_API_KEY and url_to_analyze.startswith(('http://', 'https://')):
        sb_result = check_url_safety(url_to_analyze, YANDEX_SB_API_KEY)
        result['yandex_sb'] = sb_result
    
    result['time_sec'] = time.time() - start_time
    return result


def format_response(result):
    """Форматирует ответ для пользователя."""
    lines = ["Анализ QR-кода\n"]
    lines.append(f"Извлечённый URL: {result['original_url']}")
    
    if len(result['redirect_chain']) > 1:
        lines.append("\nЦепочка редиректов:")
        for i, url in enumerate(result['redirect_chain'], 1):
            lines.append(f"{i}. {url}")
    
    verdict = result['verdict']
    if verdict == 'SAFE':
        verdict_icon = "SAFE (безопасно)"
    elif verdict == 'DANGER':
        verdict_icon = "DANGER (опасно)"
    elif verdict == 'SUSPICIOUS':
        verdict_icon = "SUSPICIOUS (подозрительно)"
    else:
        verdict_icon = "UNKNOWN"
    
    lines.append(f"\nВЕРДИКТ: {verdict_icon}")
    
    if result['reasons']:
        lines.append("\nПричины:")
        for reason in result['reasons']:
            lines.append(f"- {reason}")
    
    if result['yandex_sb']:
        sb = result['yandex_sb']
        if sb['safe'] is True:
            lines.append("\nYandex Safe Browsing: Проверено, угроз нет")
        elif sb['safe'] is False:
            lines.append(f"\nYandex Safe Browsing: УГРОЗЫ: {', '.join(sb['threats'])}")
        else:
            lines.append(f"\nYandex Safe Browsing: Не удалось проверить ({sb['error']})")
    
    lines.append(f"\nВремя анализа: {result['time_sec']:.2f} сек")
    
    return "\n".join(lines)


async def start_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик команды /start."""
    text = """Привет! Я Secure QR Lens Bot.

Я помогу проверить QR-коды на безопасность.

Что я умею:
- Отправь мне фото QR-кода — я проанализирую ссылку
- /check <url> — проверить URL напрямую
- /help — справка

Просто отправь фото с QR-кодом!"""
    await update.message.reply_text(text)


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик команды /help."""
    text = """Как пользоваться ботом:

1. Отправьте фото QR-кода
   Бот декодирует QR и проанализирует ссылку

2. /check <url>
   Проверить URL напрямую
   Пример: /check https://sberrbank.ru

Что проверяется:
- Typosquatting (опечатки в доменах)
- Punycode-атаки (поддельные домены)
- Deep Link инъекции
- Сокращённые ссылки (раскрытие редиректов)
- Yandex Safe Browsing (если настроен)

Вердикты:
- SAFE — безопасно
- SUSPICIOUS — подозрительно
- DANGER — опасно"""
    await update.message.reply_text(text)


async def check_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик команды /check <url>."""
    if not context.args:
        await update.message.reply_text("Использование: /check <url>\nПример: /check https://example.com")
        return
    
    url = context.args[0]
    await update.message.reply_text("Анализирую URL...")
    
    result = analyze_url(url)
    response = format_response(result)
    await update.message.reply_text(response)


async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик фотографий с QR-кодами."""
    if not QR_AVAILABLE:
        await update.message.reply_text("Декодирование QR-кодов недоступно. Установите pyzbar и Pillow.")
        return
    
    await update.message.reply_text("Обрабатываю изображение...")
    
    try:
        photo = update.message.photo[-1]
        file = await context.bot.get_file(photo.file_id)
        
        image_bytes = BytesIO()
        await file.download_to_memory(image_bytes)
        image_bytes.seek(0)
        
        image = Image.open(image_bytes)
        decoded = decode_qr(image)
        
        if not decoded:
            await update.message.reply_text("QR-код не найден на изображении. Попробуйте другое фото.")
            return
        
        url = decoded[0].data.decode('utf-8')
        logger.info(f"Декодирован QR: {url}")
        
        result = analyze_url(url)
        response = format_response(result)
        await update.message.reply_text(response)
        
    except Exception as e:
        logger.error(f"Ошибка обработки фото: {e}")
        await update.message.reply_text(f"Ошибка при обработке изображения: {e}")


async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Обработчик текстовых сообщений."""
    text = update.message.text
    
    if text.startswith(('http://', 'https://', 'tg://', 'sber://')):
        await update.message.reply_text("Анализирую URL...")
        result = analyze_url(text)
        response = format_response(result)
        await update.message.reply_text(response)
    else:
        await update.message.reply_text("Отправьте фото QR-кода или URL для проверки.\nИспользуйте /help для справки.")
