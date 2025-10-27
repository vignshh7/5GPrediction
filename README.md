# 5G Network Congestion Prediction System

## Project Overview

**Objective:** Develop a machine learning system to predict network congestion in 5G networks before it impacts users, enabling proactive network management and optimal resource allocation.

**Problem Statement:** Network congestion causes slow internet, dropped calls, and poor user experience. By predicting congestion in advance, network operators can take preventive action such as load balancing, resource reallocation, or traffic redirection.

---

## What This System Does

This system performs **three core tasks**:

1. **Data Preprocessing** - Cleans and validates 5G network data
2. **Feature Engineering** - Creates intelligent features from raw network metrics
3. **Congestion Prediction** - Trains a Random Forest model to predict congestion with alert levels

**Output:** Real-time congestion predictions with risk scores (0-100%) and alert levels (LOW/MEDIUM/HIGH/CRITICAL)

---

## Dataset Description

### Dataset Source
- **File:** `Quality of Service 5G.csv`
- **Records:** 400 network connections
- **Date:** September 3, 2023, 10:00 AM
- **Source:** Live 5G network monitoring system

### 8 Raw Data Fields

| # | Field Name | Description | Unit | Range | Example |
|---|------------|-------------|------|-------|---------|
| 1 | **Timestamp** | When connection was recorded | DateTime | Single timestamp | "9/3/2023 10:00" |
| 2 | **User_ID** | Unique user identifier | String | User_1 to User_400 | "User_42" |
| 3 | **Application_Type** | Service being used | Category | 11 types | "Video_Call" |
| 4 | **Signal_Strength** | 5G signal quality | dBm | -100 to -50 | "-75 dBm" |
| 5 | **Latency** | Network response time | milliseconds | 0 to 110 | "30 ms" |
| 6 | **Required_Bandwidth** | Speed needed | Mbps | 0 to 690 | "10 Mbps" |
| 7 | **Allocated_Bandwidth** | Speed provided | Mbps | 0 to 690 | "15 Mbps" |
| 8 | **Resource_Allocation** | Network resources used | Percentage | 50% to 90% | "70%" |

### 11 Application Types

| Application Type | Count | Avg Signal | Avg Latency | Avg Bandwidth | Priority |
|------------------|-------|------------|-------------|---------------|----------|
| Emergency_Service | 47 | -55.7 dBm | 5.57 ms | 0.68 Mbps | Highest |
| Video_Call | 58 | -63.7 dBm | 32.9 ms | 14.4 Mbps | High |
| Online_Gaming | 45 | -63.2 dBm | 29.1 ms | 4.14 Mbps | High |
| VoIP_Call | 46 | -75.8 dBm | 31.3 ms | 81.6 Mbps | Medium |
| Streaming | 47 | -88.4 dBm | 41.8 ms | 3.35 Mbps | Medium |
| Video_Streaming | 47 | -92.0 dBm | 38.8 ms | 2.94 Mbps | Medium |
| Web_Browsing | 48 | -96.4 dBm | 15.6 ms | 0.49 Mbps | Low |
| Background_Download | 47 | -98.2 dBm | 57.0 ms | 548 Mbps | Low |
| IoT_Temperature | 13 | -98.8 dBm | 102 ms | 3.85 Mbps | Low |
| File_Download | 1 | -75.0 dBm | 45 ms | 2.0 Mbps | Low |
| Voice_Call | 1 | -80.0 dBm | 20 ms | 100 Mbps | High |

### Key Dataset Statistics

| Metric | Min | Mean | Max | Std Dev |
|--------|-----|------|-----|---------|
| Signal Strength | -100 dBm | -79.51 dBm | -50 dBm | 17.76 |
| Latency | 0 ms | 33.83 ms | 110 ms | 21.12 |
| Required Bandwidth | 0 Mbps | 77.57 Mbps | 690 Mbps | 178.38 |
| Allocated Bandwidth | 0 Mbps | 80.81 Mbps | 690 Mbps | 178.88 |
| Resource Allocation | 50% | 74.71% | 90% | 8.98 |

---

## Field Interrelationships

Understanding how network metrics correlate helps us engineer better features for congestion prediction.

### Strong Positive Correlation (r = 0.999)
**Required_Bandwidth ↔ Allocated_Bandwidth**
- Network dynamically allocates bandwidth very close to requirements
- When allocation < requirement → potential congestion
- Used to create: `Bandwidth_Deficit` feature

### Moderate Negative Correlation (r = -0.495)
**Resource_Allocation ↔ Required_Bandwidth**
- High bandwidth demands correlate with lower resource percentages
- Resource-intensive apps compete for capacity
- Used to create: `Resource_Pressure` feature

