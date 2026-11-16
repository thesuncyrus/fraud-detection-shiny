# Data setup

The verified route starts from the supplied `Balanced_Processed.csv`: 25,000 labelled transactions, 12,500 per class. Required fields and types are listed in the README and `functions.R`. Local checksum references are in `docs/input-checksums.csv`.

```sh
Rscript setup.R
Rscript run_all.R /path/to/Balanced_Processed.csv outputs /path/to/customers.csv
```

The optional customer file enables segmentation and Shiny integration. To launch the app after training, set `FRAUD_MODEL_PATH` to the fitted `model.rds` and `FRAUD_CUSTOMERS_PATH` to the customer CSV, or use the default paths described in the README.

A separate raw-source route is available:

```sh
Rscript prepare.R /path/to/raw-tables outputs/Balanced_Processed.csv
```

It requires `transactions_data.csv`, `users_data.csv`, `cards_data.csv`, and `train_fraud_labels.json` containing a named `target` mapping. Joins use transaction, user and card keys; foreign keys, ownership, monetary parsing and class counts are validated. This route was tested with synthetic fixtures. The complete original raw tables were not available, so it has not been certified to regenerate the supplied balanced CSV byte-for-byte.

The supplied `Processed_Data.csv` describes a different 500-user sample and contains direct identifiers and card fields. It is not redistributed and is not a substitute for the balanced experiment. No raw data, card numbers, customer-level assignments or fitted models are committed. Dataset redistribution rights must be determined independently.
