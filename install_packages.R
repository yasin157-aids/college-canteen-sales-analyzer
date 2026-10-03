# ==========================================================
# install_packages.R
# Checks whether the required package (ggplot2) is installed.
# If it is missing, it is installed automatically.
# (An internet connection is needed only for this one-time step.)
# ==========================================================

# The only package this project needs
required_packages <- c("ggplot2")

# Install into a personal library folder so no admin rights are needed
user_lib <- Sys.getenv("R_LIBS_USER")
if (user_lib != "") {
  if (!dir.exists(user_lib)) {
    dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
  }
  .libPaths(c(user_lib, .libPaths()))
}

for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("Package", pkg, "is already installed.\n")
  } else {
    cat("Package", pkg, "is not installed. Installing now...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org")

    # Check again to make sure the installation worked
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Could not install package '", pkg,
           "'. Please check your internet connection and try again.",
           call. = FALSE)
    }
    cat("Package", pkg, "installed successfully.\n")
  }
}
