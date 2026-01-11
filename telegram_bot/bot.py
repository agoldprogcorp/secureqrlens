import sys
import os
import logging

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from telegram.ext import Application, CommandHandler, MessageHandler, filters

from telegram_bot.config import TELEGRAM_BOT_TOKEN
from telegram_bot.handlers import (
    start_command,
    help_command,
    check_command,
    handle_photo,
    handle_text
)

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)


def main():
    """Запуск бота."""
    if not TELEGRAM_BOT_TOKEN:
        print("Ошибка: TELEGRAM_BOT_TOKEN не установлен!")
        print("\nКак настроить:")
        print("1. Создайте бота через @BotFather в Telegram")
        print("2. Скопируйте токен")
        print("3. Создайте файл .env в корне проекта:")
        print("   TELEGRAM_BOT_TOKEN=ваш_токен")
        print("\nИли установите переменную окружения:")
        print("   set TELEGRAM_BOT_TOKEN=ваш_токен")
        return
    
    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()
    
    app.add_handler(CommandHandler("start", start_command))
    app.add_handler(CommandHandler("help", help_command))
    app.add_handler(CommandHandler("check", check_command))
    
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))
    
    logger.info("Бот запущен!")
    print("Secure QR Lens Bot запущен!")
    print("Нажмите Ctrl+C для остановки")
    
    app.run_polling(allowed_updates=Update.ALL_TYPES if hasattr(Update, 'ALL_TYPES') else None)


if __name__ == '__main__':
    from telegram import Update
    main()
