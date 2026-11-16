# Setting directory
getwd()

# Load necessary libraries
library(data.table)
library(caret)
library(ggplot2)
library(dplyr)

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

# Print Model Performance
confMatrix <- confusionMatrix(as.factor(pred_labels), as.factor(test_data$label))
print(confMatrix)

# Convert confusion matrix to data frame
conf_matrix_df <- as.data.frame(confMatrix$table)

# Create a bar plot for confusion matrix
ggplot(conf_matrix_df, aes(x = Prediction, y = Freq, fill = Reference)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Classification Results", x = "Predicted Label", y = "Count") +
  scale_fill_manual(values = c("steelblue", "darkorange")) + 
  theme_minimal()