### Moderate Negative Correlation (r = -0.387)
**Signal_Strength ↔ Latency**
- Weaker signal → higher latency
- Combined effect impacts congestion more than individual metrics
- Used to create: `Signal_Latency_Interaction` feature

### Weak Negative Correlation (r = -0.375)
**Required_Bandwidth ↔ Signal_Strength**
- Higher bandwidth needs correlate with weaker signals
- May indicate network strain
- Contributes to: `QoS_Score` composite metric

---

## Feature Engineering Process

We transform 8 raw fields into 25 intelligent features for the model.

### Step 1: Create Target Variable

**Congestion_Risk** (Binary: 0 = Normal, 1 = Congestion)

**Congestion Definition:**
```
IF Latency > 45 ms OR Resource_Allocation > 80%
THEN Congestion_Risk = 1
ELSE Congestion_Risk = 0
```

**Result:**
- Congestion cases: 169 (42.2%)
- Normal cases: 231 (57.8%)

### Step 2: Engineer 8 Derived Features

| # | Feature Name | Formula | Purpose |
|---|--------------|---------|---------|
| 1 | **Bandwidth_Deficit** | `Allocated_Bandwidth - Required_Bandwidth` | Measures undersupply (negative = shortage) |
| 2 | **Bandwidth_Efficiency** | `(Allocated / Required) × 100` | Allocation efficiency percentage |
| 3 | **Signal_Category** | 4 bins: Poor/Fair/Good/Excellent | Categorical signal quality |
| 4 | **Latency_Category** | 4 bins: Low/Medium/High/VeryHigh | Categorical latency level |
| 5 | **Resource_Level** | 4 bins: Low/Medium/High/Critical | Categorical resource usage |
| 6 | **Signal_Latency_Interaction** | `Signal_Strength × Latency` | Combined signal-latency effect |
| 7 | **Resource_Pressure** | `(Resource_Allocation/100) × Latency` | Resource stress indicator |
| 8 | **QoS_Score** | `(|Signal| + BW_Efficiency + (100-Latency) + Resource) / 4` | Overall quality metric |

**Signal_Category Bins:**
- Poor: < -90 dBm
- Fair: -90 to -80 dBm
- Good: -80 to -70 dBm
- Excellent: > -70 dBm

**Latency_Category Bins:**
- Low: < 20 ms
- Medium: 20-40 ms
- High: 40-60 ms
- VeryHigh: > 60 ms

**Resource_Level Bins:**
- Low: 0-60%
- Medium: 60-75%
- High: 75-85%
- Critical: 85-100%

### Step 3: One-Hot Encode Application Types

Transform categorical `Application_Type` into 11 binary features:
- Application_TypeVideo_Call (0 or 1)
- Application_TypeVoice_Call (0 or 1)
- Application_TypeStreaming (0 or 1)
- ... (11 total)

### Step 4: Label Encode Categorical Features

Convert ordered categories to numeric:
- Signal_Category_Num: Poor=1, Fair=2, Good=3, Excellent=4
- Latency_Category_Num: Low=1, Medium=2, High=3, VeryHigh=4
- Resource_Level_Num: Low=1, Medium=2, High=3, Critical=4

### Step 5: Final Feature Selection

**Total Features for Model:** 25

**Breakdown:**
- 5 original numeric fields (Signal_Strength, Latency, Required_Bandwidth, Allocated_Bandwidth, Resource_Allocation)
- 8 derived numeric features (Bandwidth_Deficit, Bandwidth_Efficiency, etc.)
- 11 one-hot encoded application types
- 3 label-encoded categorical features
- Minus 2 zero-variance features removed

**Excluded from Model:**
- Timestamp (not predictive)
- User_ID (identifier only)
- Application_Type (already one-hot encoded)
- DayOfWeek (constant - all same day)
- Original categorical features (replaced by numeric encoding)

---

## Training Process with Dataset

### Step 1: Data Preprocessing

**Input:** 400 raw records from CSV

**Operations:**
1. Load dataset from `../DATASET/Quality of Service 5G.csv`
2. Remove duplicates (if any)
3. Clean column names (remove spaces, special chars)
4. Parse units:
   - "-75 dBm" → -75
   - "30 ms" → 30
   - "10 Mbps" → 10
   - "70%" → 70
5. Handle missing values (median imputation for numeric, mode for categorical)
6. Validate ranges:
   - Signal strength clipped to [-100, -50]
   - Latency clipped to [0, ∞]
