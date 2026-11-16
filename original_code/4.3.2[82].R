# Setting directory
getwd()

# Load necessary libraries
library(data.table)
library(caret)
library(ggplot2)
library(dplyr)
library(randomForest)

setwd("C:/Users/Owner/Desktop/College/Spring 2025/MGMT 389/Financial Transactions Dataset")
# Load preprocessed data
processed_data <- fread("Balanced_Processed.csv")

processed_data$id = NULL
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
## model <- glm(label ~ ., data = train_data, family = binomial())
model <- randomForest(label ~ ., data = train_data)

# Make Predictions
preds <- predict(model, newdata = test_data, type = "response")

# Export Predictions
fwrite(data.table(Predicted = pred_labels, Actual = test_data$label), "fraud_predictions.csv")

# Print Model Performance
confMatrix <- confusionMatrix(as.factor(preds), as.factor(test_data$label))
print(confMatrix)

# Confusion Matrix Plot
conf_matrix_plot <- as.data.frame(confMatrix$table)
ggplot(conf_matrix_plot, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Freq), vjust = 1) +
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(title = "Confusion Matrix", x = "Actual", y = "Predicted") +
  theme_minimal()


