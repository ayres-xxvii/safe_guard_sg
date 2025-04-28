import pandas as pd
from datetime import datetime

from sklearn.model_selection import train_test_split
from sklearn.model_selection import StratifiedKFold
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.svm import SVC
from sklearn.naive_bayes import MultinomialNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import RandomizedSearchCV, GridSearchCV
from sklearn.metrics import recall_score, confusion_matrix, classification_report

import pickle

df = pd.read_csv(r"data/superfinal_5mins_full_2013-2025.csv")

# Step 1: Split the data FIRST
X_train, X_test, y_train, y_test = train_test_split(
    df[["rainfall_5min_prior",
        "rainfall_10min_prior",
        "rainfall_15min_prior",
        "rainfall_20min_prior",
        "rainfall_25min_prior",
        "rainfall_30min_prior",
        "rainfall_35min_prior",
        "rainfall_40min_prior",
        "rainfall_45min_prior",
        "rainfall_50min_prior",
        "rainfall_55min_prior",
        "rainfall_1hr_prior", 
        "is_floodprone"]],

    df["is_flooded"],
    stratify=df["is_flooded"],
    test_size=0.2,
    random_state=88
)

prediction_models = {}

rf = RandomForestClassifier(random_state=8, class_weight='balanced')

# Define a (reasonable) search space
param_grid = {
    'n_estimators': [100, 200],
    'max_depth': [1, 2, 3, 4, 5, 6,7, 8, 9, 10, 20],
    'min_samples_split': [2, 4, 5, 8, 10],
    'min_samples_leaf': [1, 2, 3, 4],
    'max_features': ['sqrt', 'log2']
}

# Set up GridSearchCV
grid_search = GridSearchCV(
    estimator=rf,
    param_grid=param_grid,
    scoring='recall',  # Focus on catching floods
    cv=5,  # 5-fold Stratified CV
    n_jobs=-1,  # Use all cores
    verbose=2  # Print progress
)

# cols_to_drop = ["rainfall_5min_prior", "rainfall_10min_prior","rainfall_15min_prior","rainfall_20min_prior","rainfall_25min_prior"]

try:
    # Fit the search
    grid_search.fit(X_train, y_train)
    best_rf = grid_search.best_estimator_
    prediction_models["5min"] = {"model": best_rf, "params": grid_search.best_params_,"classification_report": classification_report(y_test, best_rf.predict(X_test), digits=3)}

    grid_search.fit(X_train.drop(columns=["rainfall_5min_prior"]), y_train)
    best_rf = grid_search.best_estimator_
    prediction_models["10min"] = {"model": best_rf, "params": grid_search.best_params_,"classification_report": classification_report(y_test, best_rf.predict(X_test.drop(columns=["rainfall_5min_prior"])), digits=3)}

    grid_search.fit(X_train.drop(columns=["rainfall_10min_prior"]), y_train)
    best_rf = grid_search.best_estimator_
    prediction_models["15min"] = {"model": best_rf, "params": grid_search.best_params_,"classification_report": classification_report(y_test, best_rf.predict(X_test.drop(columns=["rainfall_10min_prior"])), digits=3)}

    grid_search.fit(X_train.drop(columns=["rainfall_15min_prior","rainfall_20min_prior","rainfall_25min_prior"]), y_train)
    best_rf = grid_search.best_estimator_
    prediction_models["30min"] = {"model": best_rf, "params": grid_search.best_params_,"classification_report": classification_report(y_test, best_rf.predict(X_test.drop(columns=["rainfall_15min_prior","rainfall_20min_prior","rainfall_25min_prior"])), digits=3)}

finally:
    for key, value in prediction_models.items():
        print(f"Model: {key}")
        print(f"Best Parameters: {value['params']}")
        print(f"Classification Report:\n{value['classification_report']}\n")
        # Save the results to a file with a timestamp in the filename
        output_file = f"model_reports/grid_search_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        pickle.dump(value['model'], open(f'model_{key}.pkl', 'wb'))

        with open(output_file, "w") as f:
            for key, value in prediction_models.items():
                f.write(f"Model: {key}\n")
                f.write(f"Best Parameters: {value['params']}\n")
                f.write(f"Classification Report:\n{value['classification_report']}\n")
                f.write("-" * 50 + "\n")

