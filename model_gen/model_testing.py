from joblib import load

# Load the model
model5 = load('past_model/batch5/model_5min.pkl')
model10 = load('past_model/batch5/model_10min.pkl')
model15 = load('past_model/batch5/model_15min.pkl')

print(model5.predict_proba([[0,0,0,0,0,0,0,0,0,0,0,0.0,0]]))
print(model5.predict_proba([[0,0,0,0,0,0,0,0,0,0,0,0.0,1]]))
print(model10.predict_proba([[0.4,0.4,0.4,0.2,0.2,0.2,0.2,0.0,0.2,0.2,0.0,0]]))
print(model10.predict_proba([[0.4,0.4,0.4,0.2,0.2,0.2,0.2,0.0,0.2,0.2,0.0,1]]))

# print(model15.predict_proba([[9.4,10.2,7.6,7.4,3.8,2.0,0.2,0.0,0.0,0.0,1]]))