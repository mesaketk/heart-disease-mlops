#!/bin/bash

echo "=========================================="
echo "Heart Disease MLOps Pipeline - Full Run"
echo "=========================================="
echo ""

# Step 1: Download data
echo "Step 1: Downloading data..."
python data/download_data.py
if [ $? -ne 0 ]; then
    echo "❌ Data download failed"
    exit 1
fi
echo "✓ Data downloaded"
echo ""

# Step 2: Preprocess
echo "Step 2: Preprocessing data..."
python src/data_preprocessing.py
if [ $? -ne 0 ]; then
    echo "❌ Preprocessing failed"
    exit 1
fi
echo "✓ Data preprocessed"
echo ""

# Step 3: Train models
echo "Step 3: Training models..."
python src/train.py
if [ $? -ne 0 ]; then
    echo "❌ Training failed"
    exit 1
fi
echo "✓ Models trained"
echo ""

# Step 4: Run tests
echo "Step 4: Running tests..."
pytest tests/ -v
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi
echo "✓ All tests passed"
echo ""

echo "=========================================="
echo "Pipeline completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Run 'mlflow ui' to view experiments"
echo "2. Run 'python app.py' to start API server"
echo "3. Run 'docker build -t heart-disease-api .' to build container"
echo ""
