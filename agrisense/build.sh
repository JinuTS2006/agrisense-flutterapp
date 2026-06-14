#!/usr/bin/env bash
# exit on error
set -o errexit

pip install -r requirements.txt

# Extract the ML model using python to avoid OS/unzip issues
python -c "
import os, zipfile, sys
zip_path = 'ml_module/yield_model.zip'
pkl_path = 'ml_module/yield_model.pkl'

if not os.path.exists(zip_path):
    print(f'ERROR: {zip_path} not found!')
    sys.exit(1)

print('Extracting yield model...')
with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall('ml_module/')

if not os.path.exists(pkl_path):
    print(f'ERROR: {pkl_path} not found after extraction!')
    sys.exit(1)

print('Extraction successful!')
"


python manage.py collectstatic --no-input
python manage.py migrate
python manage.py createcachetable
