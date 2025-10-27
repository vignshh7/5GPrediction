# ============================================================================
# Script 02: IMPROVED Exploratory Data Analysis for 5G Network Congestion
# ============================================================================
# Purpose: Analyze and visualize the 5G QoS dataset with enhanced graphics
# Author: PDS Course Project
# Date: October 2025
# ============================================================================

cat("\n========================================\n")
cat("SCRIPT 02: EXPLORATORY DATA ANALYSIS (IMPROVED)\n")
cat("========================================\n\n")

# Load required libraries
suppressMessages({
  library(dplyr)
  library(ggplot2)
  library(corrplot)
  library(gridExtra)
  library(scales)
  library(reshape2)
  library(RColorBrewer)
})

# Set a modern theme for all plots
theme_custom <- function() {
  theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
      plot.subtitle = element_text(hjust = 0.5, size = 12, color = "gray40"),
      axis.title = element_text(size = 12, face = "bold"),
      axis.text = element_text(size = 10),
      legend.position = "right",
      legend.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "gray80", fill = NA, linewidth = 0.5)
    )
}

# Create visualization directory
if (!dir.exists("visualizations")) dir.create("visualizations")
if (!dir.exists("visualizations/eda")) dir.create("visualizations/eda")

# ============================================================================
# STEP 1: Load Cleaned Data
# ============================================================================

cat("STEP 1: Loading cleaned data...\n")

if (!file.exists("data/processed/cleaned_data.csv")) {
  stop("Cleaned data not found! Please run 01_data_preprocessing.R first.")
}

df <- read.csv("data/processed/cleaned_data.csv", stringsAsFactors = FALSE)
cat(paste("✓ Loaded", nrow(df), "records\n\n"))

# ============================================================================
# STEP 2: Univariate Analysis - IMPROVED
# ============================================================================

cat("STEP 2: Creating enhanced univariate analysis plots...\n")

# 1. Signal Strength Distribution - Enhanced
p1 <- ggplot(df, aes(x = Signal_Strength)) +
  geom_histogram(bins = 35, fill = "#3498db", color = "#2c3e50", alpha = 0.8, linewidth = 0.3) +
  geom_vline(aes(xintercept = mean(Signal_Strength)), 
             color = "#e74c3c", linetype = "dashed", linewidth = 1.2) +
  geom_vline(aes(xintercept = median(Signal_Strength)), 
             color = "#27ae60", linetype = "dotted", linewidth = 1.2) +
  annotate("text", x = mean(df$Signal_Strength) - 5, y = Inf, 
           label = paste("Mean:", round(mean(df$Signal_Strength), 1), "dBm"),
           vjust = 2, hjust = 1, color = "#e74c3c", fontface = "bold", size = 4) +
  labs(title = "Signal Strength Distribution",
       subtitle = sprintf("Range: %.1f to %.1f dBm | Median: %.1f dBm", 
                         min(df$Signal_Strength), max(df$Signal_Strength), 
                         median(df$Signal_Strength)),
       x = "Signal Strength (dBm)", 
       y = "Frequency (Number of Connections)") +
  theme_custom()

ggsave("visualizations/eda/01_signal_strength_distribution.png", p1, 
       width = 12, height = 7, dpi = 300, bg = "white")

# 2. Latency Distribution - Enhanced
p2 <- ggplot(df, aes(x = Latency)) +
  geom_histogram(bins = 35, fill = "#2ecc71", color = "#27ae60", alpha = 0.8, linewidth = 0.3) +
  geom_vline(aes(xintercept = mean(Latency)), 
             color = "#e74c3c", linetype = "dashed", linewidth = 1.2) +
  geom_vline(aes(xintercept = quantile(Latency, 0.75)), 
             color = "#f39c12", linetype = "dashed", linewidth = 1.2) +
  annotate("text", x = mean(df$Latency), y = Inf, 
           label = paste("Mean:", round(mean(df$Latency), 1), "ms"),
           vjust = 2, hjust = -0.1, color = "#e74c3c", fontface = "bold", size = 4) +
  annotate("text", x = quantile(df$Latency, 0.75), y = Inf, 
           label = paste("75th %ile:", round(quantile(df$Latency, 0.75), 1), "ms"),
           vjust = 4, hjust = -0.1, color = "#f39c12", fontface = "bold", size = 4) +
  labs(title = "Latency Distribution",
       subtitle = sprintf("Range: %.1f to %.1f ms | 75th Percentile: %.1f ms (Congestion Threshold)", 
                         min(df$Latency), max(df$Latency), quantile(df$Latency, 0.75)),
       x = "Latency (milliseconds)", 
       y = "Frequency (Number of Connections)") +
  theme_custom()

