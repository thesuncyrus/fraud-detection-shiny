# Join and prepare raw transaction, customer and card tables.
# Requires the raw source tables listed below.
# setting directory
source("config.R")
args <- commandArgs(trailingOnly=TRUE)
if (!length(args)) stop("Supply the authorized raw-table folder.")
setwd(normalizePath(args[1],mustWork=TRUE))

# reading in CSVs
cd = read.csv("cards_data.csv", header = T, sep = ",")
td = read.csv("transactions_data.csv", header = T, sep = ",") # will take a while
ud = read.csv("users_data.csv", header = T, sep = ",")

library(jsonlite)
# reading in JSON files
mcc = fromJSON("mcc_codes.json")
labels = fromJSON("train_fraud_labels.json") # will take a while

# checking length of transaction data and labels

# coverting json data to df
labels_df <- data.frame(id = names(labels), label = unlist(labels))
labels_df$id = rownames(labels_df)
rownames(labels_df) = NULL

labels_df$id = sapply(strsplit(labels_df$id, "\\."), function(x) {
  if (length(x) > 1) {
    return(x[2])
  } else {
    return(NA)
  }
})



library(sqldf)
td_label = sqldf(
  "SELECT td.*, labels_df.label
  FROM td
  INNER JOIN labels_df ON td.id = labels_df.id"
)

yes = td_label[td_label$label == "Yes", ]
no = td_label[td_label$label == "No", ]
set.seed(fraud_config$preparation$seed)
sample_yes = yes[sample(nrow(yes), fraud_config$preparation$observations_per_class), ]
sample_no = no[sample(nrow(no), fraud_config$preparation$observations_per_class), ]

temp = rbind(sample_yes, sample_no)

balanced_processed = sqldf("
                          SELECT ud.*, temp.*, cd.*
                          FROM ud
                          INNER JOIN temp ON ud.id = temp.client_id
                          INNER JOIN cd ON temp.card_id = cd.id"
) 


balanced_processed = balanced_processed[, c(27, 15, 2, 6, 11:14, 19, 20, 26, 37)]

balanced_processed$yearly_income <- gsub("\\$", "", balanced_processed$yearly_income)
balanced_processed$yearly_income <- as.numeric(balanced_processed$yearly_income)
balanced_processed$total_debt <- gsub("\\$", "", balanced_processed$total_debt)
balanced_processed$total_debt <- as.numeric(balanced_processed$total_debt)
balanced_processed$amount <- gsub("\\$", "", balanced_processed$amount)
balanced_processed$amount <- as.numeric(balanced_processed$amount)
balanced_processed$credit_limit <- gsub("\\$", "", balanced_processed$credit_limit)
balanced_processed$credit_limit <- as.numeric(balanced_processed$credit_limit)


balanced_processed$errors = ifelse(balanced_processed$errors == "", "No", "Yes")


balanced_processed$label = as.factor(balanced_processed$label)
balanced_processed$gender = as.factor(balanced_processed$gender)
balanced_processed$num_credit_cards = as.factor(balanced_processed$num_credit_cards)
balanced_processed$use_chip = as.factor(balanced_processed$use_chip)
balanced_processed$errors = as.factor(balanced_processed$errors)

write.table(balanced_processed, file = "Balanced_Processed.csv", sep = ',', row.names = F)
