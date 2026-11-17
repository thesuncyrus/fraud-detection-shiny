# Analysis datasets

- **Balanced_Processed.csv**: 25,000 transactions, evenly divided between No and Yes fraud labels. The model uses the ten customer/transaction predictors after excluding ID.
- **customers.csv**: 307 customer summaries used by the Shiny clustering interface.

The files are the team’s supplied analysis inputs, with values and row order unchanged. Monetary values are numeric; categorical predictors use the encoding defined in src/fraud_model.R.

Dataset reference: [Financial Transactions Dataset: Analytics](https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets), shared by ComputingVictor and credited to Caixabank Tech’s 2024 AI Hackathon. The dataset card lists Apache 2.0. See LICENSE.txt and NOTICE.md.

The large joined raw table and raw card/account fields are not required by the app and are not included. Full raw preparation requires the separately obtained users, cards, transactions, MCC and label source files.
