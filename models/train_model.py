import os
import sys
import pickle
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from feature_extractor import FeatureExtractor


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_path = os.path.join(base_dir, 'data', 'dataset.csv')
    model_path = os.path.join(base_dir, 'models', 'model.pkl')
    scaler_path = os.path.join(base_dir, 'models', 'scaler.pkl')

    df = pd.read_csv(data_path)
    print(f"Загружено {len(df)} записей")
    print(df['status'].value_counts())

    extractor = FeatureExtractor(data_dir=os.path.join(base_dir, 'data'))
    X, y, errors = [], [], 0
    for idx, row in df.iterrows():
        try:
            X.append(extractor.extract(row['url']))
            y.append(row['status'])
        except Exception as e:
            errors += 1
    X, y = np.array(X), np.array(y)
    print(f"Признаков: {X.shape}")

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    model = LogisticRegression(max_iter=2000, random_state=42, solver='lbfgs', class_weight='balanced')
    model.fit(X_train_scaled, y_train)

    y_pred = model.predict(X_test_scaled)
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average='weighted', zero_division=0)
    recall = recall_score(y_test, y_pred, average='weighted', zero_division=0)
    f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)

    print(f"\nAccuracy:  {accuracy * 100:.1f}%")
    print(f"Precision: {precision * 100:.1f}%")
    print(f"Recall:    {recall * 100:.1f}%")
    print(f"F1-score:  {f1 * 100:.1f}%")

    labels = sorted(model.classes_)
    print(f"\nConfusion matrix ({labels}):")
    print(confusion_matrix(y_test, y_pred, labels=labels))

    for label in labels:
        mask = y_test == label
        if mask.sum() > 0:
            print(f"{label}: {(y_pred[mask] == label).mean() * 100:.1f}% ({mask.sum()} samples)")

    with open(model_path, 'wb') as f:
        pickle.dump(model, f)
    with open(scaler_path, 'wb') as f:
        pickle.dump(scaler, f)
    print(f"\nМодель: {model_path}")
    print(f"Scaler: {scaler_path}")
    return accuracy, precision, recall, f1


if __name__ == '__main__':
    main()
