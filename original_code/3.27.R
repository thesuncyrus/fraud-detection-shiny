# setting directory
setwd("C:/Users/msurb_vznbu2w/OneDrive/Desktop/MGMT 389/Shiny Project")

# Load necessary libraries
library(jsonlite)
library(data.table)
library(caret)

# Read CSV files using data.table for better performance
cd <- fread("cards_data.csv")
td <- fread("transactions_data.csv")
ud <- fread("users_data.csv")

# Read JSON files
mcc <- fromJSON("mcc_codes.json")
labels <- fromJSON("train_fraud_labels.json")

# Convert JSON labels to data.table
labels_df <- data.table(id = names(labels), label = unlist(labels))
labels_df$id <- sapply(strsplit(labels_df$id, "\\."), function(x) if (length(x) > 1) x[2] else NA)

# Keep only 500 users (250 Male, 250 Female)
set.seed(123)
sample_users <- rbind(
  ud[gender == "Male"][sample(.N, 250)],
  ud[gender == "Female"][sample(.N, 250)]
)

# Filter transactions for selected users before joining (improves speed)
td_filtered <- td[client_id %in% sample_users$id]
labels_filtered <- labels_df[id %in% td_filtered$id]

# Perform joins using data.table
processed_data <- merge(sample_users, td_filtered, by.x = "id", by.y = "client_id")
processed_data <- merge(processed_data, cd, by.x = "card_id", by.y = "id")
processed_data <- merge(processed_data, labels_filtered, by.x = "transaction_id", by.y = "id")

# Rename columns
setnames(processed_data, "id", "customer_id")
setnames(processed_data, "transaction_id", "id")

# Convert label to factor for classification
processed_data$label <- as.factor(processed_data$label)

# Remove non-numeric or ID columns that shouldn't be used for training
drop_cols <- c("customer_id", "id", "card_id")  # Keep only relevant numeric features
processed_data_clean <- processed_data[, !drop_cols, with = FALSE]

# Save processed dataset
fwrite(processed_data, "processed_data.csv", sep = ",")

# Train-Test Split (70% Train, 30% Test)
set.seed(123)
trainIndex <- createDataPartition(processed_data_clean$label, p = 0.7, list = FALSE)
trainData <- processed_data_clean[trainIndex]
testData <- processed_data_clean[-trainIndex]

# Train Logistic Regression Model
model <- train(label ~ ., data = trainData, method = "glm", family = "binomial", 
               trControl = trainControl(method = "cv", number = 5))

# Make Predictions
testData$predicted_label <- predict(model, testData)

# Export Fraud Predictions
fwrite(testData[, .(customer_id, id, label, predicted_label)], "fraud_predictions.csv", sep = ",")

# Print Model Performance
confMatrix <- confusionMatrix(testData$predicted_label, testData$label)
print(confMatrix)