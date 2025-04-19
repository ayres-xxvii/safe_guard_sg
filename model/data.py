'''
Since this script is intended to be run only once for initial data collection,

I have decided to making the twitter log in manual. 

Steps when running this script:
1. cd to the folder directory of this file
2. Run python3 data.py
3. A browser window will open, and you will need to log in to your Twitter account.
4. After logging in, the script will automatically navigate to the search URL and start scraping tweets.

Caveats:
1. The script captures time based on "hrs / hr / hours / hour" in the tweet text 
    BUT as of my last iteration, i realised there were 5 tweets that did not follow that pattern.
    However, I am too lazy to change and run anymore. So I just manually changed the 5 tweets in the csv file.

2. (rare but) Sometimes it does not capture ALL tweets...
    like it's due to some inconsistency in the twitter search results 
'''
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

import undetected_chromedriver as uc

import time
import pandas as pd
import re
import os
from datetime import datetime

def setup_driver():
    """Set up the Chrome webdriver with appropriate options."""
    chrome_options = uc.ChromeOptions()
    chrome_options.add_argument("--incognito") # I use this because I am testing this too many times and I dont want it in my history
    # chrome_options.add_argument("--headless") # controls whether the browser is visible
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1920,1080")
    chrome_options.add_argument("--disable-notifications")
    
    driver = uc.Chrome(options=chrome_options)
    return driver

def extract_flood_info(tweet_text):
    """Extract location and time from tweet text using regex patterns."""
    # Pattern to match "flood at {location}."
    location_pattern = re.compile(r'flood at\s+([^.]+)', re.IGNORECASE)
    
    # Pattern to match time format (both hh:mm and hhmm)
    time_pattern = re.compile(r'(\d{1,2}[:]*\d{2})\s*(?:hours|hour|hrs|hr)', re.IGNORECASE)
    
    # Extract location
    location_match = location_pattern.search(tweet_text)
    location = location_match.group(1).strip() if location_match else "Unknown"
    
    # Extract time
    time_match = time_pattern.search(tweet_text)
    time_str = time_match.group(1) if time_match else "Unknown"
    
    # Standardize time format by removing ":"
    standardized_time = time_str.replace(":", "") if time_str != "Unknown" else "Unknown"
    
    return location, standardized_time

def scrape_pub_flood_tweets(driver, search_url, scroll = 1):
    """Scrape PUB Singapore flood tweets and extract location and time."""
    driver.get(r'https://x.com')

    # Wait for tweets to load
    try:
        WebDriverWait(driver, 100).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "article[data-testid='tweet']"))
        )
        driver.get(search_url)
        print(f"Navigating to {search_url}")
        WebDriverWait(driver, 50).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "article[data-testid='tweet']"))
        )
    except TimeoutException:
        print("Timeout waiting for tweets to load")
        return []
    
    flood_data = []
    seen_tweet_ids = set()
    # Scroll and collect tweets
    while scroll:
        print(f"Scrolled {scroll} times")
        time.sleep(10)  # Wait for new content to load
        
        # Extract tweets on current view
        tweet_elements = driver.find_elements(By.CSS_SELECTOR, "article[data-testid='tweet']")

        print(f"Found {len(tweet_elements)} tweets on this page")
        for tweet in tweet_elements:
            try:
                # Extract tweet ID to avoid duplicates
                tweet_links = tweet.find_elements(By.CSS_SELECTOR, "a[href*='/status/']")
                if not tweet_links:
                    print("No tweet links found")
                    continue
                    
                tweet_url = tweet_links[0].get_attribute("href")
                tweet_id = re.search(r"/status/(\d+)", tweet_url).group(1)
                                    
                # Extract tweet text
                try:
                    text_element = tweet.find_element(By.CSS_SELECTOR, "div[data-testid='tweetText']")
                    tweet_text = text_element.text
                except:
                    continue  # Skip tweets without text
                
                # Extract date for reference
                date_element = tweet.find_elements(By.CSS_SELECTOR, "time")
                tweet_date = date_element[0].get_attribute("datetime") if date_element else "Unknown"
                
                # Extract location and time info
                location, time_value = extract_flood_info(tweet_text)

                # Skip if we've already processed this tweet
                if tweet_id in seen_tweet_ids:
                    print(f"Already seen tweet ID: {tweet_id}")
                    if location != "Unknown" or time_value != "Unknown":
                        print(f"Found flood at {location} at {time_value}")
                    continue
                
                seen_tweet_ids.add(tweet_id)

                # Only add entries that have valid location and time
                if location != "Unknown" or time_value != "Unknown":
                    flood_data.append({
                        "tweet_id": tweet_id,
                        "date": tweet_date,
                        "location": location,
                        "time": time_value,
                        "full_text": tweet_text
                    })
                    
                    print(f"Found flood at {location} at {time_value}")
                
            except Exception as e:
                print(f"Error processing tweet: {str(e)}")
                continue
        
        if (driver.execute_script("return (window.innerHeight + window.scrollY) >= document.body.scrollHeight - 5")):
            break

        # Scroll down to load more tweets
        driver.execute_script("window.scrollBy({top:document.documentElement.clientHeight/2, left:0, behaviour: 'instant'});")
        scroll += 1
    
    return flood_data

def save_to_csv(flood_data, filename="pub_flood_locations.csv"):
    """Save the flood location and time data to a CSV file."""
    if not flood_data:
        print("No flood data collected to save")
        return
        
    df = pd.DataFrame(flood_data)
    
    # Format the date for better readability
    if "date" in df.columns:
        df["date"] = pd.to_datetime(df["date"]).dt.strftime("%Y-%m-%d %H:%M:%S")
    
    # Add timestamp to filename to avoid overwriting
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{os.path.splitext(filename)[0]}_{timestamp}.csv"
    
    # Save only essential columns to CSV
    essential_columns = ["date", "location", "time"]
    
    # Check if we have the columns
    available_columns = [col for col in essential_columns if col in df.columns]
    
    df[available_columns].to_csv(filename, index=False)
    print(f"Saved {len(flood_data)} flood records to {filename}")
    
    return filename

def main():
    # Configuration
    search_url = r"https://x.com/search?q=%22flood%20at%22%20-subsided%20(from%3APUBsingapore)&src=typed_query&f=top"
    
    # Initialize driver
    driver = setup_driver()
    
    try:
        # Scrape tweets and extract flood data
        flood_data = scrape_pub_flood_tweets(driver, search_url)
        
        # Save the collected flood data
        if flood_data:
            save_to_csv(flood_data)
            print(f"Successfully collected {len(flood_data)} flood records")
        else:
            print("No flood data was collected")
    
    finally:
        # Clean up
        driver.quit()

main()