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
  cat("Authorized frozen snapshot installed and verified. No provider download was performed.\n")
  invisible(expected)
}
