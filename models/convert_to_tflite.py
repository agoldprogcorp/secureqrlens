import os
import sys
import pickle
import json
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PKL = os.path.join(BASE_DIR, 'models', 'model.pkl')
SCALER_PKL = os.path.join(BASE_DIR, 'models', 'scaler.pkl')
TFLITE_OUT = os.path.join(BASE_DIR, 'models', 'model.tflite')
DART_OUT = os.path.join(BASE_DIR, 'android_app', 'lib', 'features', 'analysis', 'ml_weights.dart')


def load_models():
    with open(MODEL_PKL, 'rb') as f:
        model = pickle.load(f)
    with open(SCALER_PKL, 'rb') as f:
        scaler = pickle.load(f)
    return model, scaler


def convert_to_tflite(model, scaler):
    try:
        import tensorflow as tf

        weights = model.coef_.T.astype(np.float32)
        biases = model.intercept_.astype(np.float32)

        inputs = tf.keras.Input(shape=(6,))
        normalized = tf.keras.layers.Normalization(
            mean=scaler.mean_.astype(np.float32),
            variance=scaler.var_.astype(np.float32),
        )(inputs)
        outputs = tf.keras.layers.Dense(3, activation='softmax')(normalized)
        keras_model = tf.keras.Model(inputs=inputs, outputs=outputs)
        keras_model.layers[-1].set_weights([weights, biases])

        converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
        tflite_model = converter.convert()

        with open(TFLITE_OUT, 'wb') as f:
            f.write(tflite_model)
        print(f"TFLite: {TFLITE_OUT} ({len(tflite_model)} bytes)")
        return True
    except ImportError:
        print("TensorFlow not found, skipping")
        return False
    except Exception as e:
        print(f"TFLite error: {e}")
        return False


def generate_dart_weights(model, scaler):
    classes = list(model.classes_)
    coef = model.coef_.tolist()
    intercept = model.intercept_.tolist()
    mean = scaler.mean_.tolist()
    scale = np.sqrt(scaler.var_).tolist()

    def fmt(lst):
        return ', '.join(f'{v:.8f}' for v in lst)

    lines = [
        'class MlWeights {',
        f'  static const List<String> classes = {json.dumps(classes)};',
        '',
        '  static const List<List<double>> coef = [',
    ]
    for row in coef:
        lines.append(f'      [{fmt(row)}],')
    lines += [
        '  ];',
        '',
        f'  static const List<double> intercept = [{fmt(intercept)}];',
        '',
        f'  static const List<double> scalerMean = [{fmt(mean)}];',
        f'  static const List<double> scalerScale = [{fmt(scale)}];',
        '}',
    ]

    os.makedirs(os.path.dirname(DART_OUT), exist_ok=True)
    with open(DART_OUT, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print(f"Dart weights: {DART_OUT}")


def main():
    model, scaler = load_models()
    print(f"Model: {type(model).__name__}, classes: {list(model.classes_)}")

    convert_to_tflite(model, scaler)
    generate_dart_weights(model, scaler)

    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from feature_extractor import FeatureExtractor
    fe = FeatureExtractor(data_dir=os.path.join(BASE_DIR, 'data'))

    for url, expected in [("https://sberbank.ru", "safe"), ("https://sberrbank.ru/login", "danger")]:
        feats = fe.extract(url)
        feats_scaled = scaler.transform([feats])
        verdict = model.predict(feats_scaled)[0]
        probs = model.predict_proba(feats_scaled)[0]
        prob_str = ', '.join(f'{c}:{p:.2f}' for c, p in zip(model.classes_, probs))
        mark = 'ok' if verdict == expected else 'MISMATCH'
        print(f"  [{mark}] {url} -> {verdict} ({prob_str})")


if __name__ == '__main__':
    main()
