import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
import coremltools as ct

# 学習用データのCSVファイルパスを指定してください
CSV_PATH = 'sleep_quality_data.csv'

# 特徴量カラム名のリスト（SleepQualityDataに対応）
feature_columns = [
    'totalSleepTime', 'idealSleepTime', 'timeInBed',
    'sleepEfficiency', 'sleepLatency', 'waso',
    'sleepTimeVariability', 'wakeTimeVariance', 'sleepRegularityIndex',
    'subjectiveSleepQuality', 'subjectiveSleepRegularity',
    'subjectiveSleepLatency', 'subjectiveWaso', 'subjectiveSleepiness',
    'hasWearableData'
]
# 予測したいターゲットカラム名（SleepQualityScore.totalScoreに対応）
target_column = 'totalScore'

# データ読み込み
df = pd.read_csv(CSV_PATH)
X = df[feature_columns]
y = df[target_column]

# 学習／テスト分割
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# モデルの学習
model = RandomForestRegressor(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Core MLモデルへ変換
coreml_model = ct.converters.sklearn.convert(
    model,
    input_features=feature_columns,
    output_feature_names=[target_column]
)

# .mlmodelファイルとして保存
coreml_model.save('SleepQualityPredictor.mlmodel')
print('Saved SleepQualityPredictor.mlmodel') 