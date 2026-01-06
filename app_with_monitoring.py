"""
Flask API with Prometheus Monitoring and Advanced Logging - FIXED
"""
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import numpy as np
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
import sys
import os
import time

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from src.inference import HeartDiseasePredictor

# Setup logging
os.makedirs('logs', exist_ok=True)

# File handler
file_handler = RotatingFileHandler(
    'logs/api.log', 
    maxBytes=10485760,  # 10MB
    backupCount=10
)
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
))

# Console handler
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(levelname)s - %(message)s'
))

# Configure logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)
logger.addHandler(console_handler)

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Define Prometheus metrics BEFORE using them
prediction_counter = Counter(
    'predictions_total', 
    'Total number of predictions',
    ['status', 'prediction_label']
)

prediction_histogram = Histogram(
    'prediction_duration_seconds',
    'Time spent processing prediction'
)

model_confidence_gauge = Gauge(
    'model_confidence',
    'Confidence of the last prediction'
)

http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

# Load model at startup
predictor = None
try:
    predictor = HeartDiseasePredictor()
    logger.info("✓ Model loaded successfully")
except Exception as e:
    logger.error(f"✗ Error loading model: {e}")

@app.before_request
def log_request_info():
    """Log incoming request details"""
    logger.info(f'Request: {request.method} {request.path} from {request.remote_addr}')

@app.after_request
def log_response_info(response):
    """Log response details and update metrics"""
    logger.info(f'Response: {response.status_code}')
    
    # Update HTTP request counter
    http_requests_total.labels(
        method=request.method,
        endpoint=request.path,
        status=response.status_code
    ).inc()
    
    return response

@app.route('/', methods=['GET'])
def home():
    """Health check endpoint"""
    logger.info("Home endpoint accessed")
    return jsonify({
        'status': 'healthy',
        'service': 'Heart Disease Prediction API',
        'version': '1.0.0',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Prediction endpoint with monitoring
    """
    start_time = time.time()
    
    try:
        # Get JSON data
        data = request.get_json()
        
        if not data or 'features' not in data:
            logger.warning("Missing 'features' in request")
            prediction_counter.labels(status='error', prediction_label='none').inc()
            return jsonify({
                'error': 'Missing features in request',
                'expected_format': {
                    'features': [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
                }
            }), 400
        
        features = data['features']
        
        # Validate features
        if not isinstance(features, list) or len(features) != 13:
            logger.warning(f"Invalid features length: {len(features)}")
            prediction_counter.labels(status='error', prediction_label='none').inc()
            return jsonify({
                'error': 'Features must be a list of 13 values'
            }), 400
        
        # Make prediction
        logger.info(f"Processing prediction request - Features: {features[:3]}...")
        result = predictor.predict(features)
        
        # Calculate latency
        latency = time.time() - start_time
        
        # Update metrics
        prediction_counter.labels(
            status='success', 
            prediction_label=result['prediction_label']
        ).inc()
        model_confidence_gauge.set(result['confidence'])
        prediction_histogram.observe(latency)
        
        logger.info(
            f"Prediction: {result['prediction_label']}, "
            f"Confidence: {result['confidence']:.2%}, "
            f"Latency: {latency:.3f}s"
        )
        
        return jsonify({
            'success': True,
            'prediction': result['prediction'],
            'prediction_label': result['prediction_label'],
            'confidence': result['confidence'],
            'probability_disease': result['probability_disease'],
            'probability_no_disease': result['probability_no_disease'],
            'latency_seconds': latency,
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}", exc_info=True)
        prediction_counter.labels(status='error', prediction_label='none').inc()
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Detailed health check with metrics"""
    health_status = {
        'status': 'healthy' if predictor is not None else 'unhealthy',
        'model_loaded': predictor is not None,
        'timestamp': datetime.now().isoformat(),
        'uptime_seconds': time.time() - app.start_time if hasattr(app, 'start_time') else 0
    }
    logger.debug(f"Health check: {health_status}")
    return jsonify(health_status)

@app.route('/metrics', methods=['GET'])
def metrics():
    """
    Prometheus metrics endpoint
    Returns metrics in Prometheus format
    """
    logger.debug("Metrics endpoint accessed")
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == '__main__':
    app.start_time = time.time()
    logger.info("Starting Heart Disease Prediction API with monitoring...")
    logger.info(f"Metrics available at: http://0.0.0.0:5000/metrics")
    app.run(host='0.0.0.0', port=5000, debug=False)