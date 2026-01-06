"""
Download Heart Disease UCI Dataset
"""
import pandas as pd
import os

def download_heart_disease_data():
    """Download and save the heart disease dataset"""
    
    # Column names for the dataset
    column_names = [
        'age', 'sex', 'cp', 'trestbps', 'chol', 
        'fbs', 'restecg', 'thalach', 'exang', 
        'oldpeak', 'slope', 'ca', 'thal', 'target'
    ]
    
    # URL for Cleveland dataset
    url = "https://archive.ics.uci.edu/ml/machine-learning-databases/heart-disease/processed.cleveland.data"
    
    try:
        # Download data
        print("Downloading data...")
        df = pd.read_csv(url, names=column_names, na_values='?')
        
        # Save to CSV
        output_path = os.path.join('data', 'heart_disease.csv')
        df.to_csv(output_path, index=False)
        
        print(f"✓ Data downloaded successfully!")
        print(f"✓ Saved to: {output_path}")
        print(f"✓ Shape: {df.shape}")
        print(f"✓ Columns: {list(df.columns)}")
        
        # Basic info
        print("\n--- Dataset Info ---")
        print(f"Total records: {len(df)}")
        print(f"Missing values: {df.isnull().sum().sum()}")
        print(f"Target distribution:\n{df['target'].value_counts()}")
        
        return df
        
    except Exception as e:
        print(f"✗ Error downloading data: {e}")
        return None

if __name__ == "__main__":
    download_heart_disease_data()
