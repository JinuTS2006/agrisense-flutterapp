#!/usr/bin/env bash
# exit on error
set -o errexit

pip install -r requirements.txt

# Extract the ML model if it exists
if [ -f "ml_module/yield_model.zip" ]; then
    echo "Extracting yield model..."
    unzip -o ml_module/yield_model.zip -d ml_module/
fi

python manage.py collectstatic --no-input
python manage.py migrate
