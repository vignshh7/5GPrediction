# ============================================================================
# Model Training - 5G Network Congestion Prediction
# ============================================================================

cat("\n========================================\n")
cat("MODEL TRAINING\n")
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

cat("Training Random Forest model...\n")

set.seed(123)

rf_model <- randomForest(
  as.formula(paste("Congestion_Risk ~", paste(feature_metadata$all_features, collapse = " + "))),
  data = train_data,
  ntree = 100,
  mtry = sqrt(length(feature_metadata$all_features)),
  importance = TRUE
)

saveRDS(rf_model, "models/random_forest_model.rds")

# Feature importance
importance_scores <- importance(rf_model)
importance_df <- data.frame(
  Feature = rownames(importance_scores),
  Importance = importance_scores[, "MeanDecreaseGini"]
) %>%
  arrange(desc(Importance)) %>%
  head(10)

write.csv(importance_df, "models/feature_importance.csv", row.names = FALSE)

cat("✓ Model trained successfully\n")
cat("✓ Model saved: models/random_forest_model.rds\n")
cat("✓ Feature importance saved: models/feature_importance.csv\n\n")
