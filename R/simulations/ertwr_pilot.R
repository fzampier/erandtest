# =============================================================================
# e-RTwr Pilot Simulations
# =============================================================================
#
# Disjoint-pair win-ratio e-process for continuous endpoints. The pairwise
# comparison is intentionally simple: higher treatment outcome wins, higher
# control outcome loses, exact ties are possible only if tie_margin > 0.
#
# Run:
#   Rscript R/simulations/ertwr_pilot.R 1000
#
# Output:
#   results/ertwr_pilot_<n_sims>.csv

suppressPackageStartupMessages(source("R/ertwr.R"))

dir.create("results", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 500L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260429)

alpha <- 0.05
target_power <- 0.80
wr_grid <- c(1.10, 1.20, 1.30, 1.50)

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

run_policy <- function(n_sims, n_pairs, true_wr, policy, wager_wr = NA_real_,
                       burn_in = 10, ramp = 50, kelly_fraction = 1.0) {
  d_true <- wr_to_d(true_wr)
  crossings <- rep(NA_integer_, n_sims)
  finals <- numeric(n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_pairwise_continuous(n_pairs, d_true = d_true)

    wealth <- if (policy == "adaptive_full_kelly") {
      compute_eRTwr(
        trial$d_pair,
        wager = "adaptive",
        burn_in = burn_in,
        ramp = ramp,
        kelly_fraction = kelly_fraction
      )
    } else {
      compute_eRTwr(
        trial$d_pair,
        wager = "fixed",
        lambda = wr_to_lambda(wager_wr)
      )
    }

    crossings[[s]] <- threshold_crossing(wealth, alpha)
    finals[[s]] <- tail(wealth, 1)
  }

  summarize_runs(crossings, finals)
}

run_null_scenario <- function(wr_design) {
  n_pairs <- design_n_pairs_continuous(
    wr_design,
    target_power = target_power,
    alpha = alpha
  )

  policies <- data.frame(
    policy = c("adaptive_full_kelly", "fixed_design"),
    wager_wr = c(NA_real_, wr_design),
    wager_misspecification = c("adaptive", "design_under_null"),
    stringsAsFactors = FALSE
  )

  rows <- vector("list", nrow(policies))
  for (i in seq_len(nrow(policies))) {
    cat(sprintf(
      "Null: design WR %.2f, policy %s\n",
      wr_design, policies$policy[[i]]
    ))
    res <- run_policy(
      n_sims = n_sims,
      n_pairs = n_pairs,
      true_wr = 1,
      policy = policies$policy[[i]],
      wager_wr = policies$wager_wr[[i]]
    )
    rows[[i]] <- cbind(
      scenario_type = "null",
      true_wr = 1,
      design_wr = wr_design,
      wager_wr = policies$wager_wr[[i]],
      wager_lambda = ifelse(is.na(policies$wager_wr[[i]]), NA_real_,
                            wr_to_lambda(policies$wager_wr[[i]])),
      policy = policies$policy[[i]],
      wager_misspecification = policies$wager_misspecification[[i]],
      n_pairs = n_pairs,
      n_patients = 2 * n_pairs,
      res,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, rows)
}

run_alt_scenario <- function(true_wr) {
  n_pairs <- design_n_pairs_continuous(
    true_wr,
    target_power = target_power,
    alpha = alpha
  )

  under_wr <- 1 + 0.5 * (true_wr - 1)
  matched_wr <- true_wr
  over_wr <- 1 + 2 * (true_wr - 1)

  policies <- data.frame(
    policy = c(
      "adaptive_full_kelly",
      "fixed_under",
      "fixed_matched",
      "fixed_over"
    ),
    wager_wr = c(NA_real_, under_wr, matched_wr, over_wr),
    wager_misspecification = c(
      "adaptive",
      "underestimated",
      "matched",
      "overestimated"
    ),
    stringsAsFactors = FALSE
  )

  rows <- vector("list", nrow(policies))
  for (i in seq_len(nrow(policies))) {
    cat(sprintf(
      "Alternative: true WR %.2f, policy %s\n",
      true_wr, policies$policy[[i]]
    ))
    res <- run_policy(
      n_sims = n_sims,
      n_pairs = n_pairs,
      true_wr = true_wr,
      policy = policies$policy[[i]],
      wager_wr = policies$wager_wr[[i]]
    )
    rows[[i]] <- cbind(
      scenario_type = "alternative",
      true_wr = true_wr,
      design_wr = true_wr,
      wager_wr = policies$wager_wr[[i]],
      wager_lambda = ifelse(is.na(policies$wager_wr[[i]]), NA_real_,
                            wr_to_lambda(policies$wager_wr[[i]])),
      policy = policies$policy[[i]],
      wager_misspecification = policies$wager_misspecification[[i]],
      n_pairs = n_pairs,
      n_patients = 2 * n_pairs,
      res,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, rows)
}

results <- do.call(
  rbind,
  c(
    lapply(wr_grid, run_null_scenario),
    lapply(wr_grid, run_alt_scenario)
  )
)

results$true_d <- wr_to_d(results$true_wr)
results$design_d <- wr_to_d(results$design_wr)
results$target_power <- target_power
results$alpha <- alpha
results$n_sims <- n_sims

results <- results[, c(
  "scenario_type", "true_wr", "design_wr", "wager_wr", "wager_lambda",
  "true_d", "design_d", "policy", "wager_misspecification",
  "n_pairs", "n_patients", "rejection_rate", "se", "median_crossing",
  "median_final_evalue", "target_power", "alpha", "n_sims"
)]

output_file <- sprintf("results/ertwr_pilot_%s.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

cat(sprintf("\nSaved %s\n\n", output_file))
print(results)
