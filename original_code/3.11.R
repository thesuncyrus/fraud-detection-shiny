# setting directory
setwd("C:/Users/Owner/Desktop/College/Spring 2025/MGMT 389/Financial Transactions Dataset")

# reading in CSVs
cd = read.csv("cards_data.csv", header = T, sep = ",")
td = read.csv("transactions_data.csv", header = T, sep = ",") # will take a while
ud = read.csv("users_data.csv", header = T, sep = ",")

# install.packages("jsonlite")
library(jsonlite)
# reading in JSON files
mcc = fromJSON("mcc_codes.json")
## mcc
labels = fromJSON("train_fraud_labels.json") # will take a while
## labels

# checking length of transaction data and labels
length(labels$target)
nrow(td)

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

head(labels_df)
anyNA(labels_df)
# joining labels on transaction data
library(sqldf)

       #p_td = sqldf("
                       #SELECT td.*, labels_df.label
                      #FROM td
                      #INNER JOIN labels_df ON td.id = labels_df.id")
        # This will take very long, will continue to clean data further


# Keeping 500 users, 250 Males, 250 Females
table(ud$gender)
males = ud[ud$gender == 'Male', ]
females = ud[ud$gender == "Female", ]

set.seed(123)
sample_males = males[sample(nrow(males), 250), ]
sample_females = females[sample(nrow(females), 250), ]
users = rbind(sample_males, sample_females)
table(users$gender)


# Joining all but merchant tables
processed_data = sqldf("
                          SELECT users.*, td.*, cd.*, labels_df.label
                          FROM users
                          INNER JOIN td ON users.id = td.client_id
                          INNER JOIN cd ON td.card_id = cd.id
                          INNER JOIN labels_df ON td.id = labels_df.id"
) 

head(processed_data)
nrow(processed_data) / nrow(td)

names(processed_data)[1] = "customer_id"
names(processed_data)[15] = "transaction_id"

processed_data[17] = NULL
processed_data[26] = NULL
processed_data[26] = NULL

processed_data = processed_data[, c(1, 15, 17, 2:14, 16, 18:ncol(processed_data))]



write.table(processed_data, file = "Processed_Data.csv", sep = ',', row.names = F)

