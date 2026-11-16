# Setting directory
getwd()

# Load necessary libraries
library(data.table)
library(caret)
library(ggplot2)
library(DT)

# Load preprocessed data
processed_data <- fread("Processed_Data.csv")

# Convert label to factor if not already
if (!is.factor(processed_data$label)) {
  processed_data[, label := as.factor(label)]
}

# Ensure label has at least two levels
if (length(unique(processed_data$label)) < 2) {
  stop("Label factor must have at least 2 levels for classification")
}

# Ensure there are predictors
if (ncol(processed_data) <= 1) {
  stop("No predictors found in the data")
}

# Convert categorical variables to numeric, keeping label as factor
cat_cols <- names(processed_data)[sapply(processed_data, is.character)]
if (length(cat_cols) > 0) {
  processed_data[, (cat_cols) := lapply(.SD, as.numeric), .SDcols = cat_cols]
}

# Separate label and predictors
response_vector <- processed_data$label
predictors <- processed_data[, !"label", with = FALSE]

# Ensure all predictors are numeric
if (!all(sapply(predictors, is.numeric))) {
  stop("Non-numeric predictor variables detected")
}

# Convert to matrix
sparse_matrix <- as.matrix(predictors)

# Train-Test Split
set.seed(123)
trainIndex <- createDataPartition(response_vector, p = 0.7, list = FALSE)
trainData <- sparse_matrix[trainIndex, , drop = FALSE]
testData <- sparse_matrix[-trainIndex, , drop = FALSE]
trainLabels <- response_vector[trainIndex]
testLabels <- response_vector[-trainIndex]

# Convert to data.frame for glm
train_df <- data.frame(label = trainLabels, trainData)
test_df <- data.frame(testData)

# Ensure label is a factor for glm
train_df$label <- as.factor(train_df$label)

# Train Logistic Regression Model
model <- glm(label ~ ., data = train_df, family = binomial(), control = list(maxit = 50))

# Make Predictions
predicted_probs <- predict(model, newdata = test_df, type = "response")
predicted_labels <- ifelse(predicted_probs > 0.5, levels(train_df$label)[2], levels(train_df$label)[1])

# Export Predictions
fwrite(data.table(predicted_label = predicted_labels, actual_label = testLabels), "fraud_predictions.csv", sep = ",")

# Print Model Performance
confMatrix <- confusionMatrix(as.factor(predicted_labels), as.factor(testLabels))
print(confMatrix)

# Confusion Matrix Plot
conf_matrix_plot <- as.data.frame(as.table(confMatrix$table))
colnames(conf_matrix_plot) <- c("Prediction", "Reference", "Freq")

print(
  ggplot(conf_matrix_plot, aes(x = Reference, y = Prediction)) +
    geom_tile(aes(fill = Freq), color = "white") +
    geom_text(aes(label = Freq), vjust = 1) +
    scale_fill_gradient(low = "white", high = "steelblue") +
    labs(title = "Confusion Matrix", x = "Actual", y = "Predicted") +
    theme_minimal()
)

# Interactive Table
datatable(data.table(Predicted = predicted_labels, Actual = testLabels),
          options = list(pageLength = 10),
          caption = "Fraud Predictions Table")