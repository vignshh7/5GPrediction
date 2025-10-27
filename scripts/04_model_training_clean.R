# ============================================================================
# Model Training - 5G Network Congestion Prediction
# ============================================================================

cat("\n========================================\n")
cat("MODEL TRAINING & PREDICTION\n")
cat("========================================\n\n")

suppressMessages({
  suppressWarnings({
    library(dplyr)
    library(caret)
    library(randomForest)
  })
})

if (!dir.exists("models")) dir.create("models")

cat("Loading data...\n")

train_data <- read.csv("data/processed/train_data.csv", stringsAsFactors = FALSE)
test_data <- read.csv("data/processed/test_data.csv", stringsAsFactors = FALSE)
feature_metadata <- readRDS("data/processed/feature_metadata.rds")

train_data$Congestion_Risk <- suppressWarnings(as.factor(train_data$Congestion_Risk))
test_data$Congestion_Risk <- suppressWarnings(as.factor(test_data$Congestion_Risk))

cat("Training model...\n")

set.seed(123)

rf_model <- randomForest(
  as.formula(paste("Congestion_Risk ~", paste(feature_metadata$all_features, collapse = " + "))),
  data = train_data,
  ntree = 100,
  mtry = sqrt(length(feature_metadata$all_features)),
  importance = TRUE
)

saveRDS(rf_model, "models/random_forest_model.rds")

# Make predictions
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
cat("RESULTS:\n")
cat("─────────────────────────────────────────\n")

accuracy <- mean(results$Correct) * 100
cat(paste("Accuracy:", round(accuracy, 2), "%\n"))

alert_summary <- table(results$Alert_Level)
cat("\nAlert Levels:\n")
for(level in names(alert_summary)) {
  cat(paste("  ", level, ":", alert_summary[level], "\n"))
}

cat("\nSample Predictions:\n")
cat("─────────────────────────────────────────\n")
print(head(results[, c("Predicted", "Risk_Score", "Alert_Level")], 10))

# Feature importance
importance_scores <- importance(rf_model)
importance_df <- data.frame(
  Feature = rownames(importance_scores),
  Importance = importance_scores[, "MeanDecreaseGini"]
) %>%
  arrange(desc(Importance)) %>%
  head(10)

write.csv(importance_df, "models/feature_importance.csv", row.names = FALSE)

cat("\n✓ Model training complete\n✓ Predictions saved: models/test_predictions.csv\n\n")
