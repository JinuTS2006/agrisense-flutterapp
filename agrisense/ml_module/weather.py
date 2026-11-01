import os
import requests

API_KEY = os.environ.get("OPENWEATHER_API_KEY", "")

def get_weather_for_city(city):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    data = response.json()
    
    return {
        "temperature": data["main"]["temp"],
        "humidity": data["main"]["humidity"],
        "rainfall": data.get("rain", {}).get("1h", 0)  # fallback to 0 if no rain
    }