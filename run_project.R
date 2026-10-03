# ==========================================================
# run_project.R
# Runs the whole project in one step:
#   1. Checks/installs ggplot2
#   2. Runs the canteen analysis (reads CSV, makes graphs,
#      writes the report, prints the results)
#
# How to run (from the project folder):
#   Rscript run_project.R
# ==========================================================

# ---- Find the folder where this file is stored ----
# This lets the project work no matter where it is extracted.
get_project_dir <- function() {
  # Case 1: run with "Rscript run_project.R"
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg[1])
    return(dirname(normalizePath(script_path)))
  }

  # Case 2: run with source("run_project.R") or the VS Code "Run Source" button
  for (i in rev(seq_len(sys.nframe()))) {
    script_path <- tryCatch(sys.frame(i)$ofile, error = function(e) NULL)
    if (!is.null(script_path)) {
      return(dirname(normalizePath(script_path)))
    }
  }

  # Case 3: fall back to the current working directory
  return(getwd())
}

project_dir <- get_project_dir()
setwd(project_dir)   # all other files are found using relative paths
cat("Project folder:", project_dir, "\n\n")

# ---- Step 1: make sure ggplot2 is installed ----
source("install_packages.R")

# ---- Step 2: run the analysis ----
source("canteen_analyzer.R")
