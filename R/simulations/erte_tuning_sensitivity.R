# =============================================================================
# e-RTe / e-RTb Adaptive Tuning Sensitivity
# =============================================================================
#
# Run:
#   Rscript R/simulations/erte_tuning_sensitivity.R 1000
#
# Outputs:
#   results/erte_tuning_sensitivity_<n_sims>.csv
#   manuscript/erte_tuning_sensitivity_table.tex

suppressPackageStartupMessages({
  source("R/ertb.R")
  source("R/erte.R")
  library(dplyr)
})

dir.create("results", showWarnings = FALSE)
dir.create("manuscript", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260430)

alpha <- 0.05
target_power <- 0.80
minimum_treatment_rate <- 0.05

design_n_binary <- function(p_ctrl, design_arr, target_power, alpha) {
  ss <- power.prop.test(
    p1 = p_ctrl,
    p2 = p_ctrl - design_arr,
    power = target_power,
    sig.level = alpha
  )
  2 * ceiling(ss$n)
}

threshold_crossing <- function(wealth, alpha) {
  crossing <- which(wealth >= 1 / alpha)
  if (length(crossing) == 0) NA_integer_ else crossing[[1]]
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

schedule_params <- function(endpoint, schedule, n_patients, n_events_expected) {
  unit_n <- if (endpoint == "e-RTb") n_patients else n_events_expected

  if (schedule == "default") {
    if (endpoint == "e-RTb") {
      return(c(burn_in = 50L, ramp = 100L))
    }
    return(c(burn_in = 30L, ramp = 50L))
  }

  if (schedule == "fixed_10_20") {
    return(c(burn_in = 10L, ramp = 20L))
  }

  if (schedule == "fixed_30_50") {
    return(c(burn_in = 30L, ramp = 50L))
  }

  if (schedule == "proportional_5_10") {
    return(c(
      burn_in = max(1L, ceiling(0.05 * unit_n)),
      ramp = max(1L, ceiling(0.10 * unit_n))
    ))
  }

  if (schedule == "proportional_10_20") {
    return(c(
      burn_in = max(1L, ceiling(0.10 * unit_n)),
      ramp = max(1L, ceiling(0.20 * unit_n))
    ))
  }

  stop("Unknown schedule: ", schedule)
}

schedule_label <- function(schedule) {
  labels <- c(
    default = "default",
    fixed_10_20 = "10/20 events",
    fixed_30_50 = "30/50 events",
    proportional_5_10 = "5/10\\%",
    proportional_10_20 = "10/20\\%"
  )
  out <- unname(labels[schedule])
  ifelse(is.na(out), schedule, out)
}

policy_label <- function(schedule, kelly_fraction) {
  sprintf("%s, %sK", schedule_label(schedule), format_pct(kelly_fraction, 0))
}

scenario_grid <- expand.grid(
  arr = c(0.05, 0.075, 0.10),
  baseline = seq(0.10, 0.40, by = 0.05),
  KEEP.OUT.ATTRS = FALSE
)
scenario_grid$p_trt <- scenario_grid$baseline - scenario_grid$arr
scenario_grid <- scenario_grid[scenario_grid$p_trt >= minimum_treatment_rate, ]
scenario_grid <- scenario_grid[order(scenario_grid$arr, scenario_grid$baseline), ]

schedule_grid <- c(
  "default",
  "fixed_10_20",
  "fixed_30_50",
  "proportional_5_10",
  "proportional_10_20"
)
kelly_grid <- c(0.25, 0.50, 0.75, 1.00)
endpoint_grid <- c("e-RTb", "e-RTe")

config_grid <- expand.grid(
  endpoint = endpoint_grid,
  schedule = schedule_grid,
  kelly_fraction = kelly_grid,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)

all_results <- vector("list", nrow(scenario_grid))

for (scenario_index in seq_len(nrow(scenario_grid))) {
  scenario <- scenario_grid[scenario_index, ]
  p_ctrl <- scenario$baseline
  arr <- scenario$arr
  p_trt <- scenario$p_trt
  n_patients <- design_n_binary(p_ctrl, arr, target_power, alpha)
  n_events_expected <- expected_events(n_patients, p_ctrl, p_trt)

  cfg <- config_grid
  cfg$burn_in <- NA_integer_
  cfg$ramp <- NA_integer_
  for (i in seq_len(nrow(cfg))) {
    params <- schedule_params(
      endpoint = cfg$endpoint[[i]],
      schedule = cfg$schedule[[i]],
      n_patients = n_patients,
      n_events_expected = n_events_expected
    )
    cfg$burn_in[[i]] <- params[["burn_in"]]
    cfg$ramp[[i]] <- params[["ramp"]]
  }

  crossed <- matrix(FALSE, nrow = n_sims, ncol = nrow(cfg))
  crossings <- matrix(NA_integer_, nrow = n_sims, ncol = nrow(cfg))
  final_evalues <- matrix(NA_real_, nrow = n_sims, ncol = nrow(cfg))

  cat(sprintf(
    "Tuning sensitivity: ARR=%.3f p_ctrl=%.2f p_trt=%.3f N=%d events=%d\n",
    arr, p_ctrl, p_trt, n_patients, n_events_expected
  ))

  for (sim in seq_len(n_sims)) {
    trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)
    event_idx <- which(trial$outcome == 1)

    for (j in seq_len(nrow(cfg))) {
      if (cfg$endpoint[[j]] == "e-RTb") {
        wealth <- compute_eRT(
          trial$treatment,
          trial$outcome,
          burn_in = cfg$burn_in[[j]],
          ramp = cfg$ramp[[j]],
          wager = "adaptive",
          kelly_fraction = cfg$kelly_fraction[[j]]
        )
        crossings[[sim, j]] <- threshold_crossing(wealth, alpha)
        crossed[[sim, j]] <- !is.na(crossings[[sim, j]])
        final_evalues[[sim, j]] <- tail(wealth, 1)
      } else {
        if (length(event_idx) == 0) {
          crossed[[sim, j]] <- FALSE
          final_evalues[[sim, j]] <- 1
        } else {
          res <- compute_eRTe(
            trial$treatment[event_idx],
            burn_in = cfg$burn_in[[j]],
            ramp = cfg$ramp[[j]],
            threshold = 1 / alpha,
            wager = "adaptive",
            kelly_fraction = cfg$kelly_fraction[[j]]
          )
          crossed[[sim, j]] <- res$crossed
          crossings[[sim, j]] <- res$crossed_at
          final_evalues[[sim, j]] <- tail(res$wealth, 1)
        }
      }
    }
  }

  scenario_results <- lapply(seq_len(nrow(cfg)), function(j) {
    pwr <- mean(crossed[, j])
    data.frame(
      arr = arr,
      baseline = p_ctrl,
      trt_rate = p_trt,
      n_patients = n_patients,
      n_events = n_events_expected,
      endpoint = cfg$endpoint[[j]],
      schedule = cfg$schedule[[j]],
      kelly_fraction = cfg$kelly_fraction[[j]],
      burn_in = cfg$burn_in[[j]],
      ramp = cfg$ramp[[j]],
      power = pwr,
      se = sqrt(pwr * (1 - pwr) / n_sims),
      median_crossing = median_crossing(crossings[, j]),
      median_final_evalue = median(final_evalues[, j]),
      n_sims = n_sims,
      target_power = target_power,
      alpha = alpha,
      stringsAsFactors = FALSE
    )
  })

  all_results[[scenario_index]] <- do.call(rbind, scenario_results)
}

