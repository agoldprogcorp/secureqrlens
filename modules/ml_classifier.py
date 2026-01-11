import os
import time
import pickle
from modules.feature_extractor import FeatureExtractor


class MLClassifier:
    def __init__(self, models_dir='models', data_dir='data'):
        self.models_dir = models_dir
        self.data_dir = data_dir
        self.model = None
        self.scaler = None
        self.extractor = None
        self._load_model()

    def _load_model(self):
        model_path = os.path.join(self.models_dir, 'model.pkl')
        scaler_path = os.path.join(self.models_dir, 'scaler.pkl')
        try:
            with open(model_path, 'rb') as f:
                self.model = pickle.load(f)
            with open(scaler_path, 'rb') as f:
                self.scaler = pickle.load(f)
            self.extractor = FeatureExtractor(data_dir=self.data_dir)
        except FileNotFoundError as e:
            raise RuntimeError(f"Модель не найдена. Сначала запустите train_model.py\nОшибка: {e}")

    def predict(self, url):
        start_time = time.time()
        features = self.extractor.extract(url)
        features_scaled = self.scaler.transform([features])
        prediction = self.model.predict(features_scaled)[0]
        probabilities = self.model.predict_proba(features_scaled)[0]
        prob_dict = {label: round(probabilities[i], 3) for i, label in enumerate(self.model.classes_)}
        return {
            'verdict': prediction,
            'probabilities': prob_dict,
            'time_ms': (time.time() - start_time) * 1000
        }

    def predict_batch(self, urls):
        return [self.predict(url) for url in urls]


if __name__ == '__main__':
    try:
        classifier = MLClassifier()
        test_urls = [
            "https://sberbank.ru/login",
            "https://sberrbank.ru/login",
            "https://x7k2m9pq.com/malware",
            "https://google.com",
            "https://192.168.1.1/admin"
        ]
        print("ML-классификатор Secure QR Lens")
        print("=" * 50)
        for url in test_urls:
            result = classifier.predict(url)
            print(f"\nURL: {url}")
            print(f"Вердикт: {result['verdict']}")
            print(f"Вероятности: {result['probabilities']}")
            print(f"Время: {result['time_ms']:.2f} мс")
    except RuntimeError as e:
        print(f"Ошибка: {e}")
