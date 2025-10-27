cat("\n========================================\n")
cat("FEATURE ENGINEERING\n")
cat("========================================\n\n")

suppressMessages({
  library(dplyr)
  library(caret)
})

cat("Loading data...\n")
df <- read.csv("data/processed/cleaned_data.csv", stringsAsFactors = FALSE)

df$Congestion_Risk <- ifelse(df$Latency > 45 | df$Resource_Allocation > 80, 1, 0)
congestion_count <- sum(df$Congestion_Risk == 1)
cat(paste("Creating features...\n"))

df$Bandwidth_Deficit <- df$Allocated_Bandwidth - df$Required_Bandwidth
df$Bandwidth_Efficiency <- (df$Allocated_Bandwidth / pmax(df$Required_Bandwidth, 0.01)) * 100
df$Signal_Category <- cut(df$Signal_Strength, breaks = c(-Inf, -90, -80, -70, Inf), labels = c("Poor", "Fair", "Good", "Excellent"))
df$Latency_Category <- cut(df$Latency, breaks = c(-Inf, 20, 40, 60, Inf), labels = c("Low", "Medium", "High", "VeryHigh"))
df$Resource_Level <- cut(df$Resource_Allocation, breaks = c(0, 60, 75, 85, 100), labels = c("Low", "Medium", "High", "Critical"))
df$Signal_Latency_Interaction <- df$Signal_Strength * df$Latency
df$Resource_Pressure <- (df$Resource_Allocation / 100) * df$Latency
df$QoS_Score <- (abs(df$Signal_Strength) + df$Bandwidth_Efficiency + (100 - df$Latency) + df$Resource_Allocation) / 4

app_dummies <- model.matrix(~ Application_Type - 1, data = df)
df <- cbind(df, app_dummies)

df$Signal_Category_Num <- as.numeric(df$Signal_Category)
df$Latency_Category_Num <- as.numeric(df$Latency_Category)
df$Resource_Level_Num <- as.numeric(df$Resource_Level)

exclude_cols <- c("Timestamp", "User_ID", "Application_Type", "DayOfWeek", "Signal_Category", "Latency_Category", "Resource_Level", "Congestion_Risk")
feature_cols <- setdiff(names(df), exclude_cols)

nzv <- nearZeroVar(df[feature_cols], saveMetrics = FALSE)
if (length(nzv) > 0) {
  feature_cols <- feature_cols[-nzv]
}
all_features <- feature_cols

set.seed(123)
train_idx <- createDataPartition(df$Congestion_Risk, p = 0.8, list = FALSE)
train_data <- df[train_idx, c(all_features, "Congestion_Risk")]
test_data <- df[-train_idx, c(all_features, "Congestion_Risk")]

numeric_features_only <- all_features[sapply(train_data[all_features], is.numeric)]
preproc <- suppressWarnings(preProcess(train_data[numeric_features_only], method = c("center", "scale")))
train_data[numeric_features_only] <- predict(preproc, train_data[numeric_features_only])
test_data[numeric_features_only] <- predict(preproc, test_data[numeric_features_only])

write.csv(df, "data/processed/engineered_features.csv", row.names = FALSE)
write.csv(train_data, "data/processed/train_data.csv", row.names = FALSE)
write.csv(test_data, "data/processed/test_data.csv", row.names = FALSE)
write.csv(train_data, "data/processed/train_data_scaled.csv", row.names = FALSE)
write.csv(test_data, "data/processed/test_data_scaled.csv", row.names = FALSE)

feature_metadata <- list(all_features = all_features, numeric_features = numeric_features_only, preprocessing = preproc)
saveRDS(feature_metadata, "data/processed/feature_metadata.rds")

cat(paste("✓ Features ready:", length(all_features), "features,", nrow(train_data), "train,", nrow(test_data), "test\n\n"))
