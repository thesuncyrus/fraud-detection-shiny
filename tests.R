# Meaningful checks for the corrected Shiny field mapping and historical fit.
source("src/fraud_model.R")
path <- Sys.getenv("FRAUD_MODEL_PATH","outputs/model.rds")
if(!file.exists(path)) stop("Train the historical model before running this integration check.")
b <- readRDS(path)
values <- as.list(b$defaults)
for(n in names(b$levels)) values[[n]] <- b$levels[[n]][1]
x <- encode_observation(values,b)
stopifnot(identical(names(x),b$features),nrow(x)==1)
for(n in setdiff(b$features,names(b$levels))) stopifnot(x[[n]]==values[[n]])
for(n in names(b$levels)) stopifnot(x[[n]]==1)
bad <- values;bad[[names(b$levels)[1]]] <- "unseen value"
stopifnot(inherits(try(encode_observation(bad,b),silent=TRUE),"try-error"))
stopifnot(identical(as.integer(b$confusion),c(3220L,530L,561L,3189L)))
app_env <- new.env(parent=globalenv())
sys.source("app.R",app_env)
shiny::testServer(app_env$server, {
 do.call(session$setInputs,c(values,list(classify=1)))
 expected <- as.character(predict(b$model,x,type="response"))
 stopifnot(grepl(paste0("Classification: ",expected),output$prediction,fixed=TRUE))
})
cat("Named predictor encoding, rejection of unknown categories, original confusion matrix and Shiny prediction passed.\n")
