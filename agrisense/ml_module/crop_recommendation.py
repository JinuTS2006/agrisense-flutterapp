# ml_module/crop_recommendation.py
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
import pickle
import os

# Path to save/load trained model
MODEL_FILE = os.path.join(os.path.dirname(__file__), "crop_model.pkl")

def train_crop_model():
    # Load dataset
    df = pd.read_csv("ml_module/data/crop_data.csv")

    # Features and target
    X = df[['N', 'P', 'K', 'temperature', 'humidity','ph', 'rainfall']]
    y = df['label']

    # Encode target labels
    le = LabelEncoder()
    y = le.fit_transform(y)

    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train RandomForest classifier
    clf = RandomForestClassifier(n_estimators=100, random_state=42)
    clf.fit(X_train, y_train)

    # Save model and label encoder
    with open(MODEL_FILE, "wb") as f:
        pickle.dump((clf, le), f)

    print("Crop Recommendation Model trained and saved!")

def predict_crop(input_data):
    """
    input_data: dict with keys N, P, K, temperature, humidity, ph, rainfall
    Example: 
    {'N':90, 'P':42, 'K':43, 'temperature':25, 'humidity':80, 'ph':6.5, 'rainfall':200}
    """
    with open(MODEL_FILE, "rb") as f:
        clf, le = pickle.load(f)

    df = pd.DataFrame([input_data])
    pred = clf.predict(df)
    crop = le.inverse_transform(pred)[0]
    return crop
def recommend_top_crops(input_features, top_n=3):
    """
    input_features: dict with keys: N, P, K, temperature, humidity, ph, rainfall, season
    Returns top N recommended crops
    """
    import pickle
    import pandas as pd
    import os

    MODEL_FILE = os.path.join(os.path.dirname(__file__), "crop_model.pkl")
    
    # Load model
    with open(MODEL_FILE, "rb") as f:
        model, le = pickle.load(f)
    
    # Prepare input
    df = pd.DataFrame([input_features])
    
    # Predict probabilities
    probs = model.predict_proba(df)[0]  # Array of probabilities
    
    # Get crop names from label encoder
    crops = le.classes_
    
    # Pair crops with probabilities
    crop_probs = list(zip(crops, probs))
    
    # Sort descending and pick top N
    crop_probs.sort(key=lambda x: x[1], reverse=True)
    return crop_probs[:top_n]

# ml_module/crop_recommendation.py

# Suppose your dataset has a column 'label' for crops
import pandas as pd
CROP_DATA_PATH = "ml_module/data/crop_data.csv"

crop_df = pd.read_csv(CROP_DATA_PATH)
ALL_CROPS = crop_df['label'].unique().tolist()  # list of all crops