7. Extract time features (Hour, DayOfWeek, IsWeekend)

**Output:** `cleaned_data.csv` (400 clean records)

### Step 2: Feature Engineering

**Input:** 400 clean records

**Operations:**
1. Create target variable `Congestion_Risk`
2. Generate 8 derived features (formulas above)
3. One-hot encode `Application_Type` (11 features)
4. Label encode categorical variables (3 features)
5. Remove zero-variance features
6. Select 25 final features

**Output:** `engineered_features.csv` (400 records × 25 features)

### Step 3: Train-Test Split

**Split Ratio:** 80% training, 20% testing

**Method:** Stratified sampling (maintains congestion ratio in both sets)

**Result:**
- Training set: 320 records
  - Congestion: 136 (42.5%)
  - Normal: 184 (57.5%)
- Test set: 80 records
  - Congestion: 33 (41.3%)
  - Normal: 47 (58.7%)

### Step 4: Feature Scaling

**Method:** Standardization (Z-score normalization)

**Formula:** `X_scaled = (X - mean) / std_dev`

**Applied to:** All 21 numeric features

**Why:** Random Forest doesn't require scaling, but we do it for consistency

### Step 5: Model Training

**Algorithm:** Random Forest Classifier

**Hyperparameters:**
- Number of trees: 100
- Features per split: sqrt(25) ≈ 5
- Criterion: Gini impurity
- Min samples split: 2 (default)
- Random state: 123 (for reproducibility)

**Training Process:**
1. For each of 100 trees:
   - Randomly sample 320 training records (with replacement)
   - Randomly select 5 features at each split
   - Grow tree until pure or min samples reached
   - Calculate Gini impurity for splits
2. Combine all 100 trees into ensemble
3. Calculate feature importance using Gini decrease

**Training Time:** ~3 seconds

**Output:** `random_forest_model.rds`

### Step 6: Prediction & Alert Generation

**Input:** 80 test records

**Prediction Process:**
1. Pass each test record through all 100 trees
2. Each tree votes: 0 (Normal) or 1 (Congestion)
3. Calculate probability: `P(Congestion) = votes/100`
4. Convert to risk score: `Risk_Score = P(Congestion) × 100`
5. Classify final prediction: `If P(Congestion) > 0.5 then 1 else 0`
6. Generate alert level based on risk score:
   - LOW: 0-25%
   - MEDIUM: 25-50%
   - HIGH: 50-75%
   - CRITICAL: 75-100%

**Output:** `test_predictions.csv` with columns:
- Actual (true label)
- Predicted (model prediction)
- Risk_Score (0-100)
- Alert_Level (LOW/MEDIUM/HIGH/CRITICAL)
- Correct (TRUE/FALSE)

---

## Model Performance

### Accuracy Metrics

**Overall Accuracy:** 100% (80/80 correct predictions)

**Confusion Matrix:**
```
                Predicted
                Normal  Congestion
Actual  Normal    47       0
        Congest    0      33
```

**Classification Metrics:**
- Precision: 100%
- Recall: 100%
- F1-Score: 100%
- Out-of-Bag Error: 0.83%

### Alert Level Distribution

| Alert Level | Count | Percentage | Risk Range |
|-------------|-------|------------|------------|
| LOW | 41 | 51.3% | 0-25% |
| MEDIUM | 0 | 0% | 25-50% |
| HIGH | 2 | 2.5% | 50-75% |
| CRITICAL | 37 | 46.3% | 75-100% |

**Interpretation:** Model confidently classifies most cases as either low risk (normal) or critical risk (congestion), with very few borderline cases.

### Top 10 Most Important Features

| Rank | Feature | Importance Score | Category |
|------|---------|------------------|----------|
| 1 | Resource_Allocation | 24.88 | Original |
| 2 | Resource_Pressure | 23.31 | Derived |
| 3 | Latency | 20.53 | Original |
| 4 | Signal_Latency_Interaction | 17.11 | Derived |
| 5 | Allocated_Bandwidth | 11.69 | Original |
| 6 | Bandwidth_Deficit | 9.24 | Derived |
| 7 | Bandwidth_Efficiency | 7.77 | Derived |
| 8 | Latency_Category_Num | 7.21 | Encoded |
| 9 | Required_Bandwidth | 6.36 | Original |
| 10 | Resource_Level_Num | 6.25 | Encoded |

**Key Insights:**
1. **Resource_Allocation** is the single most predictive feature (24.88%)
2. **Derived features** (Resource_Pressure, Signal_Latency_Interaction) rank very high
3. **Top 3 features** account for 68.72% of model's decision-making
4. **Application types** have low importance (not in top 10)

