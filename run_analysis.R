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

# Pipeline - Complete ordered sequence
pipeline_steps <- list(
  list(name = "Data Preprocessing", script = "scripts/01_data_preprocessing.R", number = "01"),
  list(name = "Exploratory Data Analysis", script = "scripts/02_exploratory_analysis_improved.R", number = "02"),
  list(name = "Feature Engineering", script = "scripts/03_feature_engineering.R", number = "03"),
  list(name = "Model Training", script = "scripts/04_model_training_clean.R", number = "04"),
  list(name = "Prediction & Evaluation", script = "scripts/05_prediction_system.R", number = "05")
)

# Execute with detailed output
for (i in seq_along(pipeline_steps)) {
  step <- pipeline_steps[[i]]
  
  cat("\n")
  cat("════════════════════════════════════════\n")
  cat(paste("STEP", step$number, ":", toupper(step$name), "\n"))
  cat("════════════════════════════════════════\n")
  
  tryCatch({
    source(step$script, echo = FALSE)
    cat(paste("\n✓ Step", step$number, "completed successfully\n"))
  }, error = function(e) {
    cat(paste("\n✗ Error in Step", step$number, "-", step$name, ":", e$message, "\n"))
    cat("Continuing to next step...\n")
  })
}

# Summary
duration <- difftime(Sys.time(), start_time, units = "secs")

cat("\n╔══════════════════════════════════════════╗\n")
cat("║         ANALYSIS COMPLETE                ║\n")
cat("╚══════════════════════════════════════════╝\n\n")

cat(paste("Duration:", round(duration, 1), "seconds\n"))
cat("Results: models/test_predictions.csv\n\n")
