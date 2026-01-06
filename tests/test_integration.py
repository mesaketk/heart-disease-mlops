"""
Integration tests for the API
"""
import pytest
import requests
import time

BASE_URL = "http://localhost:5000"

class TestAPIIntegration:
    
    def test_health_endpoint(self):
        """Test health endpoint"""
        response = requests.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'healthy'
        assert data['model_loaded'] == True
    
    def test_predict_endpoint(self):
        """Test prediction endpoint"""
        payload = {
            "features": [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
        }
        response = requests.post(f"{BASE_URL}/predict", json=payload)
        assert response.status_code == 200
        
        data = response.json()
        assert data['success'] == True
        assert 'prediction' in data
        assert data['prediction'] in [0, 1]
        assert 0 <= data['confidence'] <= 1
    
    def test_predict_invalid_input(self):
        """Test prediction with invalid input"""
        payload = {
            "features": [63, 1, 3]  # Too few features
        }
        response = requests.post(f"{BASE_URL}/predict", json=payload)
        assert response.status_code == 400
    
    def test_metrics_endpoint(self):
        """Test Prometheus metrics endpoint"""
        response = requests.get(f"{BASE_URL}/metrics")
        assert response.status_code == 200
        assert 'predictions_total' in response.text

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
