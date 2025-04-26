import pandas as pd

from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.svm import SVC
from sklearn.naive_bayes import MultinomialNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, confusion_matrix, classification_report

from imblearn.over_sampling import SMOTE

df = pd.read_csv(r"data/final_5mins_full_2013-2025.csv")
skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=88)

# X_train, X_test, y_train, y_test = train_test_split(df[["rainfall_1hr_prior","rainfall_2hr_prior",
#                                                         "rainfall_3hr_prior", "rainfall_5min_prior",
#                                                         "rainfall_10min_prior","rainfall_15min_prior",
#                                                         "rainfall_20min_prior","rainfall_25min_prior",
#                                                         "rainfall_30min_prior","rainfall_35min_prior",
#                                                         "rainfall_40min_prior","rainfall_45min_prior",
#                                                         "nearest_station_distance",
#                                                         "is_floodprone"]], 
#                                                     df["is_flooded"],
#                                                     stratify=df["is_flooded"],
#                                                     test_size=0.2, 
#                                                     random_state=42)

# Apply SMOTE on training data
# smote = SMOTE(random_state=42)
# X_train_smote, y_train_smote = smote.fit_resample(X_train, y_train)
# print(y_train.value_counts())
# print(y_train_smote.value_counts())

X = df[["rainfall_1hr_prior","rainfall_2hr_prior",
        "rainfall_3hr_prior", "rainfall_5min_prior",
        "rainfall_10min_prior","rainfall_15min_prior",
        "rainfall_20min_prior","rainfall_25min_prior",
        "rainfall_30min_prior","rainfall_35min_prior",
        "rainfall_40min_prior","rainfall_45min_prior",
        "nearest_station_distance",
        "is_floodprone"]].values

y = df["is_flooded"]

models = [
    RandomForestClassifier(n_estimators=80, random_state=88, class_weight='balanced'),
    RandomForestClassifier(n_estimators=50, random_state=88, class_weight='balanced'),
    RandomForestClassifier(n_estimators=30, random_state=88, class_weight='balanced'),
    RandomForestClassifier(n_estimators=20, random_state=88, class_weight='balanced'),
    RandomForestClassifier(n_estimators=15, random_state=88, class_weight='balanced'),
    SVC(probability=True, random_state=88, class_weight='balanced'),
    GradientBoostingClassifier(n_estimators=20, random_state=88),
    GradientBoostingClassifier(n_estimators=15, random_state=88),
    MultinomialNB(),
    KNeighborsClassifier(),
]

# Initialize dictionaries to store metrics for each model
average_metrics = {model: {"accuracy": [], "recall": [], "confusion_matrix": []} for model in models}

for fold, (train_index, test_index) in enumerate(skf.split(X, y)):
    print(f"Fold {fold}:")
    # print(f"  Train: index={train_index}")
    # print(f"  Test:  index={test_index}")
    X_train, X_test, y_train, y_test = X[train_index], X[test_index], y[train_index], y[test_index]
    # print(f"  X_train shape: {X_train.shape}")
    # print(f"  y_train shape: {y_train.shape}")
    # print(f"  X_test shape: {X_test.shape}")
    # print(f"  y_test shape: {y_test.shape}")
    for model in models:
        model.fit(X_train, y_train)
        print(f"Model: {model}")
        print(f"Train Accuracy Score: {model.score(X_train, y_train)}")
        print("Train Recall Score: ", recall_score(y_train, model.predict(X_train)))
        confusion_matrix_train = confusion_matrix(y_train, model.predict(X_train))
        print(f"Train Confusion Matrix:\n{confusion_matrix_train}\n")
        # print("Train Classification report:\n", classification_report(y_train, model.predict(X_train)))

        print(f"Test Accuracy Score: {model.score(X_test, y_test)}")
        print("Test Recall Score: ", recall_score(y_test, model.predict(X_test)))
        confusion_matrix_result = confusion_matrix(y_test, model.predict(X_test))
        print(f"Test Confusion Matrix:\n{confusion_matrix_result}")
        # print("Test Classification report:\n", classification_report(y_test, model.predict(X_test)))
        print("-" * 30)

        # Test metrics
        accuracy = model.score(X_test, y_test)
        recall = recall_score(y_test, model.predict(X_test))
        confusion_matrix_result = confusion_matrix(y_test, model.predict(X_test))
        
        # Append metrics for this fold
        average_metrics[model]["accuracy"].append(accuracy)
        average_metrics[model]["recall"].append(recall)
        average_metrics[model]["confusion_matrix"].append(confusion_matrix_result)

    print("NEXT FOLD \n\n\n")

    # Compute averages
    print("Summary of Models Test results (Average Metrics):")
    for model in models:
        avg_accuracy = sum(average_metrics[model]["accuracy"]) / len(average_metrics[model]["accuracy"])
        avg_recall = sum(average_metrics[model]["recall"]) / len(average_metrics[model]["recall"])
        avg_confusion_matrix = sum(average_metrics[model]["confusion_matrix"]) / len(average_metrics[model]["confusion_matrix"])
        
        print(f"Model: {model}")
        print(f"Average Accuracy: {avg_accuracy}")
        print(f"Average Recall: {avg_recall}")
        print(f"Average Confusion Matrix:\n{avg_confusion_matrix}")
        print("-" * 30)