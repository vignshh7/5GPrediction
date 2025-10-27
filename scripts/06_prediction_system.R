# ============================================================================
# Script 06: Real-time Prediction System for 5G Network Congestion
# ============================================================================
# Purpose: Provide real-time congestion prediction and risk assessment
# Author: PDS Course Project
# Date: October 2025
# ============================================================================

cat("\n========================================\n")
cat("SCRIPT 06: PREDICTION SYSTEM\n")
cat("========================================\n\n")

# Load required libraries
suppressMessages({
  library(randomForest)
  library(dplyr)
})

# ============================================================================
# Load Trained Models and Metadata
# ============================================================================

cat("Loading trained models...\n")

# Load models
rf_model <- readRDS("models/random_forest_model.rds")
feature_metadata <- readRDS("data/processed/feature_metadata.rds")

cat("✓ Models loaded successfully\n\n")

# ============================================================================
# Prediction Function
# ============================================================================

predict_congestion <- function(new_data) {
  #' Predict Network Congestion Risk
  #' 
  #' @param new_data A data frame with network metrics
  #' @return A list with prediction results
  #' 
  #' Required columns:
  #' - Signal_Strength (dBm)
  #' - Latency (ms)
  #' - Required_Bandwidth (Mbps)
  #' - Allocated_Bandwidth (Mbps)
  #' - Resource_Allocation (%)
  #' - Application_Type (optional)
  
  # Feature engineering on new data
  new_data$Bandwidth_Deficit <- new_data$Required_Bandwidth - new_data$Allocated_Bandwidth
  new_data$Bandwidth_Efficiency <- ifelse(new_data$Required_Bandwidth > 0,
                                          new_data$Allocated_Bandwidth / new_data$Required_Bandwidth * 100,
                                          100)
  new_data$Signal_Latency_Interaction <- new_data$Signal_Strength * new_data$Latency
  new_data$Resource_Pressure <- (new_data$Resource_Allocation / 100) * (new_data$Latency / 100) * 100
  new_data$QoS_Score <- (
    ((new_data$Signal_Strength + 100) / 50) * 0.3 +
    ((150 - new_data$Latency) / 150) * 0.4 +
    (new_data$Bandwidth_Efficiency / 100) * 0.3
  ) * 100
  
  # Categorical encoding
  new_data$Signal_Category <- cut(new_data$Signal_Strength, 
                                   breaks = c(-Inf, -90, -80, -70, -Inf),
                                   labels = c("Poor", "Fair", "Good", "Excellent"),
                                   include.lowest = TRUE)
  new_data$Signal_Category_Num <- as.numeric(new_data$Signal_Category)
  
  new_data$Latency_Category <- cut(new_data$Latency,
                                    breaks = c(-Inf, 20, 40, 60, Inf),
                                    labels = c("Low", "Medium", "High", "Very High"),
                                    include.lowest = TRUE)
  new_data$Latency_Category_Num <- as.numeric(new_data$Latency_Category)
  
  new_data$Resource_Level <- cut(new_data$Resource_Allocation,
                                  breaks = c(-Inf, 60, 75, 90, Inf),
                                  labels = c("Low", "Medium", "High", "Critical"),
                                  include.lowest = TRUE)
  new_data$Resource_Level_Num <- as.numeric(new_data$Resource_Level)
  
  # Make prediction
  prediction <- predict(rf_model, new_data, type = "class")
  probability <- predict(rf_model, new_data, type = "prob")
  
  # Risk score (0-100)
  risk_score <- round(probability[, "1"] * 100, 1)
  
  # Determine alert level
  alert_level <- case_when(
    risk_score < 30 ~ "Low",
    risk_score < 60 ~ "Medium",
    risk_score < 80 ~ "High",
    TRUE ~ "Critical"
  )
  
  # Generate recommendations
  recommendations <- generate_recommendations(new_data, risk_score)
  
  # Return results
  result <- list(
    prediction = as.character(prediction),
    congestion_predicted = as.character(prediction) == "1",
    risk_score = risk_score,
    alert_level = alert_level,
    probability_congestion = probability[, "1"],
    probability_normal = probability[, "0"],
    key_metrics = list(
      signal_strength = new_data$Signal_Strength,
      latency = new_data$Latency,
      resource_allocation = new_data$Resource_Allocation,
      bandwidth_deficit = new_data$Bandwidth_Deficit,
      qos_score = round(new_data$QoS_Score, 1)
    ),
    recommendations = recommendations
  )
  
  return(result)
}

