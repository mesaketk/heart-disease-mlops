# Heart Disease Prediction - MLOps Project

A complete MLOps pipeline for heart disease prediction using UCI Heart Disease dataset.

## 🎯 Project Overview

This project demonstrates end-to-end MLOps practices including:
- Data preprocessing and EDA
- Model training with experiment tracking
- CI/CD pipeline with GitHub Actions
- Containerization with Docker
- Kubernetes deployment
- API serving with Flask
- Comprehensive testing

## 📁 Project Structure

```
heart-disease-mlops/
├── data/                   # Data files and download script
├── notebooks/              # Jupyter notebooks for EDA
├── src/                    # Source code
│   ├── data_preprocessing.py
│   ├── train.py
│   └── inference.py
├── models/                 # Trained models
├── tests/                  # Unit tests
├── deployment/             # Kubernetes manifests
├── .github/workflows/      # CI/CD pipeline
├── app.py                  # Flask API
├── Dockerfile              # Container configuration
└── requirements.txt        # Dependencies
```

## 🚀 Quick Start

### 1. Setup Environment

```bash
# Install dependencies
pip install -r requirements.txt

# Download dataset
python data/download_data.py
```

### 2. Run EDA

```bash
jupyter notebook notebooks/01_eda.ipynb
```

### 3. Train Models

```bash
# Preprocess data
python src/data_preprocessing.py

# Train models
python src/train.py

# View MLflow UI
mlflow ui
# Open: http://localhost:5000
```

### 4. Run Tests

```bash
pytest tests/ -v
```

### 5. Run API Locally

```bash
python app.py
# API available at: http://localhost:5000
```

Test the API:
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
  }'
```

## 🐳 Docker

### Build and Run

```bash
# Build image
docker build -t heart-disease-api .

# Run container
docker run -p 5000:5000 heart-disease-api

# Test
curl http://localhost:5000/health
```

## ☸️ Kubernetes Deployment

### Local Deployment (Minikube)

```bash
# Start Minikube
minikube start

# Load Docker image
minikube image load heart-disease-api:latest

# Deploy
kubectl apply -f deployment/kubernetes/deployment.yaml
kubectl apply -f deployment/kubernetes/service.yaml

# Get service URL
minikube service heart-disease-service --url
```

### Check Status

```bash
kubectl get pods
kubectl get services
kubectl logs -f <pod-name>
```

## 🧪 Testing

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html
```

## 📊 Features

- **Age**: Age in years
- **Sex**: 1 = male, 0 = female
- **CP**: Chest pain type (0-3)
- **Trestbps**: Resting blood pressure
- **Chol**: Serum cholesterol
- **FBS**: Fasting blood sugar > 120 mg/dl
- **Restecg**: Resting ECG results
- **Thalach**: Maximum heart rate achieved
- **Exang**: Exercise induced angina
- **Oldpeak**: ST depression
- **Slope**: Slope of peak exercise ST segment
- **CA**: Number of major vessels (0-3)
- **Thal**: Thalassemia (1-3)

## 📈 Model Performance

| Model | Accuracy | Precision | Recall | F1-Score | ROC-AUC |
|-------|----------|-----------|--------|----------|---------|
| Logistic Regression | ~0.85 | ~0.83 | ~0.88 | ~0.85 | ~0.91 |
| Random Forest | ~0.88 | ~0.86 | ~0.90 | ~0.88 | ~0.93 |

## 🔄 CI/CD Pipeline

GitHub Actions workflow automatically:
1. Lints code with flake8
2. Runs unit tests
3. Trains models
4. Builds Docker image
5. Uploads artifacts

## 📝 API Endpoints

### GET /
Health check endpoint

### GET /health
Detailed health status

### POST /predict
Make predictions

Request body:
```json
{
  "features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
}
```

Response:
```json
{
  "success": true,
  "prediction": 1,
  "prediction_label": "Heart Disease",
  "confidence": 0.87,
  "probability_disease": 0.87,
  "probability_no_disease": 0.13,
  "timestamp": "2024-01-05T10:30:00"
}
```

## 🛠️ Technologies Used

- Python 3.9
- scikit-learn
- MLflow
- Flask
- Docker
- Kubernetes
- GitHub Actions
- Pytest

## 📚 Documentation

For detailed documentation, see:
- [Model Training Guide](docs/training.md)
- [API Documentation](docs/api.md)
- [Deployment Guide](docs/deployment.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- Saket Kumar - MLOps Assignment

## 🙏 Acknowledgments

- UCI Machine Learning Repository for the dataset
- BITS Pilani for the assignment guidelines
