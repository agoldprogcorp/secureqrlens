import os
from dotenv import load_dotenv

load_dotenv()

TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
YANDEX_SB_API_KEY = os.getenv("YANDEX_SB_API_KEY")

if not TELEGRAM_BOT_TOKEN:
    print("ВНИМАНИЕ: TELEGRAM_BOT_TOKEN не установлен!")
    print("Создайте файл .env или установите переменную окружения")
