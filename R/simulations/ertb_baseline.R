# =============================================================================
# Baseline e-RTb operating characteristics for the manuscript
# =============================================================================
#
# Run:
#   Rscript R/simulations/ertb_baseline.R 5000
#
# Outputs:
#   results/ertb_baseline_<n_sims>.csv
#   manuscript/ertb_baseline_table.tex

suppressPackageStartupMessages(source("R/ertb.R"))

dir.create("results", showWarnings = FALSE)
dir.create("manuscript", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 5000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260427)

alpha <- 0.05
p_ctrl <- 0.40
arrs <- c(0.05, 0.10)
target_powers <- c(0.80, 0.90)

threshold_crossing <- function(wealth, alpha) {
  crossing <- which(wealth >= 1 / alpha)
  if (length(crossing) == 0) NA_integer_ else crossing[[1]]
}

design_n_binary <- function(p_ctrl, design_arr, target_power, alpha) {
  ss <- power.prop.test(
    p1 = p_ctrl,
    p2 = p_ctrl - design_arr,
    power = target_power,
    sig.level = alpha
  )
  2 * ceiling(ss$n)
}

run_one <- function(n_patients, p_trt) {
  crossings <- rep(NA_integer_, n_sims)
  finals <- numeric(n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)
    wealth <- compute_eRT(
      trial$treatment,
      trial$outcome,
      burn_in = 50,
      ramp = 100,
      wager = "adaptive"
    )
    crossings[[s]] <- threshold_crossing(wealth, alpha)
    finals[[s]] <- tail(wealth, 1)
  }

  crossed <- !is.na(crossings)
  list(
    rejection_rate = mean(crossed),
    se = sqrt(mean(crossed) * (1 - mean(crossed)) / n_sims),
    median_crossing = if (any(crossed)) median(crossings[crossed]) else NA_real_,
    median_final_evalue = median(finals)
  )
}

rows <- list()
for (target_power in target_powers) {
  for (arr in arrs) {
    n_patients <- design_n_binary(p_ctrl, arr, target_power, alpha)
    cat(sprintf(
      "e-RTb baseline: ARR=%.2f target_power=%.2f N=%d\n",
      arr, target_power, n_patients
    ))

    null_res <- run_one(n_patients, p_trt = p_ctrl)
    alt_res <- run_one(n_patients, p_trt = p_ctrl - arr)

    rows[[length(rows) + 1]] <- data.frame(
      arr = arr,
      target_power = target_power,
      n_patients = n_patients,
      type1_error = null_res$rejection_rate,
      type1_se = null_res$se,
      eRTb_power = alt_res$rejection_rate,
      power_se = alt_res$se,
      median_crossing = alt_res$median_crossing,
      median_crossing_frac = alt_res$median_crossing / n_patients,
      median_null_final_evalue = null_res$median_final_evalue,
      median_alt_final_evalue = alt_res$median_final_evalue,
      n_sims = n_sims,
      alpha = alpha,
      stringsAsFactors = FALSE
    )
  }
}

results <- do.call(rbind, rows)
output_file <- sprintf("results/ertb_baseline_%s.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

format_pct <- function(x, digits = 1) sprintf(paste0("%.", digits, "f\\%%"), 100 * x)
format_int <- function(x) {
  ifelse(is.na(x), "--", formatC(as.integer(round(x)), format = "d", big.mark = "{,}"))
}
format_arr <- function(x) sprintf("%.0f\\%%", 100 * x)
format_target <- function(x) sprintf("%.0f\\%%", 100 * x)

table_rows <- vapply(seq_len(nrow(results)), function(i) {
  x <- results[i, ]
  sprintf(
    "%s & %s & %s & %.3f & %s & %s (%s) \\\\",
    format_arr(x$arr),
    format_target(x$target_power),
    format_int(x$n_patients),
    x$type1_error,
    format_pct(x$eRTb_power),
    format_int(x$median_crossing),
    format_pct(x$median_crossing_frac, digits = 0)
  )
}, character(1))

table_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  sprintf("\\caption{Operating characteristics for adaptive e-RTb. Each row summarizes %s fixed-seed simulated trials under the null and %s under the matched alternative.}", format_int(n_sims), format_int(n_sims)),
  "\\begin{tabular}{@{}cccccc@{}}",
  "\\toprule",
  "ARR & Target Power & $N$ & Type I Error & e-RTb Power & Median Crossing \\\\",
  "\\midrule",
  table_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:simulations}",
  "\\end{table}"
)

writeLines(table_lines, "manuscript/ertb_baseline_table.tex")

cat(sprintf("\nSaved %s\n", output_file))
cat("Saved manuscript/ertb_baseline_table.tex\n")
print(results)
