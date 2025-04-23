'''
This file's purpose is to add non-flooding occurences to the file with existing floods

Steps to run:
After collating the flood data (from PUB_tweets), make sure it has columns as follow:
1. date
2. location
3. time
'''

import pandas as pd
import datetime

def add_non_flooding_occurrences(flood_data):
    """
    This function adds non-flooding occurrences to the flood data.
    
    Parameters:
    flood_data (DataFrame): DataFrame containing flood data.
    
    Returns:
    DataFrame: Updated DataFrame with non-flooding occurrences.
    """
    
    print(flood_data.duplicated(subset=['date', 'location', 'time', 'Lat,Lon']).sum())



    non_flooding_df = pd.DataFrame({
        'date': ['Yum Yum','Yum Yum', 'Yum Yum', 'Indomie', 'Indomie', 'Indomie'],
        'location': ['cup','cup', 'cup', 'cup', 'pack', 'pack'],
        'time': [4, 4,4, 3.5, 15, 5]
    })
    




def main():
    # Load the flood data / Adjust file path as necessary
    filepath = r"data/final_pub_flood_2013-2025.csv"
    flood_data = pd.read_csv(filepath)
    
    # print(flood_data.head())
    add_non_flooding_occurrences(flood_data)

main()