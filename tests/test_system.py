import os
import sys
import csv

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from modules.heuristics import HeuristicsAnalyzer
from modules.ml_classifier import MLClassifier


class SystemTester:
    def __init__(self, data_dir='data', models_dir='models'):
        self.heuristics = HeuristicsAnalyzer(data_dir=data_dir)
        self.ml_classifier = None
        try:
            self.ml_classifier = MLClassifier(models_dir=models_dir, data_dir=data_dir)
        except RuntimeError:
            print("ML-модель не загружена. Только эвристики.")

    def analyze(self, url):
        heur_result = self.heuristics.analyze(url)
        if heur_result['verdict'] != 'UNKNOWN':
            return heur_result['verdict'].lower()
        if self.ml_classifier is None:
            return 'unknown'
        return self.ml_classifier.predict(url)['verdict']

    def run_tests(self, test_file):
        results = []
        with open(test_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                url = row['url']
                expected = row['expected'].lower()
                predicted = self.analyze(url)
                results.append({
                    'url': url,
                    'expected': expected,
                    'predicted': predicted,
                    'correct': expected == predicted
                })
        return results

    def calculate_metrics(self, results):
        tp, tn, fp, fn = 0, 0, 0, 0
        for r in results:
            expected_safe = r['expected'] == 'safe'
            predicted_safe = r['predicted'] == 'safe'
            if expected_safe and predicted_safe:
                tn += 1
            elif expected_safe and not predicted_safe:
                fp += 1
            elif not expected_safe and not predicted_safe:
                tp += 1
            else:
                fn += 1

        total = len(results)
        correct = sum(1 for r in results if r['correct'])
        accuracy = correct / total if total > 0 else 0
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0

        return {
            'total': total, 'correct': correct,
            'tp': tp, 'tn': tn, 'fp': fp, 'fn': fn,
            'accuracy': accuracy, 'precision': precision, 'recall': recall, 'f1': f1
        }

    def save_results(self, results, output_file):
        with open(output_file, 'w', encoding='utf-8', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=['url', 'expected', 'predicted', 'correct'])
            writer.writeheader()
            writer.writerows(results)


def main():
    print("=" * 70)
    print("ТЕСТИРОВАНИЕ SECURE QR LENS")
    print("=" * 70)

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(base_dir, 'data')
    models_dir = os.path.join(base_dir, 'models')
    test_file = os.path.join(data_dir, 'test_urls.csv')
    results_file = os.path.join(base_dir, 'tests', 'test_results.csv')

    tester = SystemTester(data_dir=data_dir, models_dir=models_dir)

    print("\n[1/3] Загрузка тестов...")
    results = tester.run_tests(test_file)
    print(f"Загружено {len(results)} URL")

    print("\n[2/3] Расчёт метрик...")
    metrics = tester.calculate_metrics(results)

    print("\n" + "=" * 70)
    print(f"РЕЗУЛЬТАТЫ НА {metrics['total']} URL")
    print("=" * 70)
    print(f"\nTP: {metrics['tp']:3d}  (угрозы определены)")
    print(f"TN: {metrics['tn']:3d}  (безопасные определены)")
    print(f"FP: {metrics['fp']:3d}  (ложные срабатывания)")
    print(f"FN: {metrics['fn']:3d}  (пропущенные угрозы)")
    print(f"\nAccuracy:  {metrics['accuracy'] * 100:5.1f}%")
    print(f"Precision: {metrics['precision'] * 100:5.1f}%")
    print(f"Recall:    {metrics['recall'] * 100:5.1f}%")
    print(f"F1-score:  {metrics['f1'] * 100:5.1f}%")

    errors = [r for r in results if not r['correct']]
    if errors:
        print("\n" + "=" * 70)
        print("ОШИБКИ")
        print("=" * 70)
        for e in errors:
            print(f"\nURL: {e['url']}")
            print(f"  Ожидалось: {e['expected']}")
            print(f"  Получено:  {e['predicted']}")
    else:
        print("\nВсе URL классифицированы правильно!")

    print("\n[3/3] Сохранение...")
    tester.save_results(results, results_file)
    print(f"Результаты: {results_file}")

    print("\n" + "=" * 70)
    print("ЗАВЕРШЕНО")
    print("=" * 70)
    return metrics


if __name__ == '__main__':
    main()