# X = df[["rainfall_1hr_prior","rainfall_2hr_prior",
#         "rainfall_3hr_prior", "rainfall_5min_prior",
#         "rainfall_10min_prior","rainfall_15min_prior",
#         "rainfall_20min_prior","rainfall_25min_prior",
#         "rainfall_30min_prior","rainfall_35min_prior",
#         "rainfall_40min_prior","rainfall_45min_prior",
#         "nearest_station_distance",
#         "is_floodprone"]].values

# y = df["is_flooded"]

# skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=88)

# models = [
#     # LogisticRegression(max_iter=1000, random_state=88),
#     RandomForestClassifier(n_estimators=19, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=18, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=17, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=16, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=15, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=14, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=13, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=12, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=11, random_state=88, class_weight='balanced'),
#     RandomForestClassifier(n_estimators=10, random_state=88, class_weight='balanced'),
#     # SVC(probability=True, random_state=88, class_weight='balanced'),
#     # GradientBoostingClassifier(n_estimators=20, random_state=88),
#     # GradientBoostingClassifier(n_estimators=15, random_state=88),
#     # MultinomialNB(),
#     # KNeighborsClassifier(),
# ]


# # Initialize dictionaries to store metrics for each model
# average_metrics = {model: {"accuracy": [], "recall": [], "confusion_matrix": []} for model in models}

# # Generate a file name with the current date and time
# output_file = f"model_reports/model_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"

# with open(output_file, "a") as f:
#     for fold, (train_index, test_index) in enumerate(skf.split(X, y)):
#             f.write(f"Output generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
#             f.write(f"Fold {fold}:\n")
#             X_train, X_test, y_train, y_test = X[train_index], X[test_index], y[train_index], y[test_index]

#             for model in models:
#                 model.fit(X_train, y_train)
#                 f.write(f"Model: {model}\n")
#                 f.write(f"Train Accuracy Score: {model.score(X_train, y_train)}\n")
#                 f.write(f"Train Recall Score: {recall_score(y_train, model.predict(X_train))}\n")
#                 confusion_matrix_train = confusion_matrix(y_train, model.predict(X_train))
#                 f.write(f"Train Confusion Matrix:\n{confusion_matrix_train}\n\n")

#                 f.write(f"Test Accuracy Score: {model.score(X_test, y_test)}\n")
#                 f.write(f"Test Recall Score: {recall_score(y_test, model.predict(X_test))}\n")
#                 confusion_matrix_result = confusion_matrix(y_test, model.predict(X_test))
#                 f.write(f"Test Confusion Matrix:\n{confusion_matrix_result}\n")
#                 f.write("-" * 30 + "\n")

#                 # Test metrics
#                 accuracy = model.score(X_test, y_test)
#                 recall = recall_score(y_test, model.predict(X_test))
#                 confusion_matrix_result = confusion_matrix(y_test, model.predict(X_test))
                
#                 # Append metrics for this fold
#                 average_metrics[model]["accuracy"].append(accuracy)
#                 average_metrics[model]["recall"].append(recall)
#                 average_metrics[model]["confusion_matrix"].append(confusion_matrix_result)

#             f.write("NEXT FOLD \n\n\n")

#             # Compute averages
#             f.write("Summary of Models Test results (Average Metrics):\n")
#             for model in models:
#                 avg_accuracy = sum(average_metrics[model]["accuracy"]) / len(average_metrics[model]["accuracy"])
#                 avg_recall = sum(average_metrics[model]["recall"]) / len(average_metrics[model]["recall"])
#                 avg_confusion_matrix = sum(average_metrics[model]["confusion_matrix"]) / len(average_metrics[model]["confusion_matrix"])
                
#                 f.write(f"Model: {model}\n")
#                 f.write(f"Average Accuracy: {avg_accuracy}\n")
#                 f.write(f"Average Recall: {avg_recall}\n")
#                 f.write(f"Average Confusion Matrix:\n{avg_confusion_matrix}\n")
#                 f.write("-" * 30 + "\n")