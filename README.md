# 5G Network Congestion Prediction

This project predicts congestion in a 5G network before users feel it, using a Random Forest model trained on QoS metrics. The pipeline cleans a real-world dataset, engineers features, trains the model, and outputs risk scores with alert levels.

## What You Get
- Cleaned and engineered datasets
- A trained Random Forest model
- Test predictions with risk scores and alert levels
- Feature importance report

## Dataset (Quick View)
- Source file: `Quality of Service 5G.csv`
- Records: 400 connections
- Collected: September 3, 2023, 10:00 AM
- Fields: Timestamp, User_ID, Application_Type, Signal_Strength, Latency, Required_Bandwidth, Allocated_Bandwidth, Resource_Allocation

## Pipeline Summary
1. Data preprocessing (clean units, fix ranges, handle missing values)
2. Feature engineering (8 derived features + encoding)
3. Train/test split (80/20 stratified)
4. Model training (Random Forest, 100 trees)
5. Prediction + alert levels (LOW/MEDIUM/HIGH/CRITICAL)

## How To Run
### Requirements
- R 4.5.1 or higher
- Packages: dplyr, caret, randomForest, lubridate (auto-installed by the script)

### Full Pipeline
```r
# From the repository root
Rscript run_analysis.R
```

### Run Individual Steps
```r
source("scripts/01_data_preprocessing.R")
source("scripts/03_feature_engineering.R")
source("scripts/04_model_training_clean.R")
```

## Outputs
- `data/processed/cleaned_data.csv`
- `data/processed/engineered_features.csv`
- `models/random_forest_model.rds`
- `models/test_predictions.csv`
- `models/feature_importance.csv`

## Project Structure
```
.
├── run_analysis.R
├── scripts/
│   ├── 01_data_preprocessing.R
│   ├── 03_feature_engineering.R
│   ├── 04_model_training_clean.R
│   └── 06_prediction_system.R
├── data/
│   ├── raw/
│   └── processed/
├── models/
└── visualizations/
```

## Notes
- Congestion rule: `Latency > 45 ms` or `Resource_Allocation > 80%`
- Risk score: percentage of trees voting for congestion

DEVELOPED FOR DATASET 2024 BY TEAM DEOCDERS
