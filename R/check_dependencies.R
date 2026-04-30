# =============================================================================
# Lightweight dependency check for the V8 standalone repository
# =============================================================================

required_packages <- c(
  "tidyverse",
  "ggplot2",
  "scales"
)

required_tools <- c("pandoc", "latexmk", "kpsewhich")
required_tex_files <- c("lineno.sty")

package_ok <- vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
tool_paths <- Sys.which(required_tools)
tool_ok <- setNames(nzchar(tool_paths), required_tools)
tex_paths <- setNames(rep("", length(required_tex_files)), required_tex_files)
tex_ok <- setNames(rep(FALSE, length(required_tex_files)), required_tex_files)

if (tool_ok[["kpsewhich"]]) {
  for (tex_file in required_tex_files) {
    path <- tryCatch(
      system2(tool_paths[["kpsewhich"]], tex_file, stdout = TRUE, stderr = FALSE),
      error = function(e) character()
    )
    if (length(path) > 0 && nzchar(path[[1]])) {
      tex_paths[[tex_file]] <- path[[1]]
      tex_ok[[tex_file]] <- TRUE
    }
  }
}

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

cat("\nLaTeX package files:\n")
for (tex_file in required_tex_files) {
  status <- if (tex_ok[[tex_file]]) tex_paths[[tex_file]] else "MISSING"
  cat(sprintf("  %-12s %s\n", tex_file, status))
}

if (!all(package_ok) || !all(tool_ok) || !all(tex_ok)) {
  missing_packages <- names(package_ok)[!package_ok]
  missing_tools <- names(tool_ok)[!tool_ok]
  missing_tex <- names(tex_ok)[!tex_ok]

  if (length(missing_packages) > 0) {
    cat("\nMissing R packages:\n")
    cat(sprintf("  install.packages(c(%s))\n", paste(sprintf('\"%s\"', missing_packages), collapse = ", ")))
  }

  if (length(missing_tools) > 0) {
    cat("\nMissing command-line tools:\n")
    cat(sprintf("  %s\n", paste(missing_tools, collapse = ", ")))
  }

  if (length(missing_tex) > 0) {
    cat("\nMissing LaTeX package files:\n")
    cat(sprintf("  %s\n", paste(missing_tex, collapse = ", ")))
    cat("  TinyTeX/TeX Live users can usually install with: tlmgr install lineno\n")
  }

  stop("Dependency check failed", call. = FALSE)
}

cat("\nDependency check passed.\n")
