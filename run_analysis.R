# ============================================================================
# 5G Network Congestion Prediction - Complete Analysis
# ============================================================================

cat("\n╔══════════════════════════════════════════╗\n")
cat("║  5G CONGESTION PREDICTION SYSTEM     ║\n")
cat("╚══════════════════════════════════════════╝\n")

start_time <- Sys.time()

# Setup
options(repos = c(CRAN = "https://cloud.r-project.org"))
suppressMessages(suppressWarnings({
  required_packages <- c("dplyr", "caret", "randomForest", "lubridate")
  new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
  if(length(new_packages) > 0) {
    install.packages(new_packages, dependencies = TRUE, quiet = TRUE)
  }
}))

# Pipeline
pipeline_steps <- list(
  list(name = "Data Preprocessing", script = "scripts/01_data_preprocessing.R"),
  list(name = "Feature Engineering", script = "scripts/03_feature_engineering.R"),
  list(name = "Model Training & Prediction", script = "scripts/04_model_training_clean.R")
)

# Execute
for (i in seq_along(pipeline_steps)) {
  step <- pipeline_steps[[i]]
  
  suppressWarnings({
    tryCatch({
      source(step$script, echo = FALSE)
    }, error = function(e) {
      cat(paste("✗ Error in", step$name, ":", e$message, "\n"))
    })
  })
}

# Summary
duration <- difftime(Sys.time(), start_time, units = "secs")

cat("\n╔══════════════════════════════════════════╗\n")
cat("║         ANALYSIS COMPLETE                ║\n")
cat("╚══════════════════════════════════════════╝\n\n")

cat(paste("Duration:", round(duration, 1), "seconds\n"))
cat("Results: models/test_predictions.csv\n\n")
