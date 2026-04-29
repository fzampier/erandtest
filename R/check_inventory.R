# =============================================================================
# Manuscript artifact inventory check
# =============================================================================

manuscript_file <- "manuscript/e-RT_v8.tex"
inventory_file <- "notes/reproducibility_inventory.md"

if (!file.exists(manuscript_file)) stop("Missing ", manuscript_file, call. = FALSE)
if (!file.exists(inventory_file)) stop("Missing ", inventory_file, call. = FALSE)

tex <- paste(readLines(manuscript_file, warn = FALSE), collapse = "\n")
inventory <- paste(readLines(inventory_file, warn = FALSE), collapse = "\n")

extract_matches <- function(pattern, text) {
  matches <- gregexpr(pattern, text, perl = TRUE)[[1]]
  if (identical(matches, -1L)) return(character())
  raw <- regmatches(text, list(matches))[[1]]
  trimws(sub(pattern, "\\1", raw, perl = TRUE))
}

graphics <- extract_matches("\\\\includegraphics(?:\\[[^]]*\\])?\\{([^}]+)\\}", tex)
inputs <- extract_matches("\\\\input\\{([^}]+)\\}", tex)

artifact_paths <- c(
  file.path("manuscript", graphics),
  file.path("manuscript", inputs)
)

missing_files <- artifact_paths[!file.exists(artifact_paths)]
missing_inventory <- c(graphics, inputs)[
  !vapply(c(graphics, inputs), function(x) grepl(x, inventory, fixed = TRUE), logical(1))
]

inside_git <- identical(
  suppressWarnings(system2("git", c("rev-parse", "--is-inside-work-tree"), stdout = TRUE, stderr = FALSE)),
  "true"
)

undocumented_pdfs <- character()
undocumented_csvs <- character()

if (inside_git) {
  tracked <- system2("git", c("ls-files", "manuscript", "results"), stdout = TRUE)
  tracked <- tracked[file.exists(tracked)]
  tracked_pdfs <- tracked[grepl("\\.pdf$", tracked)]
  tracked_csvs <- tracked[grepl("\\.csv$", tracked)]
  undocumented_pdfs <- tracked_pdfs[
    !vapply(tracked_pdfs, function(x) grepl(basename(x), inventory, fixed = TRUE), logical(1))
  ]
  undocumented_csvs <- tracked_csvs[
    !vapply(tracked_csvs, function(x) grepl(basename(x), inventory, fixed = TRUE), logical(1))
  ]
} else {
  cat("Git metadata not available; skipping tracked artifact documentation check.\n\n")
}

cat("Manuscript includegraphics targets:\n")
cat(sprintf("  %s\n", graphics), sep = "")
cat("\nManuscript input targets:\n")
cat(sprintf("  %s\n", inputs), sep = "")

if (length(missing_files) > 0) {
  cat("\nMissing files:\n")
  cat(sprintf("  %s\n", missing_files), sep = "")
}

if (length(missing_inventory) > 0) {
  cat("\nReferenced artifacts not mapped in inventory:\n")
  cat(sprintf("  %s\n", missing_inventory), sep = "")
}

if (length(undocumented_pdfs) > 0) {
  cat("\nTracked PDFs not documented in inventory:\n")
  cat(sprintf("  %s\n", undocumented_pdfs), sep = "")
}

if (length(undocumented_csvs) > 0) {
  cat("\nTracked CSVs not documented in inventory:\n")
  cat(sprintf("  %s\n", undocumented_csvs), sep = "")
}

if (
  length(missing_files) > 0 ||
    length(missing_inventory) > 0 ||
    length(undocumented_pdfs) > 0 ||
    length(undocumented_csvs) > 0
) {
  stop("Inventory check failed", call. = FALSE)
}

cat("\nInventory check passed.\n")
