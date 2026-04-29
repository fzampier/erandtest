# =============================================================================
# Lightweight dependency check for the V8 standalone repository
# =============================================================================

required_packages <- c(
  "tidyverse",
  "ggplot2",
  "scales",
  "BuyseTest",
  "WRestimates"
)

required_tools <- c("pandoc", "latexmk")

package_ok <- vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
tool_paths <- Sys.which(required_tools)
tool_ok <- setNames(nzchar(tool_paths), required_tools)

cat("R package dependencies:\n")
for (pkg in required_packages) {
  status <- if (package_ok[[pkg]]) "OK" else "MISSING"
  cat(sprintf("  %-12s %s\n", pkg, status))
}

cat("\nCommand-line tools:\n")
for (tool in required_tools) {
  status <- if (tool_ok[[tool]]) tool_paths[[tool]] else "MISSING"
  cat(sprintf("  %-12s %s\n", tool, status))
}

if (!all(package_ok) || !all(tool_ok)) {
  missing_packages <- names(package_ok)[!package_ok]
  missing_tools <- names(tool_ok)[!tool_ok]

  if (length(missing_packages) > 0) {
    cat("\nMissing R packages:\n")
    cat(sprintf("  install.packages(c(%s))\n", paste(sprintf('\"%s\"', missing_packages), collapse = ", ")))
  }

  if (length(missing_tools) > 0) {
    cat("\nMissing command-line tools:\n")
    cat(sprintf("  %s\n", paste(missing_tools, collapse = ", ")))
  }

  stop("Dependency check failed", call. = FALSE)
}

cat("\nDependency check passed.\n")
