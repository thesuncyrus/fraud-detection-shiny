# Logistic experiment includes ID as a predictor.
# This differs from the final Random Forest feature set; it is not a matched-feature benchmark.
args <- commandArgs(trailingOnly=TRUE)
if (!length(args)) stop("Supply the authorized Balanced_Processed.csv file.")
output <- if(length(args)>1) args[2] else "outputs/logistic"
dir.create(output,recursive=TRUE,showWarnings=FALSE)
d <- read.csv(args[1])
stopifnot(nrow(d)==25000, all(c("label","id") %in% names(d)))
d$label <- as.factor(d$label)
for (name in names(d)) if (is.character(d[[name]])) d[[name]] <- as.numeric(as.factor(d[[name]]))
set.seed(123)
index <- caret::createDataPartition(d$label,p=.7,list=FALSE)
train <- d[index,];test <- d[-index,]
model <- glm(label~.,data=train,family=binomial())
probability <- predict(model,newdata=test,type="response")
prediction <- ifelse(probability>.5,levels(train$label)[2],levels(train$label)[1])
roc <- pROC::roc(test$label,probability,quiet=TRUE)
ci <- pROC::ci.auc(roc)
metrics <- data.frame(accuracy=mean(prediction==test$label),auc=as.numeric(pROC::auc(roc)),auc_ci_low=ci[1],auc_ci_high=ci[3],n_test=nrow(test))
write.csv(metrics,file.path(output,"logistic-metrics.csv"),row.names=FALSE)
write.csv(as.data.frame.matrix(table(actual=test$label,predicted=prediction)),file.path(output,"logistic-confusion.csv"))
print(metrics)
