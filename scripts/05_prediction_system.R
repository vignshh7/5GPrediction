# ============================================================================
# Script 05: Prediction & Evaluation System
# ============================================================================

cat("\n========================================\n")
cat("PREDICTION & EVALUATION\n")
cat("========================================\n\n")

suppressMessages({
  library(randomForest)
  library(dplyr)
})

# Load model and test data
cat("Loading trained model...\n")
rf_model <- readRDS("models/random_forest_model.rds")
test_data <- read.csv("data/processed/test_data.csv", stringsAsFactors = FALSE)
feature_metadata <- readRDS("data/processed/feature_metadata.rds")

test_data$Congestion_Risk <- suppressWarnings(as.factor(test_data$Congestion_Risk))

# Make predictions
cat("Generating predictions on test data...\n")
predictions <- predict(rf_model, test_data, type = "prob")
pred_class <- predict(rf_model, test_data)

# Calculate risk scores and alert levels
risk_scores <- suppressWarnings(predictions[, "1"] * 100)

alert_levels <- suppressWarnings(cut(risk_scores,
                    breaks = c(-Inf, 25, 50, 75, Inf),
                    labels = c("LOW", "MEDIUM", "HIGH", "CRITICAL")))

# Create results
results <- data.frame(
  Actual = test_data$Congestion_Risk,
  Predicted = pred_class,
  Risk_Score = round(risk_scores, 2),
  Alert_Level = alert_levels,
  Correct = test_data$Congestion_Risk == pred_class
)

write.csv(results, "models/test_predictions.csv", row.names = FALSE)

# Display results
cat("\n")
cat("PREDICTION RESULTS:\n")
cat("─────────────────────────────────────────\n")

accuracy <- mean(results$Correct) * 100
cat(paste("Accuracy:", round(accuracy, 2), "%\n"))
cat(paste("Total Predictions:", nrow(results), "\n"))

alert_summary <- table(results$Alert_Level)
cat("\nAlert Level Distribution:\n")
for(level in names(alert_summary)) {
  cat(paste("  ", level, ":", alert_summary[level], "\n"))
}

cat("\nSample Predictions:\n")
cat("─────────────────────────────────────────\n")
print(head(results[, c("Predicted", "Risk_Score", "Alert_Level")], 10))

cat("\n✓ Predictions complete\n")
cat("✓ Results saved: models/test_predictions.csv\n\n")

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
# Example Usage (Commented out for clean pipeline execution)
# ============================================================================

# cat("✓ Prediction system loaded\n")
