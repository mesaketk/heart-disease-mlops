"""
Inference utilities for making predictions
"""
import joblib
import numpy as np

class HeartDiseasePredictor:
    def __init__(self, model_path='models/best_model.joblib', 
                 scaler_path='models/scaler.joblib'):
        """Initialize predictor with model and scaler"""
        self.model = joblib.load(model_path)
        self.scaler = joblib.load(scaler_path)
        print(f"✓ Model loaded from {model_path}")
        print(f"✓ Scaler loaded from {scaler_path}")
    
    def predict(self, features):
        """
        Make prediction on input features
        
        Args:
            features: array-like of shape (n_features,) or (n_samples, n_features)
        
        Returns:
            dict with prediction and probability
        """
        # Ensure 2D array
        if len(np.array(features).shape) == 1:
            features = np.array(features).reshape(1, -1)
        else:
            features = np.array(features)
        
        # Scale features
        features_scaled = self.scaler.transform(features)
        
        # Make prediction
        prediction = self.model.predict(features_scaled)
        probability = self.model.predict_proba(features_scaled)
        
        results = []
        for i in range(len(features)):
            results.append({
                'prediction': int(prediction[i]),
                'prediction_label': 'Heart Disease' if prediction[i] == 1 else 'No Heart Disease',
                'probability_no_disease': float(probability[i][0]),
                'probability_disease': float(probability[i][1]),
                'confidence': float(probability[i][prediction[i]])
            })
        
        return results[0] if len(results) == 1 else results

# Example usage
if __name__ == "__main__":
    # Sample patient data
    sample_features = [63, 1, 3, 145, 233, 1, 0, 150, 0, 2.3, 0, 0, 1]
    
    predictor = HeartDiseasePredictor()
    result = predictor.predict(sample_features)
    
    print("\n=== Prediction Result ===")
    print(f"Prediction: {result['prediction_label']}")
    print(f"Confidence: {result['confidence']:.2%}")
    print(f"Probability of Disease: {result['probability_disease']:.2%}")