ggsave("visualizations/eda/02_latency_distribution.png", p2, 
       width = 12, height = 7, dpi = 300, bg = "white")

# 3. Resource Allocation Distribution - Enhanced
p3 <- ggplot(df, aes(x = Resource_Allocation)) +
  geom_histogram(bins = 20, fill = "#e67e22", color = "#d35400", alpha = 0.8, linewidth = 0.3) +
  geom_vline(aes(xintercept = mean(Resource_Allocation)), 
             color = "#2c3e50", linetype = "dashed", linewidth = 1.2) +
  geom_vline(aes(xintercept = 80), 
             color = "#c0392b", linetype = "dashed", linewidth = 1.2) +
  annotate("text", x = mean(df$Resource_Allocation), y = Inf, 
           label = paste("Mean:", round(mean(df$Resource_Allocation), 1), "%"),
           vjust = 2, hjust = -0.1, color = "#2c3e50", fontface = "bold", size = 4) +
  annotate("text", x = 80, y = Inf, 
           label = "Congestion\nThreshold: 80%",
           vjust = 4, hjust = -0.1, color = "#c0392b", fontface = "bold", size = 4) +
  labs(title = "Resource Allocation Distribution",
       subtitle = sprintf("Range: %.0f%% to %.0f%% | Mean: %.1f%%", 
                         min(df$Resource_Allocation), max(df$Resource_Allocation), 
                         mean(df$Resource_Allocation)),
       x = "Resource Allocation (%)", 
       y = "Frequency (Number of Connections)") +
  scale_x_continuous(breaks = seq(50, 90, by = 10)) +
  theme_custom()

ggsave("visualizations/eda/03_resource_allocation_distribution.png", p3, 
       width = 12, height = 7, dpi = 300, bg = "white")

cat("✓ Univariate analysis plots saved\n\n")

# ============================================================================
# STEP 3: Application Type Analysis - IMPROVED
# ============================================================================

cat("STEP 3: Creating enhanced application type analysis...\n")

# Prepare data
app_summary <- df %>%
  group_by(Application_Type) %>%
  summarise(
    Count = n(),
    Avg_Signal = mean(Signal_Strength, na.rm = TRUE),
    Avg_Latency = mean(Latency, na.rm = TRUE),
    Avg_Resource = mean(Resource_Allocation, na.rm = TRUE)
  ) %>%
  arrange(desc(Count))

# 4. Application Type Distribution - Enhanced with better labels
colors_app <- colorRampPalette(brewer.pal(9, "Set3"))(nrow(app_summary))

p4 <- ggplot(app_summary, aes(x = reorder(Application_Type, Count), y = Count, fill = Application_Type)) +
  geom_bar(stat = "identity", color = "white", linewidth = 0.5, alpha = 0.9) +
  geom_text(aes(label = Count), hjust = -0.3, fontface = "bold", size = 4) +
  scale_fill_manual(values = colors_app) +
  coord_flip() +
  labs(title = "Distribution of Application Types",
       subtitle = sprintf("Total Connections: %d | Application Types: %d", 
                         sum(app_summary$Count), nrow(app_summary)),
       x = "Application Type", 
       y = "Number of Connections") +
  theme_custom() +
  theme(legend.position = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)))

ggsave("visualizations/eda/04_application_type_distribution.png", p4, 
       width = 12, height = 8, dpi = 300, bg = "white")

# 5. Latency by Application - Boxplot with better spacing
p5 <- ggplot(df, aes(x = reorder(Application_Type, Latency, FUN = median), y = Latency, fill = Application_Type)) +
  geom_boxplot(alpha = 0.8, outlier.color = "#e74c3c", outlier.size = 2) +
  scale_fill_manual(values = colors_app) +
  geom_hline(yintercept = quantile(df$Latency, 0.75), 
             linetype = "dashed", color = "#c0392b", linewidth = 1) +
  annotate("text", x = 1, y = quantile(df$Latency, 0.75), 
           label = "Congestion Threshold", 
           vjust = -0.5, hjust = 0, color = "#c0392b", fontface = "bold", size = 4) +
  coord_flip() +
  labs(title = "Latency Distribution by Application Type",
       subtitle = "Boxplot showing median, quartiles, and outliers",
       x = "Application Type", 
       y = "Latency (ms)") +
  theme_custom() +
  theme(legend.position = "none")

