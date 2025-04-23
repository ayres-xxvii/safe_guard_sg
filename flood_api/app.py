from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
from flask_cors import CORS
import random  # For demo purposes

app = Flask(__name__)
CORS(app)

# Load the trained model and label encoder
try:
    model = joblib.load('flood_model.pkl')
    label_encoder = joblib.load('label_encoder.pkl')
    # Get the feature names used during model training
    model_features = model.feature_names_in_ if hasattr(model, 'feature_names_in_') else []
    print(f"Model loaded successfully with features: {model_features}")
except Exception as e:
    print(f"Warning: Could not load model properly: {str(e)}")
    model = None
    label_encoder = None
    model_features = []

# Get example weather data (in a real app, this would come from weather API)
def get_weather_data():
    return {
        'air-temperature-0.5h-prior': random.uniform(24, 32),
        'air-temperature-1.0h-prior': random.uniform(24, 32),
        'air-temperature-1.5h-prior': random.uniform(24, 32),
        'air-temperature-2.0h-prior': random.uniform(24, 32),
        'air-temperature-2.5h-prior': random.uniform(24, 32),
        'rainfall-0.5h-prior': random.uniform(0, 20),
        'rainfall-1.0h-prior': random.uniform(0, 20),
        'rainfall-1.5h-prior': random.uniform(0, 20),
        'rainfall-2.0h-prior': random.uniform(0, 20),
        'rainfall-2.5h-prior': random.uniform(0, 20),
        'relative-humidity-0.5h-prior': random.uniform(70, 95),
        'relative-humidity-1.0h-prior': random.uniform(70, 95),
        'relative-humidity-1.5h-prior': random.uniform(70, 95),
        'relative-humidity-2.0h-prior': random.uniform(70, 95),
        'relative-humidity-2.5h-prior': random.uniform(70, 95),
        'wind-direction-0.5h-prior': random.uniform(0, 360),
        'wind-direction-1.0h-prior': random.uniform(0, 360),
        'wind-direction-1.5h-prior': random.uniform(0, 360),
        'wind-direction-2.0h-prior': random.uniform(0, 360),
        'wind-direction-2.5h-prior': random.uniform(0, 360),
        'wind-speed-0.5h-prior': random.uniform(0, 30),
        'wind-speed-1.0h-prior': random.uniform(0, 30),
        'wind-speed-1.5h-prior': random.uniform(0, 30),
        'wind-speed-2.0h-prior': random.uniform(0, 30),
        'wind-speed-2.5h-prior': random.uniform(0, 30),
        'elevation': random.uniform(0, 20),
        'drain-density': random.uniform(0.1, 0.9),
        'land-use': random.choice(['urban', 'residential', 'green']),
        'soil-type': random.choice(['clay', 'sandy', 'loam']),
        'slope-gradient': random.uniform(0, 10)
    }

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        
        # Check if we're in demo mode (model not loaded)
        if model is None:
            risk_level = random.choice(['low_risk', 'medium_risk', 'high_risk'])
            return jsonify({
                'prediction': risk_level,
                'probability': random.uniform(0.7, 0.95),
                'numeric_label': {'low_risk': 0, 'medium_risk': 1, 'high_risk': 2}[risk_level]
            })
        
        # Get weather and environmental data for this location
        additional_features = get_weather_data()
        
        # Combine with location data
        features = {**data, **additional_features}
        
        # Create DataFrame with all required features
        features_df = pd.DataFrame([features])
        
        # Ensure all model features are present
        for feature in model_features:
            if feature not in features_df.columns:
                features_df[feature] = 0  # Default value
        
        # Keep only the features needed by the model
        features_df = features_df[model_features]
        
        # Make prediction
        prediction_numeric = model.predict(features_df)[0]
        prediction_label = label_encoder.inverse_transform([prediction_numeric])[0]
        
        # Get prediction probability
        probabilities = model.predict_proba(features_df)[0]
        probability = float(probabilities[prediction_numeric])
        
        # Return the prediction and its probability
        return jsonify({
            'prediction': prediction_label,
            'probability': probability,
            'numeric_label': int(prediction_numeric)
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/batch_predict', methods=['POST'])
def batch_predict():
    print("Received batch prediction request!")
    try:
        data = request.get_json()
        locations = data.get('locations', [])
        print(f"Processing {len(locations)} locations")
        
        results = []
        for location in locations:
            try:
                # Extract location data
                latitude = location.get('latitude')
                longitude = location.get('longitude')
                
                # For demo purposes or if model is not loaded
                if model is None or not model_features:
                    # Generate random predictions
                    risk_levels = ['low', 'medium', 'high']
                    weights = [0.5, 0.3, 0.2]  # More low risk areas than high risk
                    
                    # Use location to affect probability (more risk in certain areas)
                    risk_level = random.choices(risk_levels, weights=weights)[0]
                    
                    # Add to results
                    results.append({
                        'latitude': latitude,
                        'longitude': longitude,
                        'prediction': f"{risk_level}_risk",
                        'severity': risk_level
                    })
                    continue
                
                # Get weather and environmental data for this location
                additional_features = get_weather_data()
                
                # Create feature dictionary
                features = {
                    'latitude': latitude,
                    'longitude': longitude,
                    **additional_features
                }
                
                # Create DataFrame
                features_df = pd.DataFrame([features])
                
                # Ensure all model features are present
                for feature in model_features:
                    if feature not in features_df.columns:
                        features_df[feature] = 0  # Default value
                
                # Keep only the features needed by the model
                features_df = features_df[model_features]
                
                # Make prediction
                prediction_numeric = model.predict(features_df)[0]
                prediction_label = label_encoder.inverse_transform([prediction_numeric])[0]
                
                # Map to severity
                severity = map_to_severity(prediction_label)
                
                results.append({
                    'latitude': latitude,
                    'longitude': longitude,
                    'prediction': prediction_label,
                    'severity': severity
                })
            except Exception as e:
                print(f"Error processing location {latitude}, {longitude}: {str(e)}")
                # Add a default low risk for this location
                results.append({
                    'latitude': latitude,
                    'longitude': longitude,
                    'prediction': 'error',
                    'severity': 'low'
                })
        
        return jsonify(results)
    
    except Exception as e:
        print(f"Batch prediction error: {str(e)}")
        return jsonify({'error': str(e)}), 500

def map_to_severity(prediction):
    # Map your model's output to severity levels used in the app
    severity_map = {
        'high_risk': 'high',
        'medium_risk': 'medium',
        'low_risk': 'low',
        # Add mappings for all your model's output classes
    }
    return severity_map.get(prediction, 'low')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)