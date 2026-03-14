# Secure QR Lens

Превентивная защита от Quishing-атак (фишинг через QR-коды).

Принцип работы: **Analyze Before Execute** — анализ содержимого QR-кода до перехода по ссылке.

## Продукт

Android-приложение на Flutter. Работает полностью автономно — офлайн, без серверов и API-ключей.

```bash
cd android_app
flutter pub get
flutter run
```

Сборка APK:
```bash
flutter build apk --release
```

## Архитектура анализа

### Этап 0: Классификация контента

- **Deep Link** (tg://, sber://, bank://) — SUSPICIOUS, обходит браузер
- **Сокращённая ссылка** — HEAD-запросы до 5 уровней, анализ конечного URL
- **Wi-Fi конфигурация** — анализ типа шифрования (WPA/WEP/Open)
- **Не-URL** (текст, vCard, SMS) — отображается без анализа
- **HTTP/HTTPS URL** — передаётся на Этап 1

### Этап 1: Эвристический анализ (офлайн, <1 мс)

9 проверок в порядке приоритета:

1. Whitelist СБП (qr.nspk.ru) — SAFE
2. Whitelist брендов (1768 доменов, поддержка поддоменов) — SAFE
3. Malware-расширения (.apk, .exe, .bat, .scr, .vbs) — DANGER
4. Deep Link схемы — SUSPICIOUS
5. IDN Homograph / Punycode (xn--, смешение кириллицы и латиницы) — DANGER
6. QRLJacking (параметры session/token в URL) — SUSPICIOUS
7. Subdomain abuse (4+ уровня вложенности) — SUSPICIOUS
8. Typosquatting (расстояние Левенштейна <= 2) — DANGER
9. Энтропия Шеннона > 3.2 (DGA-домены) — SUSPICIOUS

### Этап 2: ML-классификация (офлайн, ~5 мс)

LogisticRegression, 3 класса (safe/danger/suspicious), 6 признаков.

Обучена на Python (scikit-learn), конвертирована в TFLite для Android. Fallback на чистый Dart при недоступности TFLite.

Признаки: url_length/200, dots_count, special_chars, has_ip, Shannon entropy, levenshtein_min.

### AR-визуализация

Цветная рамка поверх QR-кода в реальном времени через CustomPaint:
- Зелёный — SAFE
- Жёлтый — SUSPICIOUS
- Красный — DANGER

## Покрытие MITRE ATT&CK

| Техника | ID | Детекция |
|---|---|---|
| Quishing | T1660 | Весь пайплайн |
| Spearphishing Link | T1566.002 | Эвристики + ML |
| IDN Homograph | T1036.008 | Punycode-декодирование |
| DGA Domains | T1568.002 | Энтропия Шеннона |
| Typosquatting | T1583.001 | Расстояние Левенштейна |
| Malware Delivery | T1105 | Расширения файлов |
| Deep Link Injection | T1528 | Детекция URI-схем |
| QRLJacking | T1539 | Параметры сессии в URL |
| Defense Evasion | TA0030 | Раскрытие редиректов |

## Исследовательская часть (Python)

Python использовался для сбора датасета, обучения и тестирования ML-модели.

```bash
pip install -r requirements.txt
python models/train_model.py          # Обучение модели
python models/convert_to_tflite.py    # Конвертация в TFLite + генерация весов
python tests/test_system.py           # Тестирование системы
```

## Структура проекта

```
secureqrlens/
├── android_app/            Flutter Android-приложение (продукт)
│   ├── lib/
│   │   ├── core/           Константы, тема, утилиты (энтропия, Левенштейн, Punycode)
│   │   ├── features/
│   │   │   ├── scanner/    Камера, AR-оверлей, контроллер анализа
│   │   │   ├── analysis/   Эвристики, ML-анализатор, классификатор контента
│   │   │   └── history/    История сканирований
│   │   ├── models/         ScanResult, Verdict
│   │   └── widgets/        UI-компоненты
│   └── assets/             model.tflite, whitelist
├── data/                   Датасет (3336 URL), тестовая выборка, whitelist (1768 доменов)
├── models/                 Обучение и конвертация ML-модели
│   ├── train_model.py      Обучение LogisticRegression
│   ├── convert_to_tflite.py Конвертация в TFLite + генерация Dart-весов
│   └── feature_extractor.py Извлечение 6 признаков из URL
└── tests/                  Тестирование системы
    ├── heuristics.py       Python-реализация эвристик (для валидации)
    └── test_system.py      Тест точности эвристик + ML на выборке
```

## Метрики

| Метрика | Значение |
|---------|----------|
| Accuracy системы | 90.0% |
| Accuracy ML | 85.1% |
| Время эвристик | <1 мс |
| Время ML | ~5 мс |
| Датасет | 3336 URL |
| Whitelist | 1768 доменов |
| Эвристик | 9 |
| MITRE ATT&CK | 9 техник |

## Лицензия

MIT License
