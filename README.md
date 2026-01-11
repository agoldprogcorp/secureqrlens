# Secure QR Lens

Система превентивной защиты от Quishing-атак (фишинг через QR-коды).

@secureqrlensbot - бот для проверки функционала в Telegram.

## Описание

Secure QR Lens анализирует URL из QR-кодов и определяет уровень угрозы:
- **SAFE** — безопасный URL
- **DANGER** — фишинговый/вредоносный URL
- **SUSPICIOUS** — потенциально опасный URL

### Многоэтапный анализ

**Этап 0: Раскрытие редиректов**
- Раскрытие цепочки сокращённых ссылок (bit.ly, clck.ru и др.)
- Анализ финального URL

**Этап 1: Эвристические правила (локальный, <100 мс)**
- Проверка whitelist СБП
- Детекция malware-расширений (.apk, .exe)
- Анализ Deep Link схем (tg://, sber://)
- Punycode-декодирование (IDN Homograph)
- Typosquatting (расстояние Левенштейна)
- Энтропия Шеннона (DGA-домены)

**Этап 2: ML-классификация (~50 мс)**
- Логистическая регрессия (multi_class='ovr')
- 6 признаков URL
- Вероятности для трёх классов

**Этап 3: Yandex Safe Browsing (опционально)**
- Проверка через Yandex Safe Browsing API
- Детекция MALWARE, SOCIAL_ENGINEERING, UNWANTED_SOFTWARE

## Установка

```bash
git clone https://github.com/agoldprogcorp/secureqrlens
cd secureqrlens
pip install -r requirements.txt
```

## Использование

### 1. Обучение модели

```bash
python models/train_model.py
```

### 2. Демонстрация эвристик

```bash
python scripts/demo_heuristics.py
```

### 3. Демонстрация ML

```bash
python scripts/demo_ml.py
```

### 4. Полный пайплайн

```bash
python scripts/demo_full_pipeline.py
```

### 5. Тестирование

```bash
python tests/test_system.py
python tests/test_redirect_resolver.py
python tests/test_yandex_sb.py
```

## Telegram-бот

Бот позволяет проверять QR-коды прямо в Telegram.

### Настройка

1. Создайте бота через [@BotFather](https://t.me/BotFather)
2. Скопируйте токен
3. Создайте файл `.env` в корне проекта:

```
TELEGRAM_BOT_TOKEN=ваш_токен_бота
YANDEX_SB_API_KEY=ваш_ключ_yandex  # опционально
```

### Запуск

```bash
python telegram_bot/bot.py
```

### Команды бота

- `/start` — приветствие
- `/help` — справка
- `/check <url>` — проверить URL

Также можно отправить фото QR-кода — бот декодирует и проанализирует ссылку.

## Yandex Safe Browsing

Для дополнительной проверки URL через Yandex Safe Browsing:

1. Получите API-ключ на https://yandex.com/dev/safebrowsing/
2. Добавьте в `.env`:

```
YANDEX_SB_API_KEY=ваш_ключ
```

Если ключ не настроен, система работает в оффлайн-режиме (только локальный анализ).

## Структура проекта

```
secure-qr-lens/
├── data/
│   ├── dataset.csv           # Датасет (1000 URL)
│   ├── whitelist_brands.txt  # 100 легитимных брендов
│   ├── sbp_whitelist.txt     # Домены СБП
│   └── test_urls.csv         # Тестовая выборка (40 URL)
├── models/
│   ├── train_model.py        # Скрипт обучения
│   ├── model.pkl             # Обученная модель
│   └── scaler.pkl            # Нормализатор
├── modules/
│   ├── heuristics.py         # Эвристический анализатор
│   ├── feature_extractor.py  # Извлечение признаков
│   ├── ml_classifier.py      # ML-классификатор
│   ├── redirect_resolver.py  # Раскрытие редиректов
│   └── yandex_safebrowsing.py # Yandex Safe Browsing API
├── scripts/
│   ├── demo_heuristics.py    # Демо эвристик
│   ├── demo_ml.py            # Демо ML
│   └── demo_full_pipeline.py # Демо полного пайплайна
├── telegram_bot/
│   ├── bot.py                # Основной файл бота
│   ├── handlers.py           # Обработчики команд
│   ├── config.py             # Конфигурация
│   └── requirements.txt      # Зависимости бота
├── tests/
│   ├── test_system.py        # Тестирование системы
│   ├── test_redirect_resolver.py # Тесты редиректов
│   ├── test_yandex_sb.py     # Тесты Yandex SB
│   └── test_results.csv      # Результаты тестов
├── .env.example              # Пример переменных окружения
├── .gitignore
├── LICENSE
├── README.md
└── requirements.txt
```

## Датасет

1000 URL из открытых источников:
- **Легитимные (400):** банки, госуслуги, магазины, СБП
- **Фишинговые (400):** PhishTank, URLhaus, typosquatting, Punycode
- **Подозрительные (200):** Deep Link, сокращатели URL

## Признаки ML-модели

1. `url_length` — длина URL / 200
2. `dots_count` — количество точек в домене
3. `special_chars` — количество спецсимволов
4. `has_ip` — IP-адрес вместо домена (0/1)
5. `entropy` — энтропия Шеннона домена
6. `levenshtein_min` — мин. расстояние до брендов

## Пример работы бота

```
Пользователь: [отправляет фото QR-кода]

Бот:
Анализ QR-кода

Извлечённый URL: https://clck.ru/xxx

Цепочка редиректов:
1. https://clck.ru/xxx
2. https://sberrbank.ru/login

ВЕРДИКТ: DANGER (опасно)

Причины:
- Typosquatting: расстояние до sberbank.ru = 1

Yandex Safe Browsing: Проверено, угроз нет

Время анализа: 0.15 сек
```

## Лицензия

MIT License
