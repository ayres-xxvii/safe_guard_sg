import pandas as pd

from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.svm import SVC
from sklearn.naive_bayes import MultinomialNB
from sklearn.metrics import accuracy_score, precision_score, recall_score, confusion_matrix

from imblearn.over_sampling import SMOTE

df = pd.read_csv(r"data/final_full_2013-2025.csv")

X_train, X_test, y_train, y_test = train_test_split(df[["rainfall_1hr_prior","rainfall_2hr_prior","rainfall_3hr_prior","nearest_station_distance","is_floodprone"]], 
                                                    df["is_flooded"],
                                                    stratify=df["is_flooded"],
                                                    test_size=0.2, 
                                                    random_state=42)

models = [
    RandomForestClassifier(n_estimators=100, random_state=42, class_weight='balanced'),
    RandomForestClassifier(n_estimators=90, random_state=42, class_weight='balanced'),
    RandomForestClassifier(n_estimators=80, random_state=42, class_weight='balanced'),
    RandomForestClassifier(n_estimators=50, random_state=42, class_weight='balanced'),
    GradientBoostingClassifier(n_estimators=100, random_state=42),
    SVC(probability=True, random_state=42, class_weight='balanced'),
    MultinomialNB()
]

for model in models:
    model.fit(X_train, y_train)
    print(f"Model: {model}")
    print(f"Train Accuracy Score: {model.score(X_train, y_train)}")
    print(f"Test Accuracy Score: {model.score(X_test, y_test)}")
    confusion_matrix_train = confusion_matrix(y_train, model.predict(X_train))
    print(f"Train Confusion Matrix:\n{confusion_matrix_train}")
    confusion_matrix_result = confusion_matrix(y_test, model.predict(X_test))
    print(f"Test Confusion Matrix:\n{confusion_matrix_result}")
    print("-" * 30)