# ============================================================================
# Recommendation Engine
# ============================================================================

generate_recommendations <- function(data, risk_score) {
  recommendations <- character(0)
  
  if (risk_score >= 60) {
    # High risk recommendations
    if (data$Resource_Allocation > 80) {
      recommendations <- c(recommendations, 
                          "• Increase resource allocation capacity")
    }
    
    if (data$Latency > 40) {
      recommendations <- c(recommendations,
                          "• Optimize network routing to reduce latency")
    }
    
    if (data$Bandwidth_Deficit > 2) {
      recommendations <- c(recommendations,
                          "• Allocate additional bandwidth to match demand")
    }
    
    if (data$Signal_Strength < -85) {
      recommendations <- c(recommendations,
                          "• Improve signal coverage in this area")
    }
    
    recommendations <- c(recommendations,
                        "• Consider load balancing to adjacent cells",
                        "• Monitor QoS metrics closely")
  } else if (risk_score >= 30) {
    # Medium risk recommendations
    recommendations <- c(recommendations,
                        "• Monitor resource utilization trends",
                        "• Prepare for potential resource reallocation")
  } else {
    # Low risk
    recommendations <- c(recommendations,
                        "• Network performance is optimal",
                        "• Continue normal monitoring")
  }
  
  return(recommendations)
}

# ============================================================================
# Batch Prediction Function
# ============================================================================

batch_predict <- function(data_file) {
  #' Batch prediction for multiple records
  #' 
  #' @param data_file Path to CSV file with network data
  #' @return Data frame with predictions
  
  data <- read.csv(data_file, stringsAsFactors = FALSE)
  
  results <- lapply(1:nrow(data), function(i) {
    result <- predict_congestion(data[i, ])
    data.frame(
      Row = i,
      Prediction = result$prediction,
      Risk_Score = result$risk_score,
      Alert_Level = result$alert_level,
      QoS_Score = result$key_metrics$qos_score
    )
  })
  
  return(do.call(rbind, results))
}

# ============================================================================
# Example Usage
# ============================================================================

cat("Prediction System Ready!\n\n")
cat("Example Usage:\n")
cat("──────────────────────────────────────────────────────\n\n")
cat("# Create sample observation\n")
cat("new_obs <- data.frame(\n")
cat("  Signal_Strength = -75,\n")
cat("  Latency = 45,\n")
cat("  Required_Bandwidth = 10,\n")
cat("  Allocated_Bandwidth = 8,\n")
cat("  Resource_Allocation = 85\n")
cat(")\n\n")
cat("# Get prediction\n")
cat("result <- predict_congestion(new_obs)\n")
cat("print(result)\n\n")

# Demo prediction
cat("Running Demo Prediction:\n")
cat("──────────────────────────────────────────────────────\n\n")

demo_data <- data.frame(
  Signal_Strength = -75,
  Latency = 45,
  Required_Bandwidth = 10,
  Allocated_Bandwidth = 8,
  Resource_Allocation = 85
)

demo_result <- predict_congestion(demo_data)

cat("Input Metrics:\n")
cat(paste("  Signal Strength:", demo_data$Signal_Strength, "dBm\n"))
cat(paste("  Latency:", demo_data$Latency, "ms\n"))
cat(paste("  Required Bandwidth:", demo_data$Required_Bandwidth, "Mbps\n"))
cat(paste("  Allocated Bandwidth:", demo_data$Allocated_Bandwidth, "Mbps\n"))
cat(paste("  Resource Allocation:", demo_data$Resource_Allocation, "%\n\n"))

cat("Prediction Results:\n")
cat(paste("  Congestion Predicted:", demo_result$congestion_predicted, "\n"))
cat(paste("  Risk Score:", demo_result$risk_score, "/ 100\n"))
cat(paste("  Alert Level:", demo_result$alert_level, "\n"))
cat(paste("  QoS Score:", demo_result$key_metrics$qos_score, "\n\n"))

cat("Recommendations:\n")
for (rec in demo_result$recommendations) {
  cat(paste("  ", rec, "\n"))
}

cat("\n")
cat("========================================\n")
cat("PREDICTION SYSTEM LOADED!\n")
cat("========================================\n")
cat("\nFunctions available:\n")
cat("  - predict_congestion(new_data)\n")
cat("  - batch_predict(data_file)\n\n")
