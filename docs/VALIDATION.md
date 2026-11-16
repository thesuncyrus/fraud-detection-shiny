# Validation

Executed 2026-11-16, R 4.4.3, caret 7.0-1, randomForest 4.7-1.2 and pROC 1.18.5. The original 25,000-row data and original training workflow reproduce the 7,500-row test confusion matrix exactly. Accuracy 0.8545333333, recall 0.8504, AUC 0.9185742222. No target metric is used in training. train.R asserts the historical counts only after fitting/evaluation.

tests.R passes named-field encoding, unseen-category rejection, exact historical counts and a Shiny testServer prediction. Plot source reads genuine aggregate outputs. Raw-table preparation is retained but not rerun; complete raw inputs are missing. No natural-prevalence or operational-impact claim is established.

The original logistic experiment also ran: AUC 0.719259, 95% CI 0.707772–0.730747, accuracy 0.6592 on 7,500 balanced-sample test rows. It preserves the original ID predictor and 0.5 threshold.