---

## Implementation Steps

### Step 1: Data Preprocessing
**Script:** `scripts/01_data_preprocessing.R`

**What it does:**
1. Loads raw dataset (400 records)
2. Removes duplicates
3. Converts string values to numeric (removes units)
4. Handles missing values
5. Validates data ranges
6. Extracts time features

**Input:** `../DATASET/Quality of Service 5G.csv`

**Output:**
- `data/processed/cleaned_data.csv`
- `data/processed/data_dictionary.csv`
- `data/processed/summary_statistics.csv`

**Console Output:**
```
Loading dataset...
✓ Loaded: 400 records
Cleaning data...
✓ Data cleaned
✓ Data preprocessed: 400 records ready
```

### Step 2: Feature Engineering
**Script:** `scripts/03_feature_engineering.R`

**What it does:**
1. Creates target variable (Congestion_Risk)
2. Engineers 8 derived features
3. One-hot encodes Application_Type (11 features)
4. Label encodes categorical features (3 features)
5. Removes zero-variance features
6. Splits into train (320) and test (80)
7. Scales numeric features

**Input:** `data/processed/cleaned_data.csv`

**Output:**
- `data/processed/engineered_features.csv`
- `data/processed/train_data.csv`
- `data/processed/test_data.csv`
- `data/processed/feature_metadata.rds`

**Console Output:**
```
Loading data...
Creating features...
✓ Features ready: 21 features, 320 train, 80 test
```

### Step 3: Model Training & Prediction
**Script:** `scripts/04_model_training_clean.R`

**What it does:**
1. Loads train and test data
2. Trains Random Forest model (100 trees)
3. Makes predictions on test set
4. Calculates risk scores (0-100%)
5. Assigns alert levels (LOW/MEDIUM/HIGH/CRITICAL)
6. Calculates accuracy
7. Computes feature importance

**Input:**
- `data/processed/train_data.csv`
- `data/processed/test_data.csv`
- `data/processed/feature_metadata.rds`

**Output:**
- `models/random_forest_model.rds`
- `models/test_predictions.csv`
- `models/feature_importance.csv`

**Console Output:**
```
Loading data...
Training model...

RESULTS:
─────────────────────────────────────────
Accuracy: 100 %

Alert Levels:
   LOW : 41
   MEDIUM : 0
   HIGH : 2
   CRITICAL : 37

Sample Predictions:
   Predicted Risk_Score Alert_Level
1          0         14         LOW
2          0         23         LOW
3          1         90    CRITICAL
...

✓ Model training complete
✓ Predictions saved: models/test_predictions.csv
```

---

## Project Structure

```
da2/
├── run_analysis.R              # Main execution script
├── README.md                   # This file
├── scripts/                    # R scripts
│   ├── 01_data_preprocessing.R
│   ├── 03_feature_engineering.R
│   ├── 04_model_training_clean.R
│   └── 06_prediction_system.R
├── data/
│   ├── raw/                    # Original data backup
│   │   └── original_data.csv
│   └── processed/              # Cleaned and engineered data
│       ├── cleaned_data.csv
│       ├── data_dictionary.csv
│       ├── summary_statistics.csv
│       ├── engineered_features.csv
│       ├── train_data.csv
│       ├── test_data.csv
│       ├── train_data_scaled.csv
│       ├── test_data_scaled.csv
│       └── feature_metadata.rds
└── models/                     # Trained models and results
    ├── random_forest_model.rds
    ├── test_predictions.csv
    └── feature_importance.csv
```

---

## How to Run

### Requirements
- R version 4.5.1 or higher
- Required packages (auto-installed):
  - dplyr
  - caret
  - randomForest
  - lubridate

### Execute Complete Pipeline

```r
# From da2 folder
Rscript run_analysis.R
```

**This will:**
1. Preprocess 400 records
2. Engineer 25 features
3. Train Random Forest model
4. Generate predictions with alert levels
5. Save all outputs

**Runtime:** ~6 seconds

**Expected Output:**
```
╔══════════════════════════════════════════╗
║  5G CONGESTION PREDICTION SYSTEM     ║
╚══════════════════════════════════════════╝

DATA PREPROCESSING → FEATURE ENGINEERING → MODEL TRAINING

RESULTS:
Accuracy: 100%
Alert Levels: LOW (41), HIGH (2), CRITICAL (37)

Duration: ~6 seconds
Results: models/test_predictions.csv
```

### Run Individual Steps

