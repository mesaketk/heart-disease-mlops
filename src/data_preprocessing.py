"""
Data preprocessing utilities
"""
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
import joblib
import os

class DataPreprocessor:
    def __init__(self):
        self.scaler = StandardScaler()
        
    def load_data(self, filepath='data/heart_disease.csv'):
        """Load dataset"""
        df = pd.read_csv(filepath)
        print(f"✓ Loaded data: {df.shape}")
        return df
    
    def clean_data(self, df):
        """Clean dataset - handle missing values"""
        # Drop rows with missing values
        df_clean = df.dropna()
        
        print(f"✓ Removed {len(df) - len(df_clean)} rows with missing values")
        print(f"✓ Clean data shape: {df_clean.shape}")
        
        return df_clean
    
    def prepare_features(self, df):
        """Prepare features and target"""
        # Convert target to binary (0: no disease, 1: disease)
        df['target'] = (df['target'] > 0).astype(int)
        
        # Separate features and target
        X = df.drop('target', axis=1)
        y = df['target']
        
        print(f"✓ Features shape: {X.shape}")
        print(f"✓ Target distribution: {y.value_counts().to_dict()}")
        
        return X, y
    
    def split_data(self, X, y, test_size=0.2, random_state=42):
        """Split data into train and test sets"""
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        print(f"✓ Train set: {X_train.shape}")
        print(f"✓ Test set: {X_test.shape}")
        
        return X_train, X_test, y_train, y_test
    
    def scale_features(self, X_train, X_test):
        """Scale features using StandardScaler"""
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        print(f"✓ Features scaled")
        
        return X_train_scaled, X_test_scaled
    
    def save_scaler(self, filepath='models/scaler.joblib'):
        """Save the fitted scaler"""
        os.makedirs('models', exist_ok=True)
        joblib.dump(self.scaler, filepath)
        print(f"✓ Scaler saved to {filepath}")
    
    def load_scaler(self, filepath='models/scaler.joblib'):
        """Load a saved scaler"""
        self.scaler = joblib.load(filepath)
        print(f"✓ Scaler loaded from {filepath}")
        return self.scaler

def run_preprocessing():
    """Run full preprocessing pipeline"""
    preprocessor = DataPreprocessor()
    
    # Load and clean data
    df = preprocessor.load_data()
    df_clean = preprocessor.clean_data(df)
    
    # Prepare features
    X, y = preprocessor.prepare_features(df_clean)
    
    # Split data
    X_train, X_test, y_train, y_test = preprocessor.split_data(X, y)
    
    # Scale features
    X_train_scaled, X_test_scaled = preprocessor.scale_features(X_train, X_test)
    
    # Save scaler
    preprocessor.save_scaler()
    
    return X_train_scaled, X_test_scaled, y_train, y_test

if __name__ == "__main__":
    run_preprocessing()
