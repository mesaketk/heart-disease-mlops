"""
Model training script with MLflow tracking
"""
import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (accuracy_score, precision_score, recall_score, 
                             f1_score, roc_auc_score, confusion_matrix, 
                             classification_report)
from sklearn.model_selection import cross_val_score
import joblib
import mlflow
import mlflow.sklearn
import matplotlib.pyplot as plt
import seaborn as sns
import os

from data_preprocessing import DataPreprocessor

class ModelTrainer:
    def __init__(self, experiment_name="heart_disease_prediction"):
        mlflow.set_experiment(experiment_name)
        self.models = {}
        self.results = {}
        
    def train_logistic_regression(self, X_train, y_train, X_test, y_test):
        """Train Logistic Regression model"""
        print("\n=== Training Logistic Regression ===")
        
        with mlflow.start_run(run_name="Logistic_Regression"):
            # Train model
            model = LogisticRegression(max_iter=1000, random_state=42)
            model.fit(X_train, y_train)
            
            # Predictions
            y_pred = model.predict(X_test)
            y_pred_proba = model.predict_proba(X_test)[:, 1]
            
            # Calculate metrics
            metrics = self._calculate_metrics(y_test, y_pred, y_pred_proba)
            
            # Cross-validation
            cv_scores = cross_val_score(model, X_train, y_train, cv=5)
            metrics['cv_mean'] = cv_scores.mean()
            metrics['cv_std'] = cv_scores.std()
            
            # Log to MLflow
            mlflow.log_params({
                "model_type": "LogisticRegression",
                "max_iter": 1000,
                "random_state": 42
            })
            mlflow.log_metrics(metrics)
            mlflow.sklearn.log_model(model, "model")
            
            # Save model
            joblib.dump(model, 'models/logistic_regression.joblib')
            
            self.models['logistic_regression'] = model
            self.results['logistic_regression'] = metrics
            
            print(f"✓ Accuracy: {metrics['accuracy']:.4f}")
            print(f"✓ ROC-AUC: {metrics['roc_auc']:.4f}")
            
            return model, metrics
    
    def train_random_forest(self, X_train, y_train, X_test, y_test):
        """Train Random Forest model"""
        print("\n=== Training Random Forest ===")
        
        with mlflow.start_run(run_name="Random_Forest"):
            # Train model
            model = RandomForestClassifier(n_estimators=100, random_state=42)
            model.fit(X_train, y_train)
            
            # Predictions
            y_pred = model.predict(X_test)
            y_pred_proba = model.predict_proba(X_test)[:, 1]
            
            # Calculate metrics
            metrics = self._calculate_metrics(y_test, y_pred, y_pred_proba)
            
            # Cross-validation
            cv_scores = cross_val_score(model, X_train, y_train, cv=5)
            metrics['cv_mean'] = cv_scores.mean()
            metrics['cv_std'] = cv_scores.std()
            
            # Log to MLflow
            mlflow.log_params({
                "model_type": "RandomForest",
                "n_estimators": 100,
                "random_state": 42
            })
            mlflow.log_metrics(metrics)
            mlflow.sklearn.log_model(model, "model")
            
            # Feature importance
            self._plot_feature_importance(model, X_train)
            mlflow.log_artifact("screenshots/feature_importance.png")
            
            # Save model
            joblib.dump(model, 'models/random_forest.joblib')
            
            self.models['random_forest'] = model
            self.results['random_forest'] = metrics
            
            print(f"✓ Accuracy: {metrics['accuracy']:.4f}")
            print(f"✓ ROC-AUC: {metrics['roc_auc']:.4f}")
            
            return model, metrics
    
    def _calculate_metrics(self, y_true, y_pred, y_pred_proba):
        """Calculate evaluation metrics"""
        return {
            'accuracy': accuracy_score(y_true, y_pred),
            'precision': precision_score(y_true, y_pred),
            'recall': recall_score(y_true, y_pred),
            'f1_score': f1_score(y_true, y_pred),
            'roc_auc': roc_auc_score(y_true, y_pred_proba)
        }
    
    def _plot_feature_importance(self, model, X_train):
        """Plot feature importance for tree-based models"""
        if hasattr(model, 'feature_importances_'):
            importance = pd.DataFrame({
                'feature': [f'feature_{i}' for i in range(X_train.shape[1])],
                'importance': model.feature_importances_
            }).sort_values('importance', ascending=False)
            
            plt.figure(figsize=(10, 6))
            plt.barh(importance['feature'][:10], importance['importance'][:10])
            plt.xlabel('Importance')
            plt.title('Top 10 Feature Importances')
            plt.tight_layout()
            
            os.makedirs('screenshots', exist_ok=True)
            plt.savefig('screenshots/feature_importance.png', dpi=300, bbox_inches='tight')
            plt.close()
    
    def compare_models(self):
        """Compare all trained models"""
        print("\n=== Model Comparison ===")
        comparison_df = pd.DataFrame(self.results).T
        print(comparison_df)
        
        # Save comparison
        comparison_df.to_csv('models/model_comparison.csv')
        
        return comparison_df
    
    def save_best_model(self):
        """Save the best performing model"""
        best_model_name = max(self.results, key=lambda x: self.results[x]['accuracy'])
        best_model = self.models[best_model_name]
        
        joblib.dump(best_model, 'models/best_model.joblib')
        print(f"\n✓ Best model ({best_model_name}) saved to models/best_model.joblib")
        
        return best_model

def main():
    """Main training pipeline"""
    print("=== Starting Model Training Pipeline ===\n")
    
    # Preprocessing
    preprocessor = DataPreprocessor()
    df = preprocessor.load_data()
    df_clean = preprocessor.clean_data(df)
    X, y = preprocessor.prepare_features(df_clean)
    X_train, X_test, y_train, y_test = preprocessor.split_data(X, y)
    X_train_scaled, X_test_scaled = preprocessor.scale_features(X_train, X_test)
    preprocessor.save_scaler()
    
    # Train models
    trainer = ModelTrainer()
    trainer.train_logistic_regression(X_train_scaled, y_train, X_test_scaled, y_test)
    trainer.train_random_forest(X_train_scaled, y_train, X_test_scaled, y_test)
    
    # Compare and save best model
    trainer.compare_models()
    trainer.save_best_model()
    
    print("\n✓ Training pipeline completed successfully!")
    print("✓ Run 'mlflow ui' to view experiment tracking")

if __name__ == "__main__":
    main()
