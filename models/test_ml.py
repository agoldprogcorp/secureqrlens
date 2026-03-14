import os
import sys
import csv
import pickle

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from feature_extractor import FeatureExtractor

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, 'data')
MODELS_DIR = os.path.join(BASE_DIR, 'models')


def load_model():
    with open(os.path.join(MODELS_DIR, 'model.pkl'), 'rb') as f:
        model = pickle.load(f)
    with open(os.path.join(MODELS_DIR, 'scaler.pkl'), 'rb') as f:
        scaler = pickle.load(f)
    return model, scaler


def load_test_set():
    rows = []
    with open(os.path.join(DATA_DIR, 'test_urls.csv'), 'r', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            rows.append({
                'url': row['url'],
                'expected': row['expected'].lower(),
                'category': row.get('category', ''),
            })
    return rows


def main():
    model, scaler = load_model()
    extractor = FeatureExtractor(data_dir=DATA_DIR)
    rows = load_test_set()

    results = []
    for row in rows:
        features = extractor.extract(row['url'])
        features_scaled = scaler.transform([features])
        predicted = model.predict(features_scaled)[0]
        results.append({**row, 'predicted': predicted, 'correct': predicted == row['expected']})

    total = len(results)
    correct = sum(1 for r in results if r['correct'])
    classes = sorted(set(r['expected'] for r in results))

    tp, fp, fn = 0, 0, 0
    for r in results:
        if r['expected'] != 'safe' and r['predicted'] != 'safe':
            tp += 1
        elif r['expected'] == 'safe' and r['predicted'] != 'safe':
            fp += 1
        elif r['expected'] != 'safe' and r['predicted'] == 'safe':
            fn += 1

    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0

    print(f"Total:     {total}")
    print(f"Correct:   {correct}")
    print(f"Accuracy:  {correct / total * 100:.1f}%")
    print(f"Precision: {precision * 100:.1f}%")
    print(f"Recall:    {recall * 100:.1f}%")
    print(f"F1-score:  {f1 * 100:.1f}%")

    print("\nPer-class:")
    for cls in classes:
        subset = [r for r in results if r['expected'] == cls]
        hits = sum(1 for r in subset if r['correct'])
        print(f"  {cls:12s}: {hits}/{len(subset)} ({hits / len(subset) * 100:.1f}%)")

    errors = [r for r in results if not r['correct']]
    if errors:
        print(f"\nErrors ({len(errors)}):")
        for e in errors:
            cat = f" [{e['category']}]" if e['category'] else ''
            print(f"  {e['expected']:10s} -> {e['predicted']:10s}{cat}  {e['url']}")


if __name__ == '__main__':
    main()
