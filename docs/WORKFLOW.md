# Source and implementation map

Original collaborative Spring 2025 project: Allison Spahn, Himanshu Niraj Sethia, Marissa Urbanek and Chau Nguyen, mentored by Matthew A. Lanham. The repository retains team credit and does not assign every original script to Chau individually.

| Stage | Retained source | Runnable implementation |
| --- | --- | --- |
| Raw tables and joins | `original_code/3.11.R`, `Balanced_Processed.R` | `prepare.R` |
| Data exploration | Original dated analysis files | `eda.R` |
| RF fitting and evaluation | Original 4.3/4.4 analysis files | `functions.R`, `train.R`, `evaluation.R` |
| Variable importance | `original_code/variable_importance.R` | `train.R`, `evaluation.R` |
| Customer segmentation | `original_code/Customer Clustering.R` | `segmentation.R` |
| Interactive application | `original_code/app.R` | `app.R`, `smoke-test.R` |
| New analysis extensions | No original-project attribution | `baseline.R`, `decision_analysis.R` |

The runnable reconstruction was prepared with AI assistance from retained materials. Improvements include named-key joins, training-only preprocessing, stable factor levels, explicit fraud-positive metrics, one-time model training, unknown-input handling, reproducible segmentation and validation-based threshold selection. `original_code/SHA256.csv` fingerprints unchanged source files.

The three-month project is represented through these analytical stages and the retained files; no dated development history or unverified individual contribution is invented.
