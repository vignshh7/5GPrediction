# ============================================================================
# Script 01: Data Preprocessing for 5G Network Congestion Prediction
# ============================================================================
# Purpose: Load, clean, and prepare the 5G QoS dataset
# Author: PDS Course Project
# Date: October 2025
# ============================================================================

cat("\n========================================\n")
cat("DATA PREPROCESSING\n")
cat("========================================\n\n")

# Load required libraries
suppressMessages({
  library(dplyr)
  library(tidyr)
  library(lubridate)
})

# Create data directories if they don't exist
if (!dir.exists("data")) dir.create("data")
if (!dir.exists("data/raw")) dir.create("data/raw")
if (!dir.exists("data/processed")) dir.create("data/processed")

# ============================================================================
# STEP 1: Load Data
# ============================================================================

cat("Loading dataset...\n")

# Load the dataset from parent directory
dataset_path <- "../DATASET/Quality of Service 5G.csv"

if (!file.exists(dataset_path)) {
  # Try alternate path
  dataset_path <- "../5g_qos_dataset.csv"
}

if (!file.exists(dataset_path)) {
  # Use the raw backup inside the repo
  dataset_path <- "data/raw/original_data.csv"
}

if (!file.exists(dataset_path)) {
  stop("Dataset not found! Please ensure the dataset is in the parent directory.")
}

df <- read.csv(dataset_path, stringsAsFactors = FALSE)

cat(paste("✓ Loaded:", nrow(df), "records\n"))

# ============================================================================
# STEP 2: Data Cleaning
# ============================================================================

cat("Cleaning data...\n")

# Remove duplicate rows
df <- df %>% distinct()

# Clean column names
names(df) <- gsub("[[:space:]]+", "_", names(df))
names(df) <- gsub("[^A-Za-z0-9_]", "", names(df))

# Convert numeric columns (remove units)
numeric_cols <- c("Signal_Strength", "Latency", "Required_Bandwidth", 
                 "Allocated_Bandwidth", "Resource_Allocation")

for (col in numeric_cols) {
  if (col %in% names(df)) {
    df[[col]] <- as.numeric(gsub("[^-0-9.]", "", df[[col]]))
  }
}

# Handle missing values
missing_summary <- sapply(df, function(x) sum(is.na(x)))
if (sum(missing_summary) > 0) {
  for (col in names(df)) {
    if (sum(is.na(df[[col]])) > 0) {
      if (is.numeric(df[[col]])) {
        df[[col]][is.na(df[[col]])] <- median(df[[col]], na.rm = TRUE)
      } else {
        mode_table <- sort(table(df[[col]]), decreasing = TRUE)
        if (length(mode_table) > 0) {
          df[[col]][is.na(df[[col]])] <- names(mode_table)[1]
        }
      }
    }
  }
}

# Data validation
if ("Signal_Strength" %in% names(df)) {
  df$Signal_Strength <- pmax(-100, pmin(-50, df$Signal_Strength))
}
if ("Latency" %in% names(df)) {
  df$Latency <- pmax(0, df$Latency)
}

# Validate resource allocation (0-100%)
if ("Resource_Allocation" %in% names(df)) {
  invalid_resource <- sum(df$Resource_Allocation < 0 | df$Resource_Allocation > 100, na.rm = TRUE)
  if (invalid_resource > 0) {
    cat(paste("⚠ Warning:", invalid_resource, "rows with invalid resource allocation\n"))
    df$Resource_Allocation <- pmax(0, pmin(100, df$Resource_Allocation))
  }
}

cat("✓ Data cleaned\n")

# Process timestamps
if ("Timestamp" %in% names(df)) {
  df$Timestamp <- as.POSIXct(df$Timestamp, format = "%m/%d/%Y %H:%M", tz = "UTC")
  df$Hour <- hour(df$Timestamp)
  df$DayOfWeek <- wday(df$Timestamp, label = TRUE)
  df$IsWeekend <- ifelse(wday(df$Timestamp) %in% c(1, 7), 1, 0)
}

# Save data dictionary
data_dictionary <- data.frame(
  Column_Name = names(df),
  Data_Type = sapply(df, function(x) class(x)[1]),
  Non_Missing = sapply(df, function(x) sum(!is.na(x))),
  Missing = sapply(df, function(x) sum(is.na(x))),
  Unique_Values = sapply(df, function(x) length(unique(x))),
  stringsAsFactors = FALSE
)

write.csv(data_dictionary, "data/processed/data_dictionary.csv", row.names = FALSE)

# Generate summary statistics
numeric_data <- df[sapply(df, is.numeric)]
safe_min <- function(x) if (all(is.na(x))) NA_real_ else min(x, na.rm = TRUE)
safe_max <- function(x) if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
safe_mean <- function(x) if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
safe_median <- function(x) if (all(is.na(x))) NA_real_ else median(x, na.rm = TRUE)
safe_sd <- function(x) if (all(is.na(x))) NA_real_ else sd(x, na.rm = TRUE)

summary_stats <- data.frame(
  Variable = names(numeric_data),
  Min = sapply(numeric_data, safe_min),
  Median = sapply(numeric_data, safe_median),
  Mean = sapply(numeric_data, safe_mean),
  Max = sapply(numeric_data, safe_max),
  SD = sapply(numeric_data, safe_sd),
  row.names = NULL
)

write.csv(summary_stats, "data/processed/summary_statistics.csv", row.names = FALSE)

# Export cleaned data
write.csv(df, "data/processed/cleaned_data.csv", row.names = FALSE)
write.csv(df, "data/raw/original_data.csv", row.names = FALSE)

cat(paste("✓ Data preprocessed:", nrow(df), "records ready\n\n"))

invisible(df)