ggsave("visualizations/eda/05_latency_by_application.png", p5, 
       width = 12, height = 8, dpi = 300, bg = "white")

# 6. Resource Allocation by Application
p6 <- ggplot(df, aes(x = reorder(Application_Type, Resource_Allocation, FUN = median), 
                     y = Resource_Allocation, fill = Application_Type)) +
  geom_boxplot(alpha = 0.8, outlier.color = "#e74c3c", outlier.size = 2) +
  scale_fill_manual(values = colors_app) +
  geom_hline(yintercept = 80, linetype = "dashed", color = "#c0392b", linewidth = 1) +
  annotate("text", x = 1, y = 80, 
           label = "High Utilization (80%)", 
           vjust = -0.5, hjust = 0, color = "#c0392b", fontface = "bold", size = 4) +
  coord_flip() +
  labs(title = "Resource Allocation by Application Type",
       subtitle = "Boxplot showing resource utilization patterns",
       x = "Application Type", 
       y = "Resource Allocation (%)") +
  theme_custom() +
  theme(legend.position = "none")

ggsave("visualizations/eda/06_resource_allocation_by_application.png", p6, 
       width = 12, height = 8, dpi = 300, bg = "white")

cat("✓ Application type analysis plots saved\n\n")

# ============================================================================
# STEP 4: Bivariate Analysis - IMPROVED
# ============================================================================

cat("STEP 4: Creating enhanced bivariate analysis plots...\n")

# 7. Signal vs Latency Scatter Plot - Enhanced
p7 <- ggplot(df, aes(x = Signal_Strength, y = Latency)) +
  geom_point(alpha = 0.5, size = 2.5, color = "#3498db") +
  geom_smooth(method = "lm", color = "#e74c3c", linewidth = 1.5, se = TRUE, alpha = 0.2, formula = y ~ x) +
  geom_smooth(method = "loess", color = "#27ae60", linewidth = 1.5, se = FALSE, linetype = "dashed", formula = y ~ x) +
  labs(title = "Relationship: Signal Strength vs Latency",
       subtitle = sprintf("Correlation: %.3f | Weaker signal tends to increase latency", 
                         cor(df$Signal_Strength, df$Latency)),
       x = "Signal Strength (dBm)", 
       y = "Latency (ms)") +
  theme_custom()

ggsave("visualizations/eda/07_signal_vs_latency.png", p7, 
       width = 12, height = 7, dpi = 300, bg = "white")

# 8. Required vs Allocated Bandwidth - Enhanced
p8 <- ggplot(df, aes(x = Required_Bandwidth, y = Allocated_Bandwidth)) +
  geom_point(alpha = 0.5, size = 2.5, color = "#9b59b6") +
  geom_abline(intercept = 0, slope = 1, color = "#e74c3c", linetype = "dashed", linewidth = 1.2) +
  geom_smooth(method = "lm", color = "#27ae60", linewidth = 1.5, se = TRUE, alpha = 0.2, formula = y ~ x) +
  annotate("text", x = max(df$Required_Bandwidth) * 0.7, y = max(df$Required_Bandwidth) * 0.7, 
           label = "Perfect\nAllocation", color = "#e74c3c", fontface = "bold", size = 4) +
  labs(title = "Required vs Allocated Bandwidth",
       subtitle = sprintf("Correlation: %.4f | Network allocates appropriately", 
                         cor(df$Required_Bandwidth, df$Allocated_Bandwidth)),
       x = "Required Bandwidth (Mbps)", 
       y = "Allocated Bandwidth (Mbps)") +
  theme_custom()

ggsave("visualizations/eda/08_required_vs_allocated_bandwidth.png", p8, 
       width = 12, height = 7, dpi = 300, bg = "white")

# 9. Signal vs Resource - Color by Latency
p9 <- ggplot(df, aes(x = Signal_Strength, y = Resource_Allocation, color = Latency)) +
  geom_point(alpha = 0.7, size = 3) +
  scale_color_gradient2(low = "#27ae60", mid = "#f39c12", high = "#e74c3c",
                        midpoint = median(df$Latency), name = "Latency\n(ms)") +
  geom_smooth(method = "lm", color = "#2c3e50", linewidth = 1.5, se = TRUE, alpha = 0.1, formula = y ~ x) +
  labs(title = "Signal Strength vs Resource Allocation",
       subtitle = "Color indicates latency level (Green=Low, Yellow=Medium, Red=High)",
       x = "Signal Strength (dBm)", 
       y = "Resource Allocation (%)") +
  theme_custom()

