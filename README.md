# fRaud

**Review guide:** [Data and complete run command](DATA_SETUP.md) · [Result provenance](RESULTS_PROVENANCE.md) · [Source/contribution map](docs/WORKFLOW.md).

The complete executable route is `run_all.R`; `setup.R` installs its R dependencies. Original sources remain available with attribution. New robustness/comparator analyses are identified separately from original project results.


An R random forest workflow and Shiny application for transaction classification and
interactive customer segmentation. Original collaborative project: Purdue University,
Spring 2025, mentored by Matthew A. Lanham. Team: Allison Spahn, Himanshu Niraj Sethia,
Marissa Urbanek, and Chau Nguyen (Cyrus Nguyen in original materials).

## Run

Use R 4.5 or later. From this directory:

```r
install.packages(c('randomForest', 'shiny'))
```

```sh
Rscript tests.R
Rscript train.R '/path/to/Balanced_Processed.csv' outputs
Rscript -e "shiny::runApp('.')"
```

For optional clustering place an authorized customers.csv at data/customers.csv.
FRAUD_MODEL_PATH and FRAUD_CUSTOMERS_PATH can override the defaults. The model is
trained once by train.R and loaded by the application. It is not retrained per visitor.
The live portfolio is static: it shows source and results, not a hosted Shiny server.

## Input contract

Balanced_Processed.csv contains label (No/Yes), an optional unique transaction id,
and ten predictors. Numeric: current_age, yearly_income, total_debt, credit_score,
num_credit_cards, amount, credit_limit. Categorical: gender, use_chip, errors.
IDs never enter the model. The supplied dataset has 25,000 rows, balanced equally
between classes before train/test splitting. Source data and fitted models are not
redistributed; use an authorized local copy. tests.R runs independently of those files.

## Evaluation

A seeded, stratified 70/30 transaction split retains both classes in training and test.
Missing-value statistics and categorical levels are learned on training rows only.
Unknown categories map to an explicit fallback. The random forest uses 500 trees and
mtry=3. Positive class is explicitly Yes; the decision threshold is 0.5. Accuracy,
recall, precision, specificity, F1 and rank-based ROC AUC are computed from held-out
predictions. Metrics and importance are written to CSV; model/schema to RDS.

This is a random transaction holdout, not a future-time or unseen-customer evaluation.
The input has already been balanced, so these results do not estimate precision at
natural fraud prevalence. Forest vote shares are not calibrated fraud probabilities.
Clustering uses standardized numeric fields and does not label fraud.

## Implementation

- Encode categories with a stable training-derived factor schema.
- Construct observations by predictor name and validate numeric inputs.
- Train the model separately from the Shiny interface.
- Define the positive class and handle unseen categories explicitly.
- Standardize clustering inputs and check missingness and distinct-row counts.
- Distribute aggregate results and source code with original team credit.

The original poster reports 85.45% accuracy. The package's metrics describe the
held-out transaction evaluation documented above; accuracy and fraud recall are
reported as separate measures.
Keep team credit when sharing. This package does not assert an open-source license or
redistribution rights over the underlying data.


## Full analysis workflow

Also install ggplot2; jsonlite is needed only for the optional raw-source route.
Run from this directory:

    Rscript tests.R
    Rscript eda.R /path/to/Balanced_Processed.csv outputs
    Rscript train.R /path/to/Balanced_Processed.csv outputs
    Rscript plot.R outputs
    Rscript evaluation.R outputs
    Rscript segmentation.R /path/to/customers.csv outputs
    Rscript decision_analysis.R /path/to/Balanced_Processed.csv outputs
    Rscript smoke-test.R

Set FRAUD_MODEL_PATH and FRAUD_CUSTOMERS_PATH for the integration test if local
files are not in the defaults used by app.R. For the optional raw-source route:

    Rscript prepare.R /path/to/raw-tables outputs/Balanced_Processed.csv

prepare.R expects transactions_data.csv, users_data.csv, cards_data.csv and
train_fraud_labels.json with a named target mapping. It validates unique keys,
joins by named transaction/customer/card identifiers, checks card ownership when
available, parses monetary strings and reconstructs the historical 12,500/12,500
sample. This path is tested with synthetic fixtures; the complete original raw
tables were not supplied. It has not reproduced the original balanced CSV.
For a future production study, split original raw data by time/customer first and
resample training data only; preserve natural prevalence in validation and test.

### Analysis files

- prepare.R: keyed joins, monetary cleaning and historical balancing.
- eda.R: whole-file quality audit; training-only descriptive and category analysis.
- train.R / functions.R: the existing balanced-data model and its evaluation.
- evaluation.R: ROC, precision–recall and forest importance charts.
- segmentation.R: standardized k-means, cluster-count sensitivity and aggregate profiles.
- decision_analysis.R: cost-sensitive threshold selection, described below.
- app.R: transaction input and customer-exploration Shiny interface.

The EDA uses 17,500 training transactions. Negative amounts are retained;
no unsupported interpretation of those values is imposed. Customer segmentation
uses the separately supplied 307-row customer summary, with age and mean transaction
amount as an illustrative pair. k=3 is the app default, not a proven optimal count.
Only aggregate cluster profiles are distributed, never customer-level assignments.

### Prescriptive analysis

The decision analysis examines unequal error costs. The outer 70/30 split
matches train.R. The 17,500 outer-training rows are
split again: 14,000 model-fit rows and 3,500 threshold-validation rows. A separate
forest is fit once on those 14,000 rows. Thresholds minimize FP + r*FN on validation
for illustrative r values of 1, 5 and 10. Ties favor the higher threshold. The frozen
policies and a 0.50 baseline are evaluated on the same 7,500 outer-test rows, without
refitting. No threshold is selected using outer-test labels.

The outer holdout is also used by the main classifier. This is an exploratory
comparison on a shared holdout, not fresh external validation. The model
is different from the main 17,500-row-fit model, so their baseline metrics differ.
All costs are assumed relative units, not dollars or measured fraud losses. Neither
real fraud prevalence, review capacity nor probability calibration is established.
The selected policy can perform worse than baseline on test data; all outcomes are
reported. This is a decision-analysis demonstration, not a deployment recommendation.


## Portfolio

[Project overview and visualizations](https://chau-nguyen-research.gabledmango1.chatgpt.site/fraud.html) · [Chau Nguyen on LinkedIn](https://www.linkedin.com/in/chaunguyen2811)

## Supporting materials

- [Fraud Poster](documents/fraud-poster.pdf)

## Validation

See [executed checks and limits](docs/VALIDATION.md) and [result provenance](RESULTS_PROVENANCE.md).
After a completed data run, `Rscript verify_results.R outputs` checks the frozen **computed** reference; it does not fit or tune a model.

`report_summary.R outputs` derives the rounded recall/AUC statement from one set of held-out predictions and verifies it against `metrics.csv`. `run_all.R` invokes it automatically, so wording and exact metrics share the same evaluation.