```r
# Step 1: Data Preprocessing
source("scripts/01_data_preprocessing.R")

# Step 2: Feature Engineering
source("scripts/03_feature_engineering.R")

# Step 3: Model Training
source("scripts/04_model_training_clean.R")
```

### View Results

```r
# Load predictions
predictions <- read.csv("models/test_predictions.csv")
head(predictions)

# Load feature importance
importance <- read.csv("models/feature_importance.csv")
head(importance, 10)

# Load trained model
model <- readRDS("models/random_forest_model.rds")
print(model)
```

---

## Key Features Used in Model

### Original Features (5)
1. **Signal_Strength** - 5G signal quality in dBm
2. **Latency** - Network response time in ms
3. **Required_Bandwidth** - Application bandwidth requirement
4. **Allocated_Bandwidth** - Network bandwidth allocation
5. **Resource_Allocation** - Percentage of resources used

### Derived Features (8)
1. **Bandwidth_Deficit** - Gap between allocated and required
2. **Bandwidth_Efficiency** - Allocation efficiency ratio
3. **Signal_Category** - Categorical signal quality
4. **Latency_Category** - Categorical latency level
5. **Resource_Level** - Categorical resource usage
6. **Signal_Latency_Interaction** - Combined signal-latency effect
7. **Resource_Pressure** - Resource stress indicator
8. **QoS_Score** - Overall quality of service metric

### Application Type Features (11)
One-hot encoded binary features for each application type:
- Application_TypeBackground_Download
- Application_TypeEmergency_Service
- Application_TypeFile_Download
- Application_TypeIoT_Temperature
- Application_TypeOnline_Gaming
- Application_TypeStreaming
- Application_TypeVideo_Call
- Application_TypeVideo_Streaming
- Application_TypeVoIP_Call
- Application_TypeVoice_Call
- Application_TypeWeb_Browsing

### Encoded Categorical Features (3)
1. **Signal_Category_Num** - Numeric encoding of signal categories (1-4)
2. **Latency_Category_Num** - Numeric encoding of latency categories (1-4)
3. **Resource_Level_Num** - Numeric encoding of resource levels (1-4)

**Total:** 27 features initially created → 25 features after removing 2 zero-variance features

---

## Technical Details

### Machine Learning Algorithm
**Random Forest Classifier**
- Ensemble method combining 100 decision trees
- Each tree trained on random subset of data (bootstrap sampling)
- Each split considers random subset of features (sqrt(25) ≈ 5 features)
- Final prediction: majority vote from all trees
- Handles non-linear relationships and feature interactions automatically
- Resistant to overfitting due to ensemble averaging

### Why Random Forest?
1. **High accuracy** on tabular data
2. **Handles mixed data types** (numeric, categorical)
3. **Feature importance** built-in
4. **No feature scaling required** (though we do it anyway)
5. **Robust to outliers**
6. **Handles non-linear relationships**
7. **Resistant to overfitting**

### Feature Importance Calculation
Uses **Gini importance** (Mean Decrease in Gini):
- Measures how much each feature decreases impurity when used for splitting
- Higher value = more important for classification
- Summed across all trees and normalized

### Probability Calibration
```
Risk_Score = P(Congestion=1) × 100
```
Where P(Congestion=1) is the fraction of trees voting for congestion class.

### Alert Level Thresholds
```
if Risk_Score < 25:  Alert = LOW
elif Risk_Score < 50: Alert = MEDIUM
elif Risk_Score < 75: Alert = HIGH
else:                Alert = CRITICAL
```

---

## Results Summary

| Metric | Value |
|--------|-------|
| **Dataset Size** | 400 records |
| **Training Set** | 320 records (80%) |
| **Test Set** | 80 records (20%) |
| **Features Used** | 25 features |
| **Model Type** | Random Forest (100 trees) |
| **Training Time** | ~3 seconds |
| **Test Accuracy** | 100% |
| **Precision** | 100% |
| **Recall** | 100% |
| **F1-Score** | 100% |
| **Most Important Feature** | Resource_Allocation (24.88%) |
| **Alert Distribution** | LOW: 51%, CRITICAL: 46%, HIGH: 3% |

---

## Contact & Credits

**Course:** PDS (Probability and Data Science) - Semester 5  
**Project:** 5G Network Congestion Prediction  
**Date:** October 2025  
**Technology:** R 4.5.1, Random Forest, Machine Learning  

---

**Last Updated:** October 27, 2025  
**Status:** ✅ Production Ready  
**Accuracy:** 100%  
**Runtime:** ~6 seconds
