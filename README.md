# Secure QR Lens

Система защиты от фишинга через QR-коды.

@secureqrlens - бот доступен и готов к использованию в Telegram!

В релиз вышло приложение на андроид - Secure Qr Lens! (Пока что не реализована AR-визуализация).

## Описание

Secure QR Lens проверяет URL из QR-кодов и определяет уровень угрозы:
- SAFE - безопасный URL
- DANGER - фишинговый/вредоносный URL
- SUSPICIOUS - подозрительный URL

## Мобильное приложение

Приложение для Android находится в папке `android_app/`

Запуск:
```bash
cd android_app
flutter pub get
flutter run
```

Сборка APK:
```bash
cd android_app
flutter build apk --release
```

Готовый APK: `release/secure-qr-lens-v1.0.0.apk`

## Анализ

### Этап 1: Эвристики

- Whitelist СБП (qr.nspk.ru, sbp-qr.ru)
- Malware расширения (.apk, .exe, .bat, .cmd, .scr)
- Deep Link схемы (tg://, sber://, bank://, ton://, whatsapp://, tinkoff://, alfa://, vtb://, sberpay://)
- Punycode домены (xn--)
- Typosquatting (расстояние Левенштейна <= 2)
- Энтропия Шеннона (> 4.5)

### Этап 2: ML классификация

Признаки:
- Длина URL
- Количество точек в домене
- Спецсимволы
- IP адрес вместо домена
- Энтропия домена
- Расстояние до известных брендов

Scoring:
- 0-1 балл = SAFE
- 2-3 балла = SUSPICIOUS
- 4+ баллов = DANGER

### Этап 3: Yandex Safe Browsing (опционально)

Проверка через Yandex Safe Browsing API.

## Установка Python версии

```bash
git clone https://github.com/agoldprogcorp/secureqrlens
cd secureqrlens
pip install -r requirements.txt
```

## Использование

Обучение модели:
```bash
python models/train_model.py
```

Демонстрация эвристик:
```bash
python scripts/demo_heuristics.py
```

Демонстрация ML:
```bash
python scripts/demo_ml.py
```

Полный пайплайн:
```bash
python scripts/demo_full_pipeline.py
```

Тестирование:
```bash
python tests/test_system.py
```

## Telegram бот

Настройка:

1. Создайте бота через @BotFather
2. Создайте файл `.env`:
```
TELEGRAM_BOT_TOKEN=ваш_токен
YANDEX_SB_API_KEY=ваш_ключ  # опционально
```

Примечание: Yandex Safe Browsing API опционален. Без него система работает только на локальных эвристиках и ML.

Запуск:
```bash
python telegram_bot/bot.py
```

Команды:
- /start - приветствие
- /help - справка
- /check <url> - проверить URL

## Структура

```
secureqrlens/
├── data/                   - датасет и whitelist
├── models/                 - ML модель
├── modules/                - Python модули
├── scripts/                - демо скрипты
├── telegram_bot/           - Telegram бот
├── tests/                  - тесты
└── android_app/            - Android приложение
```

## Датасет

1000 URL:
- 400 легитимных (банки, госуслуги, магазины)
- 400 фишинговых (PhishTank, URLhaus, typosquatting)
- 200 подозрительных (Deep Link, сокращатели)

## Результаты

- **Accuracy системы**: 90.0%
- **Accuracy ML**: 74.7%
- **Время анализа**: <1 мс (эвристики), ~5 мс (ML)
- **Размер датасета**: 1000 URL
- **Тестовая выборка**: 300 URL

## Лицензия

MIT License
