# Optional: install the directly recorded package versions for archival reproduction.
# Source installation may require the platform's R build tools (Rtools on Windows).
recorded <- read.csv(file.path("metadata","original_package_versions.csv"),stringsAsFactors=FALSE)
options(repos=c(CRAN="https://cloud.r-project.org"))
if (!requireNamespace("remotes",quietly=TRUE))install.packages("remotes")
# Matrix and Rcpp precede compiled downstream packages.
priority <- c("Matrix","Rcpp","iterators","foreach","shape","data.table","survival","glmnet","digest","zip")
recorded <- recorded[match(priority,recorded$package),]
for(i in seq_len(nrow(recorded))) {
  p <- recorded$package[i];v <- recorded$version[i]
  installed <- utils::installed.packages()
  same <- p%in%rownames(installed) && package_version(installed[p,"Version"])==package_version(v)
  if(!same)remotes::install_version(p,version=v,dependencies=NA,upgrade="never",repos="https://cloud.r-project.org")
}
cat("Recorded package installation requested. Restart R before loading the model,\n",
    "then export sessionInfo with 06_EXPORT_SPECIFICATION.R.\n",sep="")
