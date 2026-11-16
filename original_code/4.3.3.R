# Setting directory
getwd()

# Load necessary libraries
library(data.table)
library(caret)
library(ggplot2)
library(dplyr)

# Load preprocessed data
processed_data <- fread("Processed_Data.csv")

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

# Create a data frame for plotting
plot_data <- data.frame(
  Predicted_Prob = pred_probs,
  Actual_Label = test_data$label
)

# Density plot of predicted probabilities for each class
ggplot(plot_data, aes(x = Predicted_Prob, color = Actual_Label, fill = Actual_Label)) +
  geom_density(alpha = 0.4) +
  labs(
    title = "Density Plot of Predicted Probabilities",
    x = "Predicted Probability",
    y = "Density"
  ) +
  scale_fill_manual(values = c("steelblue", "darkorange")) +
  scale_color_manual(values = c("steelblue", "darkorange")) +
  theme_minimal()