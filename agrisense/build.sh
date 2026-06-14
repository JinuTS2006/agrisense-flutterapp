#!/usr/bin/env bash
# exit on error
set -o errexit

pip install -r requirements.txt

# Extract the ML model using python to avoid OS/unzip issues
python -c "
import os, zipfile
zip_path = 'ml_module/yield_model.zip'
if os.path.exists(zip_path):
    print('Extracting yield model...')
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall('ml_module/')
"


python manage.py collectstatic --no-input
python manage.py migrate
