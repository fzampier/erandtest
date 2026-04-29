# =============================================================================
# e-RTwr Adaptive Wager Tuning
# =============================================================================
#
# Compares adaptive e-RTwr policies across Kelly fractions, burn-ins, and ramps.
#
# Run:
#   Rscript R/simulations/ertwr_adaptive_tuning.R 1000
#   Rscript R/simulations/ertwr_adaptive_tuning.R 1000 fine
#
# Output:
#   results/ertwr_adaptive_tuning_<n_sims>.csv
#   results/ertwr_adaptive_tuning_fine_<n_sims>.csv

suppressPackageStartupMessages(source("R/ertwr.R"))

dir.create("results", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 500L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")
mode <- if (length(args) >= 2) args[[2]] else "coarse"
if (!mode %in% c("coarse", "fine")) stop("mode must be 'coarse' or 'fine'")

set.seed(20260430)

alpha <- 0.05
target_power <- 0.80
wr_grid <- c(1.10, 1.20, 1.30, 1.50)

tuning_grid <- if (mode == "coarse") {
  expand.grid(
    kelly_fraction = c(0.5, 1.0),
    burn_in = c(0, 10, 30),
    ramp = c(1, 20, 50),
    stringsAsFactors = FALSE
  )
} else {
  expand.grid(
    kelly_fraction = 1.0,
    burn_in = c(0, 10, 20, 30),
    ramp = c(20, 35, 50, 75, 100),
    stringsAsFactors = FALSE
  )
}

summarize_runs <- function(crossings, finals) {
  reject <- !is.na(crossings)
  rate <- mean(reject)
  data.frame(
    rejection_rate = rate,
    se = sqrt(rate * (1 - rate) / length(crossings)),
    median_crossing = if (any(reject)) median(crossings[reject]) else NA_real_,
    median_final_evalue = median(finals),
    stringsAsFactors = FALSE
  )
}

run_adaptive_policy <- function(n_sims, n_pairs, true_wr,
                                kelly_fraction, burn_in, ramp) {
  d_true <- wr_to_d(true_wr)
  crossings <- rep(NA_integer_, n_sims)
  finals <- numeric(n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_pairwise_continuous(n_pairs, d_true = d_true)
    wealth <- compute_eRTwr(
      trial$d_pair,
      wager = "adaptive",
      burn_in = burn_in,
      ramp = ramp,
      kelly_fraction = kelly_fraction
    )
    crossings[[s]] <- threshold_crossing(wealth, alpha)
    finals[[s]] <- tail(wealth, 1)
  }

  summarize_runs(crossings, finals)
}

run_tuning_row <- function(true_wr, kelly_fraction, burn_in, ramp,
                           scenario_type) {
  n_pairs <- design_n_pairs_wr(
    true_wr,
    target_power = target_power,
    alpha = alpha
  )
  sim_wr <- if (scenario_type == "null") 1 else true_wr

  cat(sprintf(
    "%s: WR %.2f, Kelly %.1f, burn-in %d, ramp %d\n",
    scenario_type, true_wr, kelly_fraction, burn_in, ramp
  ))

  res <- run_adaptive_policy(
    n_sims = n_sims,
    n_pairs = n_pairs,
    true_wr = sim_wr,
    kelly_fraction = kelly_fraction,
    burn_in = burn_in,
    ramp = ramp
  )

  cbind(
    scenario_type = scenario_type,
    true_wr = sim_wr,
    design_wr = true_wr,
    true_d = wr_to_d(sim_wr),
    design_d = wr_to_d(true_wr),
    n_pairs = n_pairs,
    n_patients = 2 * n_pairs,
    design_method = "Yu-Ganju WR",
    kelly_fraction = kelly_fraction,
    burn_in = burn_in,
    ramp = ramp,
    res,
    target_power = target_power,
    alpha = alpha,
    n_sims = n_sims,
    stringsAsFactors = FALSE
  )
}

rows <- list()
for (wr in wr_grid) {
  for (scenario_type in c("null", "alternative")) {
    for (i in seq_len(nrow(tuning_grid))) {
      rows[[length(rows) + 1]] <- run_tuning_row(
        true_wr = wr,
        kelly_fraction = tuning_grid$kelly_fraction[[i]],
        burn_in = tuning_grid$burn_in[[i]],
        ramp = tuning_grid$ramp[[i]],
        scenario_type = scenario_type
      )
    }
  }
}

results <- do.call(rbind, rows)
output_file <- if (mode == "coarse") {
  sprintf("results/ertwr_adaptive_tuning_%s.csv", n_sims)
} else {
  sprintf("results/ertwr_adaptive_tuning_%s_%s.csv", mode, n_sims)
}
write.csv(results, output_file, row.names = FALSE)

cat(sprintf("\nSaved %s\n\n", output_file))
print(results)