ggsave("visualizations/eda/09_signal_vs_resource_allocation.png", p9, 
       width = 12, height = 7, dpi = 300, bg = "white")

cat("✓ Bivariate analysis plots saved\n\n")

# ============================================================================
# STEP 5: Correlation Analysis - IMPROVED
# ============================================================================

cat("STEP 5: Creating enhanced correlation analysis...\n")

# Select numeric columns for correlation
numeric_cols <- df %>% 
  select(Signal_Strength, Latency, Required_Bandwidth, 
         Allocated_Bandwidth, Resource_Allocation)

cor_matrix <- cor(numeric_cols, use = "complete.obs")

# 10. Correlation Matrix - Enhanced with better colors
png("visualizations/eda/10_correlation_matrix.png", width = 12, height = 10, units = "in", res = 300)
par(mar = c(2, 2, 4, 2))
corrplot(cor_matrix, 
         method = "circle", 
         type = "upper",
         order = "hclust",
         col = colorRampPalette(c("#c0392b", "white", "#27ae60"))(200),
         tl.col = "black", 
         tl.srt = 45,
         tl.cex = 1.2,
         addCoef.col = "black",
         number.cex = 1.1,
         cl.cex = 1.1,
         title = "Correlation Matrix - Network QoS Metrics",
         mar = c(0, 0, 2, 0))
dev.off()

# 11. Correlation Heatmap with values
png("visualizations/eda/11_correlation_heatmap.png", width = 12, height = 10, units = "in", res = 300)

# Melt correlation matrix
cor_melted <- melt(cor_matrix)

p11 <- ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = sprintf("%.3f", value)), size = 5, fontface = "bold") +
  scale_fill_gradient2(low = "#c0392b", mid = "white", high = "#27ae60",
                       midpoint = 0, limit = c(-1, 1), 
                       name = "Correlation\nCoefficient") +
  labs(title = "Correlation Heatmap - 5G QoS Metrics",
       subtitle = "Values close to +1 indicate strong positive correlation, -1 indicates strong negative correlation",
       x = "", y = "") +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 18),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 12, face = "bold"),
    axis.text.y = element_text(size = 12, face = "bold"),
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 10),
    panel.grid = element_blank()
  ) +
  coord_fixed()

print(p11)
dev.off()

cat("✓ Correlation analysis plots saved\n\n")

# Print key correlations
cat("Key Correlations:\n")
cor_melted_sorted <- cor_melted %>%
  filter(Var1 != Var2) %>%
  arrange(desc(abs(value))) %>%
  head(10)
print(cor_melted_sorted)

# ============================================================================
# STEP 6: Time-based Analysis - IMPROVED
# ============================================================================

cat("\nSTEP 6: Creating time-based analysis...\n")

if ("Hour" %in% names(df)) {
  hourly_stats <- df %>%
    group_by(Hour) %>%
    summarise(
      Avg_Latency = mean(Latency, na.rm = TRUE),
      Avg_Resource = mean(Resource_Allocation, na.rm = TRUE),
      Count = n()
    )
  
  # 12. Latency by Hour
  p12 <- ggplot(hourly_stats, aes(x = Hour)) +
    geom_line(aes(y = Avg_Latency), color = "#3498db", linewidth = 2) +
    geom_point(aes(y = Avg_Latency), color = "#2c3e50", size = 4) +
    geom_hline(yintercept = mean(df$Latency), linetype = "dashed", color = "#e74c3c", linewidth = 1) +
    labs(title = "Average Latency by Hour of Day",
         subtitle = "Hourly trend analysis (dashed line = overall mean)",
         x = "Hour of Day", 
         y = "Average Latency (ms)") +
    scale_x_continuous(breaks = unique(hourly_stats$Hour)) +
    theme_custom()
  
  ggsave("visualizations/eda/12_latency_by_hour.png", p12, 
         width = 12, height = 7, dpi = 300, bg = "white")
  
  # 13. Resource by Hour
  p13 <- ggplot(hourly_stats, aes(x = Hour)) +
    geom_line(aes(y = Avg_Resource), color = "#e67e22", linewidth = 2) +
    geom_point(aes(y = Avg_Resource), color = "#d35400", size = 4) +
    geom_hline(yintercept = 80, linetype = "dashed", color = "#c0392b", linewidth = 1) +
    labs(title = "Average Resource Allocation by Hour of Day",
         subtitle = "Hourly utilization pattern (dashed line = congestion threshold)",
         x = "Hour of Day", 
         y = "Average Resource Allocation (%)") +
    scale_x_continuous(breaks = unique(hourly_stats$Hour)) +
    theme_custom()
  
  ggsave("visualizations/eda/13_resource_by_hour.png", p13, 
         width = 12, height = 7, dpi = 300, bg = "white")
  
  cat("✓ Time-based analysis plots saved\n\n")
} else {
  cat("⚠ No time features found, skipping time-based analysis\n\n")
}

