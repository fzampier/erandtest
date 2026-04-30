# =============================================================================
# e-RTwr manuscript tables
# =============================================================================
#
# Run:
#   Rscript explorations/ertwr/R/simulations/ertwr_tables.R
#
# Inputs:
#   explorations/ertwr/results/ertwr_sokolova_comparison_1000.csv
#   explorations/ertwr/results/ertwr_composite_buysetest_300_250.csv
#
# Outputs:
#   explorations/ertwr/manuscript/ertwr_sokolova_table.tex
#   explorations/ertwr/manuscript/ertwr_composite_table.tex

dir.create("manuscript", showWarnings = FALSE)

sokolova_file <- "explorations/ertwr/results/ertwr_sokolova_comparison_1000.csv"
composite_file <- "explorations/ertwr/results/ertwr_composite_buysetest_300_250.csv"

if (!file.exists(sokolova_file)) {
  stop(sprintf("Missing %s. Run ertwr_sokolova_comparison.R 1000 first.", sokolova_file))
}
if (!file.exists(composite_file)) {
  stop(sprintf("Missing %s. Run ertwr_composite_buysetest.R 300 250 first.", composite_file))
}

format_pct <- function(x, digits = 1) {
  ifelse(is.na(x), "--", sprintf(paste0("%.", digits, "f\\%%"), 100 * x))
}
format_num <- function(x, digits = 2) {
  ifelse(is.na(x), "--", sprintf(paste0("%.", digits, "f"), x))
}
format_int <- function(x) {
  ifelse(is.na(x), "--", formatC(as.integer(round(x)), format = "d", big.mark = "{,}"))
}

sokolova <- read.csv(sokolova_file, stringsAsFactors = FALSE)
sokolova$method_display <- sokolova$method
sokolova$method_display[sokolova$method == "Sokolova-style GROW e-design"] <- "Sokolova-style GROW e-design"

sokolova_rows <- vapply(seq_len(nrow(sokolova)), function(i) {
  x <- sokolova[i, ]
  sprintf(
    "%.2f & %s & %s & %s & %s & %s \\\\",
    x$true_wr,
    x$method_display,
    format_int(x$n_pairs),
    format_num(x$n_ratio_to_yu_ganju, 2),
    format_pct(x$null_rejection_rate, 1),
    format_pct(x$rejection_rate, 1)
  )
}, character(1))

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Simple win-ratio simulations comparing final WR analysis, adaptive e-RTwr, fixed/GROW e-RTwr, and e-process-calibrated GROW design. Each e-process row uses 1{,}000 simulations.}",
  "\\begin{tabular}{@{}llrrrr@{}}",
  "\\toprule",
  "True WR & Comparator & Pairs & N/YG & Null Reject & Power \\\\",
  "\\midrule",
  sokolova_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:ertwr_sokolova}",
  "\\end{table}"
), "explorations/ertwr/manuscript/ertwr_sokolova_table.tex")

composite <- read.csv(composite_file, stringsAsFactors = FALSE)
summary_rows <- do.call(
  rbind,
  lapply(split(composite, composite$scenario), function(x) {
    data.frame(
      scenario = x$scenario[[1]],
      buysetest_rejection_rate = mean(x$buysetest_reject),
      buysetest_se = sqrt(mean(x$buysetest_reject) * (1 - mean(x$buysetest_reject)) / nrow(x)),
      adaptive_rejection_rate = mean(x$adaptive_reject),
      adaptive_se = sqrt(mean(x$adaptive_reject) * (1 - mean(x$adaptive_reject)) / nrow(x)),
      fixed_rejection_rate = mean(x$fixed_reject),
      fixed_se = sqrt(mean(x$fixed_reject) * (1 - mean(x$fixed_reject)) / nrow(x)),
      median_buysetest_wr = median(x$buysetest_wr, na.rm = TRUE),
      median_disjoint_wr = median(x$disjoint_wr, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
)
summary_rows <- summary_rows[match(c("null", "composite_alt"), summary_rows$scenario), ]

scenario_label <- function(x) {
  ifelse(x == "null", "Null", "Composite alternative")
}
rate_with_se <- function(rate, se) {
  sprintf("%s (%s)", format_pct(rate, 1), format_pct(se, 1))
}

composite_tex_rows <- vapply(seq_len(nrow(summary_rows)), function(i) {
  x <- summary_rows[i, ]
  sprintf(
    "%s & %s & %s & %s & %.2f & %.2f \\\\",
    scenario_label(x$scenario),
    rate_with_se(x$buysetest_rejection_rate, x$buysetest_se),
    rate_with_se(x$adaptive_rejection_rate, x$adaptive_se),
    rate_with_se(x$fixed_rejection_rate, x$fixed_se),
    x$median_buysetest_wr,
    x$median_disjoint_wr
  )
}, character(1))

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Composite endpoint simulation using \\texttt{BuyseTest} and disjoint-pair e-RTwr. Rates are shown with Monte Carlo standard errors.}",
  "\\begin{tabular}{@{}lrrrrr@{}}",
  "\\toprule",
  "Scenario & BuyseTest & Adaptive & Fixed/design & Buyse WR & Disjoint WR \\\\",
  "\\midrule",
  composite_tex_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:ertwr_composite}",
  "\\end{table}"
), "explorations/ertwr/manuscript/ertwr_composite_table.tex")

cat("Saved explorations/ertwr/manuscript/ertwr_sokolova_table.tex\n")
cat("Saved explorations/ertwr/manuscript/ertwr_composite_table.tex\n")
