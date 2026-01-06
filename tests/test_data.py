"""
Unit tests for data processing
"""
import pytest
import pandas as pd
import numpy as np
import sys
import os

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.data_preprocessing import DataPreprocessor

class TestDataPreprocessing:
    
    def test_data_loading(self):
        """Test if data loads correctly"""
        preprocessor = DataPreprocessor()
        df = preprocessor.load_data('data/heart_disease.csv')
        
        assert df is not None
        assert len(df) > 0
        assert 'target' in df.columns
        assert len(df.columns) == 14
    
    def test_data_cleaning(self):
        """Test data cleaning"""
        preprocessor = DataPreprocessor()
        df = preprocessor.load_data('data/heart_disease.csv')
        df_clean = preprocessor.clean_data(df)
        
        assert df_clean.isnull().sum().sum() == 0
        assert len(df_clean) <= len(df)
    
    def test_feature_preparation(self):
        """Test feature preparation"""
        preprocessor = DataPreprocessor()
        df = preprocessor.load_data('data/heart_disease.csv')
        df_clean = preprocessor.clean_data(df)
        X, y = preprocessor.prepare_features(df_clean)
        
        assert X.shape[0] == y.shape[0]
        assert X.shape[1] == 13  # 13 features
        assert set(y.unique()).issubset({0, 1})
    
    def test_data_split(self):
        """Test train-test split"""
        preprocessor = DataPreprocessor()
        df = preprocessor.load_data('data/heart_disease.csv')
        df_clean = preprocessor.clean_data(df)
        X, y = preprocessor.prepare_features(df_clean)
        X_train, X_test, y_train, y_test = preprocessor.split_data(X, y)
        
        assert len(X_train) > len(X_test)
        assert X_train.shape[1] == X_test.shape[1]
        assert len(y_train) == len(X_train)
        assert len(y_test) == len(X_test)

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