# ============================================================================
# STEP 7: Summary Dashboard - IMPROVED
# ============================================================================

cat("STEP 7: Creating enhanced summary dashboard...\n")

# Create 4 summary panels
summary_p1 <- ggplot(df, aes(x = Signal_Strength)) +
  geom_density(fill = "#3498db", alpha = 0.7, color = "#2c3e50") +
  labs(title = "Signal Strength", x = "dBm", y = "Density") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 11))

summary_p2 <- ggplot(df, aes(x = Latency)) +
  geom_density(fill = "#2ecc71", alpha = 0.7, color = "#27ae60") +
  labs(title = "Latency", x = "ms", y = "Density") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 11))

summary_p3 <- ggplot(df, aes(x = Resource_Allocation)) +
  geom_density(fill = "#e67e22", alpha = 0.7, color = "#d35400") +
  labs(title = "Resource Allocation", x = "%", y = "Density") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 11))

summary_p4 <- ggplot(df, aes(x = Signal_Strength, y = Latency)) +
  geom_bin2d(bins = 30) +
  scale_fill_gradient(low = "white", high = "#9b59b6") +
  labs(title = "Signal vs Latency", x = "Signal (dBm)", y = "Latency (ms)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 11),
        legend.position = "none")

# Combine into dashboard
dashboard <- grid.arrange(
  summary_p1, summary_p2, summary_p3, summary_p4,
  ncol = 2,
  top = grid::textGrob("5G Network QoS - Summary Dashboard", 
                       gp = grid::gpar(fontsize = 20, fontface = "bold"))
)

ggsave("visualizations/eda/14_summary_dashboard.png", dashboard, 
       width = 14, height = 10, dpi = 300, bg = "white")

cat("✓ Summary dashboard created\n\n")

# ============================================================================
# STEP 8: Generate Statistical Summary
# ============================================================================

cat("STEP 8: Generating statistical summary...\n")

# Application-wise summary
app_summary_detailed <- df %>%
  group_by(Application_Type) %>%
  summarise(
    Count = n(),
    Avg_Signal = round(mean(Signal_Strength, na.rm = TRUE), 2),
    Avg_Latency = round(mean(Latency, na.rm = TRUE), 2),
    Avg_Required_BW = round(mean(Required_Bandwidth, na.rm = TRUE), 2),
    Avg_Allocated_BW = round(mean(Allocated_Bandwidth, na.rm = TRUE), 2),
    Avg_Resource = round(mean(Resource_Allocation, na.rm = TRUE), 2)
  ) %>%
  arrange(desc(Count))

write.csv(app_summary_detailed, "data/processed/application_summary.csv", row.names = FALSE)

cat("\nApplication-wise Summary:\n")
print(app_summary_detailed, n = Inf)

# ============================================================================
# COMPLETION
# ============================================================================

cat("\n========================================\n")
cat("EXPLORATORY DATA ANALYSIS COMPLETED!\n")
cat("========================================\n\n")

cat("Output Files:\n")
cat("  - 14 visualization plots in visualizations/eda/\n")
cat("  - data/processed/application_summary.csv\n\n")

cat("Key Insights:\n")
cat(paste("  - Average Signal Strength:", round(mean(df$Signal_Strength), 2), "dBm\n"))
cat(paste("  - Average Latency:", round(mean(df$Latency), 2), "ms\n"))
cat(paste("  - Average Resource Allocation:", round(mean(df$Resource_Allocation), 2), "%\n"))
cat(paste("  - Total Application Types:", length(unique(df$Application_Type)), "\n"))

cat("\nYou can now run: source('03_feature_engineering.R')\n\n")
