# =============================================================================
# Binary wager-asymmetry stress table
# =============================================================================
#
# Run:
#   Rscript R/simulations/wager_asymmetry_binary.R 1000
#
# Outputs:
#   results/wager_asymmetry_binary_<n_sims>.csv
#   manuscript/wager_asymmetry_binary_table.tex
#   manuscript/wager_strategy_summary_table.tex

suppressPackageStartupMessages(source("R/ertb.R"))

dir.create("results", showWarnings = FALSE)
dir.create("manuscript", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260504)

alpha <- 0.05
p_ctrl <- 0.40
true_arr <- 0.05
p_trt <- p_ctrl - true_arr
n_patients <- 2942
magnitudes <- c(0.05, 0.10, 0.15, 0.20)

threshold_crossing <- function(wealth, alpha) {
  crossing <- which(wealth >= 1 / alpha)
  if (length(crossing) == 0) NA_integer_ else crossing[[1]]
}

rows <- lapply(magnitudes, function(magnitude) {
  crossings <- rep(NA_integer_, n_sims)
  finals <- numeric(n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)
    wealth <- compute_eRT(
      trial$treatment,
      trial$outcome,
      burn_in = 50,
      ramp = 100,
      wager = "fixed",
      fixed_event_lambda = 0.5 - magnitude,
      fixed_nonevent_lambda = 0.5 + magnitude
    )
    crossings[[s]] <- threshold_crossing(wealth, alpha)
    finals[[s]] <- tail(wealth, 1)
  }

  crossed <- !is.na(crossings)
  data.frame(
    fixed_wager_magnitude = magnitude,
    relative_scale = magnitude / true_arr,
    power = mean(crossed),
    se = sqrt(mean(crossed) * (1 - mean(crossed)) / n_sims),
    median_crossing = if (any(crossed)) median(crossings[crossed]) else NA_real_,
    median_final_evalue = median(finals),
    n_patients = n_patients,
    true_arr = true_arr,
    p_ctrl = p_ctrl,
    p_trt = p_trt,
    n_sims = n_sims,
    alpha = alpha,
    stringsAsFactors = FALSE
  )
})

results <- do.call(rbind, rows)
output_file <- sprintf("results/wager_asymmetry_binary_%s.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

format_pct <- function(x, digits = 1) sprintf(paste0("%.", digits, "f\\%%"), 100 * x)
format_num <- function(x, digits = 2) {
  ifelse(
    is.na(x),
    "--",
    ifelse(x < 0.005, "$\\approx 0$", sprintf(paste0("%.", digits, "f"), x))
  )
}

table_rows <- vapply(seq_len(nrow(results)), function(i) {
  x <- results[i, ]
  sprintf(
    "%.2f & $%.0f\\times$ & %s & %s \\\\",
    x$fixed_wager_magnitude,
    x$relative_scale,
    format_pct(x$power, 1),
    format_num(x$median_final_evalue, 2)
  )
}, character(1))

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  sprintf("\\caption{Binary: cost of naive over-betting (true ARR = 5\\%%, $N = 2{,}942$). Rows summarize %s fixed-seed simulated trials.}", formatC(n_sims, format = "d", big.mark = "{,}")),
  "\\begin{tabular}{@{}cccc@{}}",
  "\\toprule",
  "Fixed wager magnitude & Relative scale & Power & Median Final E-value \\\\",
  "\\midrule",
  table_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:wage_binary}",
  "\\end{table}"
), "manuscript/wager_asymmetry_binary_table.tex")

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\caption{Summary: wager-policy design considerations by e-RT variant.}",
  "\\begin{tabular}{@{}lcccc@{}}",
  "\\toprule",
  "Property & e-RTs & e-RTe & e-RTb & e-RTc \\\\",
  "\\midrule",
  "Update unit & Failure & Event & Patient & Patient \\\\",
  "Default policy & Fixed 0.25 & Full Kelly & Half Kelly & Sign direction \\\\",
  "Design-wager role & HR planning & Event-rate planning & ARR planning & Normal-shift model \\\\",
  "Over-betting sensitivity & Lower & Moderate & High & High \\\\",
  "Main tuning issue & HR misspecification & Event-stream length & Kelly shrinkage & Scale/model choice \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:wage_summary}",
  "\\end{table}"
), "manuscript/wager_strategy_summary_table.tex")

cat(sprintf("Saved %s\n", output_file))
cat("Saved manuscript/wager_asymmetry_binary_table.tex\n")
cat("Saved manuscript/wager_strategy_summary_table.tex\n")
