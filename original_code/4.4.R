# Set working directory (optional, adjust to your path if needed)
getwd()

# Load necessary libraries
library(data.table)
library(caret)
library(ggplot2)
library(dplyr)
library(pROC)

# Load preprocessed data
processed_data <- fread("Balanced_Processed.csv")

# Convert label to factor
processed_data$label <- as.factor(processed_data$label)

# Convert categorical variables to numeric
processed_data <- processed_data %>%
  mutate_if(is.character, ~ as.numeric(as.factor(.)))

# Train-Test Split
set.seed(123)
trainIndex <- createDataPartition(processed_data$label, p = 0.7, list = FALSE)
train_data <- processed_data[trainIndex, ]
test_data <- processed_data[-trainIndex, ]

# Train Logistic Regression Model
model <- glm(label ~ ., data = train_data, family = binomial())

# Make Predictions
pred_probs <- predict(model, newdata = test_data, type = "response")
pred_labels <- ifelse(pred_probs > 0.5, levels(train_data$label)[2], levels(train_data$label)[1])

# Export Predictions
fwrite(data.table(Predicted = pred_labels, Actual = test_data$label), "fraud_predictions.csv")

# --- ROC Curve with Smaller Axis Font ---
roc_obj <- roc(response = test_data$label, predictor = pred_probs)

# Adjust margins and label spacing
par(mar = c(5.5, 5.5, 4, 2) + 0.1)
par(mgp = c(3.5, 1, 0))

plot(roc_obj,
     col = "#2c7bb6",
     lwd = 3,
     main = "ROC Curve - Fraud Detection",
     xlab = "False Positive Rate",
     ylab = "True Positive Rate",
     legacy.axes = TRUE,
     print.auc = TRUE,
     print.auc.col = "#2c7bb6",
     print.auc.cex = 1.3,
     cex.axis = 0.9,   # smaller axis tick font
     cex.lab = 1.2,    # slightly smaller axis title font
     cex.main = 1.4)   # title size

# Add diagonal line for reference
abline(a = 0, b = 1, lty = 2, col = "gray")

# Accuracy Rate
cat("Accuracy Rate:", round(accuracy, 4), "\n")

# AUC Confidence Interval
auc_ci <- ci.auc(roc_obj)
cat("AUC:", round(auc(roc_obj), 4), 
    "\n95% Confidence Interval:", round(auc_ci[1], 4), "-", round(auc_ci[3], 4), "\n")