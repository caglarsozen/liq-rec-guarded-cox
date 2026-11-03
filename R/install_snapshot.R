liq_verify_public_snapshot <- function(root=getwd()) {
  root <- normalizePath(root,winslash="/",mustWork=TRUE)
  expected <- utils::read.csv(file.path(root,"metadata","expected_snapshot.csv"),stringsAsFactors=FALSE)
  required <- c("data/frozen_ohlcv.csv","data/frozen_ohlcv.csv.lock.csv",
                "data/data_provenance.csv","universe/universe_100.csv")
  if(!all(c("path","size","md5")%in%names(expected)) ||
     anyDuplicated(expected$path) || !setequal(expected$path,required))
    stop("Malformed public snapshot manifest.")
  paths <- file.path(root,expected$path)
  present <- file.exists(paths) & !dir.exists(paths)
  if(!all(present))stop("Install the authorized frozen snapshot using 08_INSTALL_SNAPSHOT.R first. Missing: ",
                       paste(expected$path[!present],collapse=", "))
  ok <- file.info(paths)$size==expected$size & unname(tools::md5sum(paths))==expected$md5
  if(!all(ok))stop("Input differs from the published snapshot identities: ",
                  paste(expected$path[!ok],collapse=", "),
                  ". A different vintage requires a separately documented experiment.")
  invisible(expected)
}

liq_install_snapshot <- function(archive,root=getwd()) {
  archive <- normalizePath(archive,winslash="/",mustWork=TRUE)
  root <- normalizePath(root,winslash="/",mustWork=TRUE)
  expected <- read.csv(file.path(root,"metadata","expected_snapshot.csv"),stringsAsFactors=FALSE)
  temp <- tempfile("liq_snapshot_");dir.create(temp)
  on.exit(unlink(temp,recursive=TRUE),add=TRUE)
  entries <- utils::unzip(archive,list=TRUE)$Name
  nested <- entries[basename(entries)=="Online_Resource_2_Replication.zip"]
  if(length(nested)>1L)stop("Ambiguous replication archive.")
  if(length(nested)==1L) {
    # Extract only this known archive member, using a flat temporary destination.
    utils::unzip(archive,files=nested,exdir=temp,junkpaths=TRUE)
    archive <- file.path(temp,"Online_Resource_2_Replication.zip")
    entries <- utils::unzip(archive,list=TRUE)$Name
  }
  staging <- file.path(temp,"verified");dir.create(staging)
  sources <- character(nrow(expected))
  for(i in seq_len(nrow(expected))) {
    suffix <- paste0("/",expected$path[i])
    candidate <- entries[entries==expected$archive_path[i] | entries==expected$path[i] |
                         endsWith(entries,suffix)]
    if(length(candidate)!=1L)stop("Missing or ambiguous snapshot member: ",expected$path[i])
    dir <- file.path(staging,as.character(i));dir.create(dir)
    utils::unzip(archive,files=candidate,exdir=dir,junkpaths=TRUE)
    sources[i] <- file.path(dir,basename(expected$path[i]))
    if(!file.exists(sources[i]) || file.info(sources[i])$size!=expected$size[i] ||
       unname(tools::md5sum(sources[i]))!=expected$md5[i])
      stop("Archived snapshot hash or size differs: ",expected$path[i])
    dest <- file.path(root,expected$path[i])
    if(file.exists(dest) && unname(tools::md5sum(dest))!=expected$md5[i])
      stop("Existing file differs; use a separate checkout: ",expected$path[i])
  }
  for(i in seq_len(nrow(expected))) {
    dest <- file.path(root,expected$path[i]);dir.create(dirname(dest),recursive=TRUE,showWarnings=FALSE)
    if(!file.exists(dest) && !file.copy(sources[i],dest,overwrite=FALSE))stop("Copy failed: ",dest)
  }
  liq_verify_public_snapshot(root)
  cat("Authorized frozen snapshot installed and verified. No provider download was performed.\n")
  invisible(expected)
}
