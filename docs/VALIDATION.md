# Validation

Verified on 2026-11-16 with R 4.5.3.

- Unit checks cover joins/keys/card ownership, monetary parsing, split isolation, training schema, unseen categories, recall/accuracy distinction, tied AUC, ROC endpoint thresholds and invalid inputs.
- `run_all.R` completed on the supplied balanced CSV and customer summary, including EDA, RF, logistic baseline, plots, segmentation, threshold policy analysis and Shiny server integration.
- `verify_results.R` reproduced all ten stored RF metrics/counts exactly in this environment (tolerance 1e-8).
- The app test executed prediction from named inputs and optional clustering using the saved model. It did not retrain a model per visitor.

Full raw-table regeneration was only fixture-tested because the complete raw sources were not supplied. These tests do not establish natural-prevalence or operational performance.
