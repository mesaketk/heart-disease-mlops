"""
Unit tests for model training and inference
"""
import pytest
import numpy as np
import joblib
import sys
import os

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.inference import HeartDiseasePredictor

class TestModel:
    
    def test_model_exists(self):
        """Test if model file exists"""
        assert os.path.exists('models/best_model.joblib')
        assert os.path.exists('models/scaler.joblib')
    
    def test_model_loading(self):
        """Test if model loads correctly"""
        model = joblib.load('models/best_model.joblib')
        assert model is not None
        assert hasattr(model, 'predict')
        assert hasattr(model, 'predict_proba')
    
    def test_prediction_single(self):
        """Test single prediction"""
        predictor = HeartDiseasePredictor()
        sample = [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
        result = predictor.predict(sample)
        
        assert 'prediction' in result
        assert 'confidence' in result
        assert result['prediction'] in [0, 1]
        assert 0 <= result['confidence'] <= 1
    
    def test_prediction_batch(self):
        """Test batch prediction"""
        predictor = HeartDiseasePredictor()
        samples = [
            [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1],
            [67, 1, 0, 160, 286, 0, 0, 108, 1, 1.5, 1, 3, 2]
        ]
        results = predictor.predict(samples)
        
        assert len(results) == 2
        assert all('prediction' in r for r in results)

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
