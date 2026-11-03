# Run once from the repository root. Model loading never installs packages.
packages <- c("data.table","survival","glmnet","digest","zip")
repos <- getOption("repos")
if (!length(repos) || any(repos=="@CRAN@"))
  options(repos=c(CRAN="https://cloud.r-project.org"))
missing <- packages[!vapply(packages,requireNamespace,logical(1),quietly=TRUE)]
if (length(missing)) install.packages(missing,dependencies=NA)
if (!all(vapply(packages,requireNamespace,logical(1),quietly=TRUE)))
  stop("Some required packages are still unavailable.")
cat("Dependencies available:\n")
for (p in packages) cat(p,as.character(utils::packageVersion(p)),"\n")