results <- do.call(rbind, all_results)
results_file <- sprintf("results/erte_tuning_sensitivity_%s.csv", n_sims)
write.csv(results, results_file, row.names = FALSE)

default_rows <- results %>%
  filter(
    (endpoint == "e-RTb" & schedule == "default" & kelly_fraction == 0.50) |
      (endpoint == "e-RTe" & schedule == "default" & kelly_fraction == 1.00)
  ) %>%
  select(arr, baseline, endpoint, default_power = power)

best_rows <- results %>%
  group_by(arr, baseline, endpoint) %>%
  arrange(desc(power), schedule, kelly_fraction, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  mutate(best_label = policy_label(schedule, kelly_fraction)) %>%
  select(arr, baseline, endpoint, best_power = power, best_label)

summary_rows <- results %>%
  distinct(arr, baseline, trt_rate, n_patients, n_events) %>%
  left_join(default_rows %>% filter(endpoint == "e-RTb") %>% select(-endpoint),
            by = c("arr", "baseline")) %>%
  rename(ertb_default = default_power) %>%
  left_join(default_rows %>% filter(endpoint == "e-RTe") %>% select(-endpoint),
            by = c("arr", "baseline")) %>%
  rename(erte_default = default_power) %>%
  left_join(best_rows %>% filter(endpoint == "e-RTb") %>% select(-endpoint),
            by = c("arr", "baseline")) %>%
  rename(ertb_best = best_power, ertb_best_label = best_label) %>%
  left_join(best_rows %>% filter(endpoint == "e-RTe") %>% select(-endpoint),
            by = c("arr", "baseline")) %>%
  rename(erte_best = best_power, erte_best_label = best_label) %>%
  mutate(
    tuned_winner = case_when(
      abs(erte_best - ertb_best) < 0.01 ~ "$\\sim$Tied",
      erte_best > ertb_best ~ "e-RTe",
      TRUE ~ "e-RTb"
    )
  ) %>%
  arrange(arr, baseline)

format_best <- function(power, label) {
  sprintf("%s (%s)", format_pct(power, 1), label)
}

table_rows <- vapply(seq_len(nrow(summary_rows)), function(i) {
  x <- summary_rows[i, ]
  sprintf(
    "%s & %s & %s & %s & %s & %s & %s & %s \\\\",
    format_pp(x$arr, 1),
    format_pct(x$baseline, 0),
    format_int(x$n_events),
    format_pct(x$ertb_default, 1),
    format_best(x$ertb_best, x$ertb_best_label),
    format_pct(x$erte_default, 1),
    format_best(x$erte_best, x$erte_best_label),
    x$tuned_winner
  )
}, character(1))

writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\scriptsize",
  "\\setlength{\\tabcolsep}{3pt}",
    sprintf("\\caption{Sensitivity of adaptive e-RTb and e-RTe to burn-in/ramp schedule and Kelly intensity. Each row uses the same trial-data scenarios as Table~\\ref{tab:compare_erte_binary}; values summarize %s fixed-seed simulations. Tuned columns show the best power over fixed 10/20-event, fixed 30/50-event, default, proportional 5/10\\%%, and proportional 10/20\\%% burn-in/ramp schedules crossed with 25\\%%, 50\\%%, 75\\%%, and 100\\%% Kelly intensity.}", format_int(n_sims)),
  "\\begin{tabular}{@{}cccccccl@{}}",
  "\\toprule",
  "ARR & Baseline & Events & e-RTb Default & e-RTb Tuned & e-RTe Default & e-RTe Tuned & Winner \\\\",
  "\\midrule",
  table_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\label{tab:erte_tuning_sensitivity}",
  "\\end{table}"
), "manuscript/erte_tuning_sensitivity_table.tex")

cat(sprintf("Saved %s\n", results_file))
cat("Saved manuscript/erte_tuning_sensitivity_table.tex\n")
