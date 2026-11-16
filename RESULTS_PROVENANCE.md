# Result provenance

| Evaluation | Accuracy | Fraud recall | ROC AUC | Source |
| --- | ---: | ---: | ---: | --- |
| Original RF poster | 0.8545 | approximately 0.8504 | Not reported for RF | Poster and its confusion matrix |
| Recomputed RF | 0.8544 | 0.8469333 | 0.9190680 | Supplied balanced CSV; fixed stratified 70/30 holdout |
| New paired logistic baseline | 0.7776 | 0.6960 | 0.8433750 | Same holdout and training-only preprocessing as recomputed RF |
| Original logistic poster | Not stated here | Not stated here | 0.7193 | Separate historical experiment |

The recomputed RF has TP=3176, TN=3232, FP=518 and FN=574 on 7,500 held-out transactions. Recall rounds to approximately 85% and AUC to 0.92. Accuracy and recall are distinct quantities. Exact metrics from different experiments are not combined.

`baseline.R` is a new matched logistic comparison, not a reproduction of the poster's logistic experiment. It handles the redundant intercept/category columns caused by the explicit unseen-category fallback using training-only QR rank selection.

`decision_analysis.R` is an additional exploratory policy analysis. It selects thresholds using 3,500 inner-validation rows, fits on 14,000 rows and evaluates frozen policies on the shared 7,500-row outer holdout. The assumed costs are relative units; this does not establish operational savings or fresh external validation.

The original `final_graph.R` contains assumed impact percentages. It is retained only as historical source and is not executed by the runnable workflow or treated as measured impact. All reported performance uses a dataset balanced before splitting; it does not estimate precision at natural fraud prevalence or future-time/unseen-customer performance.
