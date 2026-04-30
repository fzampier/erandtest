# =============================================================================
# Baseline e-RTe tables for the manuscript
# =============================================================================
#
# Run:
#   Rscript R/simulations/erte_baseline_tables.R 2000
#
# Outputs:
#   results/erte_signal_concentration.csv
#   results/erte_head_to_head_<n_sims>.csv
#   manuscript/erte_signal_concentration_table.tex
#   manuscript/erte_head_to_head_table.tex

suppressPackageStartupMessages({
  source("R/ertb.R")
  source("R/erte.R")
})

dir.create("results", showWarnings = FALSE)
dir.create("manuscript", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 2000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260426)

alpha <- 0.05
target_power <- 0.80

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

median_crossing <- function(x) {
  finite <- x[!is.na(x)]
  if (length(finite) == 0) NA_real_ else median(finite)
}

format_pct <- function(x, digits = 1) sprintf(paste0("%.", digits, "f\\%%"), 100 * x)
format_pp <- function(x, digits = 1) sprintf(paste0("%.", digits, "f pp"), 100 * x)
format_int <- function(x) {
  ifelse(is.na(x), "--", formatC(as.integer(round(x)), format = "d", big.mark = "{,}"))
}

# Signal concentration is deterministic.
signal <- signal_concentration_table(
  baseline_rates = c(0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40),
  arr = 0.05
)
signal$tilt_over_arr <- signal$tilt_from_half / signal$arr
write.csv(signal, "results/erte_signal_concentration.csv", row.names = FALSE)

signal_rows <- vapply(seq_len(nrow(signal)), function(i) {
  x <- signal[i, ]
  sprintf(
    "%s & %s & %.3f & %s & %.2f$\\times$ \\\\",
    format_pct(x$baseline, 0),
    format_pct(x$trt_rate, 0),
    x$event_coin,
    format_pp(x$tilt_from_half, 1),
    x$tilt_over_arr
  )
}, character(1))

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Signal concentration: event-coin tilt versus ARR for a 5pp risk reduction.}",
  "\\begin{tabular}{@{}ccccc@{}}",
  "\\toprule",
  "Baseline Event Rate & Treatment Event Rate & Event Coin $p_{\\text{alt}}$ & Tilt from 0.5 & Tilt / ARR \\\\",
  "\\midrule",
  signal_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:signal_concentration}",
  "\\end{table}"
), "manuscript/erte_signal_concentration_table.tex")

baseline_rates <- seq(0.10, 0.40, by = 0.05)
arr_values <- c(0.05, 0.075, 0.10)
minimum_treatment_rate <- 0.05

head_to_head_grid <- expand.grid(
  arr = arr_values,
  baseline = baseline_rates,
  KEEP.OUT.ATTRS = FALSE
)
head_to_head_grid$p_trt <- head_to_head_grid$baseline - head_to_head_grid$arr
head_to_head_grid <- head_to_head_grid[
  head_to_head_grid$p_trt >= minimum_treatment_rate,
]
head_to_head_grid <- head_to_head_grid[
  order(head_to_head_grid$arr, head_to_head_grid$baseline),
]

head_to_head_rows <- lapply(seq_len(nrow(head_to_head_grid)), function(i) {
  p_ctrl <- head_to_head_grid$baseline[[i]]
  arr <- head_to_head_grid$arr[[i]]
  p_trt <- p_ctrl - arr
  n_patients <- design_n_binary(p_ctrl, arr, target_power, alpha)
  n_events <- expected_events(n_patients, p_ctrl, p_trt)

  cat(sprintf(
    "e-RTe vs e-RTb same-N: p_ctrl=%.2f ARR=%.3f p_trt=%.3f N=%d events=%d\n",
    p_ctrl, arr, p_trt, n_patients, n_events
  ))

  ertb_crossed <- logical(n_sims)
  erte_crossed <- logical(n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)
    wealth_b <- compute_eRT(
      trial$treatment,
      trial$outcome,
      burn_in = 50,
      ramp = 100,
      wager = "adaptive"
    )
    ertb_crossed[[s]] <- any(wealth_b >= 1 / alpha)

    event_idx <- which(trial$outcome == 1)
    if (length(event_idx) == 0) {
      erte_crossed[[s]] <- FALSE
    } else {
      res_e <- compute_eRTe(
        trial$treatment[event_idx],
        burn_in = 30,
        ramp = 50,
        threshold = 1 / alpha,
        wager = "adaptive"
      )
      erte_crossed[[s]] <- res_e$crossed
    }
  }

  power_b <- mean(ertb_crossed)
  power_e <- mean(erte_crossed)
  delta <- power_e - power_b
  winner <- if (abs(delta) < 0.01) {
    "$\\sim$Tied"
  } else if (delta > 0) {
    "e-RTe"
  } else {
    "e-RTb"
  }

  data.frame(
    arr = arr,
    baseline = p_ctrl,
    trt_rate = p_trt,
    event_coin = event_coin(p_ctrl, p_trt),
    n_patients = n_patients,
    n_events = n_events,
    ertb_power = power_b,
    erte_power = power_e,
    delta = delta,
    winner = winner,
    n_sims = n_sims,
    target_power = target_power,
    alpha = alpha,
    stringsAsFactors = FALSE
  )
})

head_to_head <- do.call(rbind, head_to_head_rows)
head_to_head_file <- sprintf("results/erte_head_to_head_%s.csv", n_sims)
write.csv(head_to_head, head_to_head_file, row.names = FALSE)

head_to_head_tex_rows <- vapply(seq_len(nrow(head_to_head)), function(i) {
  x <- head_to_head[i, ]
  sprintf(
    "%s & %s & %.3f & %s & %s & %s & %s & $%+.1f$pp & %s \\\\",
    format_pp(x$arr, 1),
    format_pct(x$baseline, 0),
    x$event_coin,
    format_int(x$n_patients),
    format_int(x$n_events),
    format_pct(x$ertb_power, 1),
    format_pct(x$erte_power, 1),
    100 * x$delta,
    x$winner
  )
}, character(1))

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\caption{Head-to-head comparison: e-RTe versus e-RTb across absolute risk reductions, using the same trial data and same enrolled-patient sample size. Scenarios requiring treatment event rates below 5\\% are omitted.}",
  "\\begin{tabular}{@{}ccccccccl@{}}",
  "\\toprule",
  "ARR & Baseline & Event Coin & $N$ & Events & e-RTb Power & e-RTe Power & $\\Delta$ & Winner \\\\",
  "\\midrule",
  head_to_head_tex_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:compare_erte_binary}",
  "\\end{table}"
), "manuscript/erte_head_to_head_table.tex")

cat(sprintf("Saved %s\n", head_to_head_file))
cat("Saved e-RTe manuscript tables\n")
