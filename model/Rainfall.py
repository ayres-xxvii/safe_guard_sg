'''
This file's purpose is to include the rainfall data into the flood data. (1h, 2h, 3h prior)

To take note:
1. The earliest rainfall data available seems to be 2016-12-02T21:50:00 - https://api-open.data.gov.sg/v2/real-time/api/rainfall?date=2016-12-02T21:50:00
    anything before that seems to be empty. As such, I will be removing any flood data before that date.

After collating the flood data, make sure it has columns as follow:
1. date
2. location
3. time

Steps to run:
1. Change filepath variable to the path of the flood data csv file
'''

import pandas as pd
from datetime import datetime, timedelta
import requests

import math

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

def get_rainfall_data(date, time, lat_lon):

    lat, lon = map(float, lat_lon.split(","))
    nearest_station_id = None
    rainfalls = [] # Expected Output: [1hr prior to flood, 2hr '...', 3hr '...']
    
    # only taking 1hr, 2hr, 3hr prior instead of rainfall at time of flood 
    # because we're trying to predict the rainfall and not just detect. (i think lol)
    for hrs in range(1, 4):

        request_datetime = datetime.strptime(f"{date} {time}", "%Y-%m-%d %H%M") - timedelta(hours=hrs)
        request_date = request_datetime.strftime("%Y-%m-%d")
        request_time = request_datetime.strftime("%H:%M:%S")
        
        api_url = f"https://api-open.data.gov.sg/v2/real-time/api/rainfall?date={request_date}T{request_time}"
        response = requests.get(api_url)

        if response.status_code == 200:
            data = response.json()
            readings = data['data']['readings'][0].get('data', [])
            stations = data['data'].get('stations', [])        
            
            # Find the nearest station
            if not nearest_station_id:
                nearest_station_id, distance = find_nearest_station(lat, lon, stations)
                print(f"Location: {lat_lon}")
                print(f"Nearest rainfall station ID: {nearest_station_id}, Distance: {distance:.2f} km")
            
            found = False
            for reading in readings:
                if reading['stationId'] == nearest_station_id:
                    rainfalls.append(reading['value'])
                    found = True
            if not found:
                print(f"Error: Station ID {nearest_station_id} not found in readings for date {date} and time {time}")
                
                exit(1)
        
        elif response.status_code == 404:
            print(f"Error URL: {api_url}")
            print("Error: No data available for the specified date and time.")
            return None, None, None, None

        else:
            print(f"Error URL: {api_url}")
            print(f"Error: {response.status_code} - {response.text}")

            #exit so i dont make anymore changes to the dataset
            exit(1)

    return rainfalls[0], rainfalls[1], rainfalls[2], distance

def main():
    # Load the flood data / Adjust file path as necessary
    filepath = "data/full_2013-2025.csv"
    flood_data = pd.read_csv(filepath, dtype=str) 
    rainfall_1hr_prior = []
    rainfall_2hr_prior = []
    rainfall_3hr_prior = []
    nearest_station_distance = []
    
    print(flood_data.head())

    for occurence in flood_data.iterrows():
        date = str(occurence[1]['date'])
        time = str(occurence[1]['time'])
        lat_lon = str(occurence[1]['lat_lon'])
        
        # if datetime.strptime((date +" "+ datetime.strptime(time, "%H%M").strftime("%H:%M"))
        #                      , "%Y-%m-%d %H:%M") < datetime(2016, 12, 3, 0, 50):
        #     print(f"\nData occurred on {date} at {time}; before 2016-12-02 detected. Skipping...\n")
        #     flood_data.drop(occurence[0], inplace=True)
        #     continue

        hr_1, hr_2, hr_3, station_distance = get_rainfall_data(date, time, lat_lon)   
        if hr_1 is None and hr_2 is None and hr_3 is None:
            print(f"Error: Unable to retrieve rainfall data for date {date} and time {time}. Dropping this entry...")
            flood_data.drop(occurence[0], inplace=True)
            continue
        else:
            rainfall_1hr_prior.append(hr_1); rainfall_2hr_prior.append(hr_2); rainfall_3hr_prior.append(hr_3); nearest_station_distance.append(station_distance)

    # Add the new columns to the DataFrame
    # Ensure the lists have the same length as the DataFrame
    if len(rainfall_1hr_prior) == len(flood_data) and \
       len(rainfall_2hr_prior) == len(flood_data) and \
       len(rainfall_3hr_prior) == len(flood_data) and \
       len(nearest_station_distance) == len(flood_data):
        flood_data['rainfall_1hr_prior'] = rainfall_1hr_prior
        flood_data['rainfall_2hr_prior'] = rainfall_2hr_prior
        flood_data['rainfall_3hr_prior'] = rainfall_3hr_prior
        flood_data['nearest_station_distance'] = nearest_station_distance
    else:
        print("Error: Mismatch in lengths of rainfall data and flood data.")
        exit(1)

    # Save the updated DataFrame to a new CSV file
    flood_data.to_csv(f"data/final_{filepath}.csv", index=False)

   
main()