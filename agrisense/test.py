from ml_module.yield_prediction import MODEL_FILE
import pickle

with open(MODEL_FILE, 'rb') as f:
    model, le = pickle.load(f)
    
print(list(le.classes_))
