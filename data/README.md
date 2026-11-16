# Private data requirements
Use an authorized local copy of Balanced_Processed.csv: 25,000 rows, 12,500 No and 12,500 Yes.
After dropping id, exact column order is label, current_age, gender, yearly_income, total_debt,
credit_score, num_credit_cards, amount, use_chip, errors, credit_limit. Categorical columns are
gender, use_chip, errors; their alphabetical factor codes are converted to numbers before splitting,
as in the original source. No missing fields occur in the supplied balanced file.

Optional customers.csv contains 307 customer-level numerical summaries for clustering. Never publish
either file. Processed_Data.csv contains sensitive personal/card-like information and is excluded.
The original raw-table builder needs cards_data.csv, transactions_data.csv, users_data.csv,
mcc_codes.json and train_fraud_labels.json. Its exact historical column ordering matters.
Source redistribution rights are not established; this repository grants no data license.
