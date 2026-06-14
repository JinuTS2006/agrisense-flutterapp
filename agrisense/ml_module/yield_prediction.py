import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestRegressor
import pickle
import os

# Path to save/load the trained model
MODEL_FILE = os.path.join(os.path.dirname(__file__), "yield_model.pkl")

# Import all crops from recommendation model
from ml_module.crop_recommendation import ALL_CROPS  # This list should contain every crop in crop recommendation

def train_yield_model():
    """
    Train the Crop Yield Prediction model using crop, soil, and weather data
    and ensure all crops from recommendation are included.
    """
    # ----------------------
    # Load datasets
    # ----------------------
    yield_df = pd.read_csv("ml_module/data/crop_yield.csv")
    soil_df = pd.read_csv("ml_module/data/state_soil_data.csv")
    weather_df = pd.read_csv("ml_module/data/state_weather_data_1997_2020.csv")

    # ----------------------
    # Merge datasets
    # ----------------------
    df = pd.merge(yield_df, soil_df, on="state", how="left")
    df = pd.merge(df, weather_df, on=["state", "year"], how="left")

    # ----------------------
    # Include missing crops from recommendation
    # ----------------------
    missing_crops = set(ALL_CROPS) - set(df['crop'].unique())
    for crop in missing_crops:
        # Copy a sample row to maintain structure
        temp = df.iloc[[0]].copy()
        temp['crop'] = crop
        # Set numeric features to 0 (or some default/mean if you want)
        temp[['yield','N','P','K','pH','avg_temp_c','avg_humidity_percent','total_rainfall_mm']] = 0
        df = pd.concat([df,temp], ignore_index=True)

    # ----------------------
    # Features + target
    # ----------------------
    features = ['crop','N','P','K','pH','avg_temp_c','avg_humidity_percent','total_rainfall_mm']
    df = df[features + ['yield']].fillna(0)

    # Encode crop names
    le = LabelEncoder()
    df['crop_encoded'] = le.fit_transform(df['crop'])

    # Features and target
    X = df[['crop_encoded','N','P','K','pH','avg_temp_c','avg_humidity_percent','total_rainfall_mm']]
    y = df['yield']

    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train RandomForest Regressor
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    # Save model + label encoder
    with open(MODEL_FILE, "wb") as f:
        pickle.dump((model, le), f)

    print("✅ Yield Prediction Model trained for ALL crops from recommendation!")

# ----------------------
# Prediction function
# ----------------------
CROP_MAPPING = {
    'rice': 'Rice',
    'maize': 'Maize',
    'cotton': 'Cotton(lint)',
    'banana': 'Banana',
    'mango': 'Mango',
    'grapes': 'Grapes',
    'watermelon': 'Watermelon',
    'apple': 'Apple',
    'orange': 'Orange',
    'papaya': 'Papaya',
    'coconut': 'Coconut ',
    'jute': 'Jute',
    'chickpea': 'Gram',
    'lentil': 'Masoor',
    'pigeonpeas': 'Arhar/Tur',
    'mungbean': 'Moong(Green Gram)',
    'blackgram': 'Urad'
}

def predict_yield(crop_name, input_data):
    """
    Predict yield for a given crop and input features
    crop_name: string
    input_data: dict with keys: N,P,K,pH,avg_temp_c,avg_humidity_percent,total_rainfall_mm
    """
    try:
        with open(MODEL_FILE, "rb") as f:
            model, le = pickle.load(f)
    except FileNotFoundError:
        import os
        dir_contents = os.listdir(os.path.dirname(__file__))
        raise Exception(f"Model file not found at {MODEL_FILE}. Contents of directory: {dir_contents}")

    # Clean and map the crop name
    clean_name = crop_name.lower().strip()
    mapped_crop = CROP_MAPPING.get(clean_name, clean_name.capitalize())

    # Encode crop name
    try:
        crop_encoded = le.transform([mapped_crop])[0]
    except ValueError:
        raise ValueError(f"Yield prediction data is not available for '{crop_name}'.")

    df = pd.DataFrame([{'crop_encoded': crop_encoded, **input_data}])

    return model.predict(df)[0]
