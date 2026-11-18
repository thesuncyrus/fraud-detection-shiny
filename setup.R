packages <- c("caret","randomForest","pROC","shiny","ggplot2","jsonlite","sqldf")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly=TRUE)]
if(length(missing)) install.packages(missing, repos="https://cloud.r-project.org")
remaining <- packages[!vapply(packages, requireNamespace, logical(1), quietly=TRUE)]
if(length(remaining)) stop(paste("Packages still unavailable:",paste(remaining,collapse=", ")))
cat("All fraud-analysis dependencies available.\n")
