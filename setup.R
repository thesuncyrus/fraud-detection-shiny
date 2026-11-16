packages <- c("randomForest", "shiny", "ggplot2", "jsonlite")
missing <- packages[!vapply(packages, requireNamespace, TRUE, quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
cat("All runtime dependencies available.\n")
