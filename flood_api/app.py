from flask import Flask, request, jsonify
import joblib
import os
import glob
import numpy as np
import pandas as pd
import math
import re
from datetime import datetime, timedelta
import requests
from flask_cors import CORS
import random  # For demo purposes

app = Flask(__name__)
CORS(app)

# Load the trained model and label encoder
model_files = [
    'model_5min.pkl',
    'model_10min.pkl',
    'model_15min.pkl',
    'model_30min.pkl',
]
models = []

# Load label encoder
try:
    label_encoder = joblib.load('label_encoder.pkl')
    print(f"Label encoder model loaded successfully")
except Exception as e:
    print(f"Warning: Could not load label encoder model properly: {str(e)}")
    label_encoder = None

for fileName in model_files:
    # Load all models
    try:
        model = joblib.load(os.path.join(os.path.dirname(__file__), "models", fileName))
        models.append(model)
        print(f"Model loaded successfully")
    except Exception as e:
        print(f"Warning: Could not load model properly: {str(e)}")

all_locations = pd.read_csv(os.path.join(os.path.dirname(__file__), '', 'locations.csv'), dtype=str) # Replace with database results

def get_weather_data(location, readings, stations):
    # readings: rainfall values based off station id
    # stations: stations data with their id
    def haversine_distance(lat1, lon1, lat2, lon2):
        """
        Calculates the distance between two geographic coordinates using the Haversine formula
        
        Args:
            lat1 (float): Latitude of the first point in degrees
            lon1 (float): Longitude of the first point in degrees
            lat2 (float): Latitude of the second point in degrees
            lon2 (float): Longitude of the second point in degrees
        
        Returns:
            float: Distance in kilometers
        """
        # Earth's radius in kilometers
        R = 6371.0
        
        # Convert degrees to radians
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        
        # Differences
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        
        # Haversine formula
        a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance = R * c
        
        return distance

    def find_nearest_station(target_lat, target_lon, stations):
        """
        Finds the nearest station to a given latitude and longitude
        
        Args:
            target_lat (float): Target latitude in degrees
            target_lon (float): Target longitude in degrees
            stations (list): List of station dictionaries with location information
        
        Returns:
            str: ID of the nearest station
            float: Distance to the nearest station in kilometers
        """
        if not stations:
            return None, float('inf')
        
        nearest_station = None
        min_distance = float('inf')
        
        for station in stations:
            station_lat = station['location']['latitude']
            station_lon = station['location']['longitude']
            
            distance = haversine_distance(target_lat, target_lon, station_lat, station_lon)
            
            if distance < min_distance:
                min_distance = distance
                nearest_station = station

        return nearest_station['id'], min_distance

    # Get the station closest to the location position
    nearest_station_id, min_distance = find_nearest_station(location['latitude'], location['longitude'], stations)

    rainfall_reading = 0
    # Loop through all stations' rainfall values
    for reading_data in readings:
        if reading_data['stationId'] == nearest_station_id:
            rainfall_reading = reading_data['value']
            break

    new_location_data = location
    new_location_data['rainfall_value'] = rainfall_reading
    new_location_data['nearest_station_distance'] = min_distance

    return new_location_data

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
        predict_batch = {
            "rainfall_5min_prior": [],
            "rainfall_10min_prior": [],
            "rainfall_15min_prior": [],
            "rainfall_20min_prior": [],
            "rainfall_25min_prior": [],
            "rainfall_30min_prior": [],
            "rainfall_35min_prior": [],
            "rainfall_40min_prior": [],
            "rainfall_45min_prior": [],
            "rainfall_50min_prior": [],
            "rainfall_55min_prior": [],
            "rainfall_1hr_prior": [], 
            # "is_floodprone": [],
            "nearest_station_distance": []
        }

        api_data = {
            'readings': [],
            'stations': []
        }

        for mins in range(5, 65, 5):
            # datetime.now() datetime(2018, 1, 24, 17, 15, 0)
            request_datetime = datetime.now() - timedelta(minutes=mins)
            request_date = request_datetime.strftime("%Y-%m-%d")
            request_time = request_datetime.strftime("%H:%M:%S")

            api_url = f"https://api-open.data.gov.sg/v2/real-time/api/rainfall?date={request_date}T{request_time}"
            response = requests.get(api_url)

            if response.status_code == 200:
                data = response.json()
                api_data['readings'].append(data['data']['readings'][0].get('data', []))
                api_data['stations'] = data['data'].get('stations', [])
            elif response.status_code == 404:
                print(f"Error URL: {api_url}")
                print("Error: No data available for the specified date and time.")
                return []

            else:
                print(f"Error URL: {api_url}")
                print(f"Error: {response.status_code} - {response.text}")
                return []
        
        for location in locations:
            # form rainfall_xmin_prior column
            try:
                for i in range(1, 13):
                    # Get rainfall value based of the location position. Passes in the api 
                    location_rainfalls = get_weather_data(location, api_data['readings'][i-1], api_data['stations'])
                    if i*5 < 60:
                        predict_batch[f'rainfall_{i*5}min_prior'].append(location_rainfalls['rainfall_value'])
                    else:
                        predict_batch['rainfall_1hr_prior'].append(location_rainfalls['rainfall_value'])
            except Exception as e:
                print(f"Error processing location {location}: {str(e)}")
            predict_batch['nearest_station_distance'].append(location_rainfalls['nearest_station_distance'])
            # predict_batch['is_floodprone'].append(False)
            results.append({
                'latitude': location_rainfalls['latitude'], 
                'longitude': location_rainfalls['longitude'],
                'severity': 'none'
            })
        
        # Predict the batch and assign to their respective lat long set
        predict_batch = pd.DataFrame(predict_batch)
        drop_columns = [
            [],
            ["rainfall_5min_prior"],
            ["rainfall_10min_prior"],
            ["rainfall_15min_prior","rainfall_20min_prior","rainfall_25min_prior"]
        ]

        # When model predicts high accuracy of flood in 5min model, returns severity high. Remaining unclassified
        # locations continues down 10min model, 15min and 30min for severity classification. Remaining locations get removed
        severity_classification = ['high', 'high', 'medium', 'low']
        severity_weightage = [0.95, 0.95, 0.85, 0.7]
        classified_j = []
        for i in range(len(models)):
            predict_batch_copy = predict_batch.copy()
            predict_batch_copy = predict_batch_copy.drop(columns=drop_columns[i])

            # predict_results = models[i].predict(predict_batch_copy).tolist()
            predict_results = models[i].predict_proba(predict_batch_copy).tolist()
            # print(predict_results)

            for j in range(len(results)):
                probabilities = predict_results[j]
                if j not in classified_j and probabilities[1] >= severity_weightage[i]:
                    results[j]['severity'] = severity_classification[i]
                    classified_j.append(j)

        results = list(filter(lambda x: x['severity'] != 'none', results))
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