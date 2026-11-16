getwd()

# Load required libraries
library(randomForest)
library(caret)
library(ggplot2)

# Load and preprocess data
processed_data <- read.csv("Balanced_Processed.csv", header = TRUE, sep = ",")
processed_data$id <- NULL
processed_data$label <- as.factor(processed_data$label)
processed_data <- processed_data %>% mutate_if(is.character, ~ as.numeric(as.factor(.)))

# Split data
set.seed(123)
trainIndex <- createDataPartition(processed_data$label, p = 0.7, list = FALSE)
train_data <- processed_data[trainIndex, ]
test_data <- processed_data[-trainIndex, ]

# Train model
model <- randomForest(label ~ ., data = train_data)

# Make predictions
preds <- predict(model, newdata = test_data, type = "response")

# Calculate accuracy metrics
confMatrix <- confusionMatrix(as.factor(preds), as.factor(test_data$label))
accuracy <- confMatrix$overall['Accuracy']
lower_ci <- confMatrix$overall['AccuracyLower']
upper_ci <- confMatrix$overall['AccuracyUpper']

# Create variable importance plot with accuracy annotation
importance_data <- as.data.frame(model$importance)
importance_data$Variable <- rownames(importance_data)

ggplot(importance_data, aes(x = reorder(Variable, MeanDecreaseGini), 
                            y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "#377EB8") +
  coord_flip() +
  labs(title = "Variable Importance",
       subtitle = sprintf("Model Accuracy: %.2f%% (95%% CI: %.2f%% - %.2f%%)", 
                          accuracy*100, lower_ci*100, upper_ci*100),
       x = "Features", 
       y = "Mean Decrease in Gini") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        plot.subtitle = element_text(hjust = 0.5, size = 12),
        axis.text = element_text(size = 12))

# Print accuracy metrics to console
cat(sprintf("\nModel Accuracy: %.2f%%\n", accuracy*100))
cat(sprintf("95%% Confidence Interval: [%.2f%%, %.2f%%]\n", lower_ci*100, upper_ci*100))

