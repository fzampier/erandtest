# =============================================================================
# e-RTwr Versus Sokolova-Style GROW Comparator
# =============================================================================
#
# Compares four related targets for the simple continuous win/loss/tie setting:
#
# 1. A conventional final all-pairs WR test at the Yu-Ganju sample size.
# 2. Adaptive/agnotic e-RTwr at the same Yu-Ganju sample size.
# 3. Fixed-design/GROW e-RTwr at the same Yu-Ganju sample size.
# 4. A Sokolova-style GROW e-design analogue: same fixed GROW wager, but
#    Nmax is calibrated so the e-process has about target_power crossing
#    probability by Nmax.
#
# This is not a claim that evalinger implements continuous WR monitoring.
# It applies the same paired e-process algebra used by evalinger's binary
# eprocess_binary() to continuous pairwise signs, D in {-1, +1}.
#
# Run:
#   Rscript R/simulations/ertwr_sokolova_comparison.R 1000
#
# Output:
#   results/ertwr_sokolova_comparison_<n_sims>.csv

suppressPackageStartupMessages(source("R/ertwr.R"))

dir.create("results", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260501)

alpha <- 0.05
target_power <- 0.80
wr_grid <- c(1.10, 1.20, 1.30, 1.50)

median_crossing <- function(crossings) {
  finite <- crossings[!is.na(crossings)]
  if (length(finite) == 0) NA_real_ else median(finite)
}

simulate_fixed_crossings <- function(n_sims, n_pairs, true_wr, wager_wr,
                                     alpha = 0.05, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  p_win <- true_wr / (1 + true_wr)
  lambda <- wr_to_lambda(wager_wr)
  threshold <- log(1 / alpha)
  log_e <- numeric(n_sims)
  crossings <- rep(NA_integer_, n_sims)

  for (j in seq_len(n_pairs)) {
    d_pair <- ifelse(runif(n_sims) < p_win, 1, -1)
    log_e <- log_e + log1p(lambda * d_pair)
    newly_crossed <- is.na(crossings) & log_e >= threshold
    crossings[newly_crossed] <- j
  }

  list(crossings = crossings, final_log_e = log_e)
}

simulate_adaptive_crossings <- function(n_sims, n_pairs, true_wr,
                                        alpha = 0.05, burn_in = 10,
                                        ramp = 50, kelly_fraction = 1.0,
                                        seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  p_win <- true_wr / (1 + true_wr)
  threshold <- log(1 / alpha)
  log_e <- numeric(n_sims)
  crossings <- rep(NA_integer_, n_sims)
  wins <- integer(n_sims)
  losses <- integer(n_sims)

  for (j in seq_len(n_pairs)) {
    informative <- wins + losses
    edge_hat <- ifelse(informative > 0, (wins - losses) / informative, 0)
    ramp_frac <- max(0, min(1, (j - burn_in) / ramp))
    lambda_j <- ramp_frac * kelly_fraction * edge_hat
    lambda_j <- pmax(-0.999, pmin(0.999, lambda_j))

    d_pair <- ifelse(runif(n_sims) < p_win, 1, -1)
    log_e <- log_e + log1p(lambda_j * d_pair)
    newly_crossed <- is.na(crossings) & log_e >= threshold
    crossings[newly_crossed] <- j

    wins <- wins + as.integer(d_pair == 1)
    losses <- losses + as.integer(d_pair == -1)
  }

  list(crossings = crossings, final_log_e = log_e)
}

calibrate_fixed_n <- function(n_sims, base_pairs, true_wr, wager_wr,
                              alpha = 0.05, target_power = 0.80,
                              seed = NULL) {
  max_pairs <- max(base_pairs, ceiling(1.5 * base_pairs))

  repeat {
    sim <- simulate_fixed_crossings(
      n_sims = n_sims,
      n_pairs = max_pairs,
      true_wr = true_wr,
      wager_wr = wager_wr,
      alpha = alpha,
      seed = seed
    )
    finite <- sort(sim$crossings[!is.na(sim$crossings)])
    if (length(finite) >= ceiling(target_power * n_sims)) {
      n_target <- finite[[ceiling(target_power * n_sims)]]
      return(list(
        n_pairs = n_target,
        crossings = sim$crossings,
        achieved_power = mean(!is.na(sim$crossings) & sim$crossings <= n_target)
      ))
    }

    max_pairs <- ceiling(1.5 * max_pairs)
    if (max_pairs > 20 * base_pairs) {
      stop("Could not calibrate fixed GROW N within 20x base_pairs")
    }
  }
}

final_wr_test_power <- function(wr, n_pairs, alpha = 0.05) {
  n_total <- 2 * n_pairs
  sigma_sqr <- wr_sigma_sqr_yu_ganju(k = 0.5, p_tie = 0)
  mu_z <- log(wr) * sqrt(n_total / sigma_sqr)
  z <- qnorm(1 - alpha / 2)
  1 - pnorm(z - mu_z) + pnorm(-z - mu_z)
}

summarize_eprocess <- function(sim, n_pairs, method, true_wr, design_wr,
                               sample_size_rule, wager_rule,
                               null_rejection_rate = NA_real_) {
  data.frame(
    true_wr = true_wr,
    design_wr = design_wr,
    method = method,
    sample_size_rule = sample_size_rule,
    wager_rule = wager_rule,
    n_pairs = n_pairs,
    n_patients = 2 * n_pairs,
    rejection_rate = mean(!is.na(sim$crossings) & sim$crossings <= n_pairs),
    null_rejection_rate = null_rejection_rate,
    se = {
      p <- mean(!is.na(sim$crossings) & sim$crossings <= n_pairs)
      sqrt(p * (1 - p) / length(sim$crossings))
    },
    median_crossing = median_crossing(ifelse(sim$crossings <= n_pairs,
                                             sim$crossings, NA_integer_)),
    median_final_evalue = median(exp(pmin(sim$final_log_e, 700))),
    alpha = alpha,
    n_sims = n_sims,
    stringsAsFactors = FALSE
  )
}

rows <- list()

for (wr in wr_grid) {
  n_yu_pairs <- design_n_pairs_wr(
    wr_design = wr,
    target_power = target_power,
    alpha = alpha
  )

  cat(sprintf("WR %.2f: Yu-Ganju pairs %s\n", wr, n_yu_pairs))

  final_power <- final_wr_test_power(wr, n_yu_pairs, alpha = alpha)
  rows[[length(rows) + 1]] <- data.frame(
    true_wr = wr,
    design_wr = wr,
    method = "Final all-pairs WR test",
    sample_size_rule = "Yu-Ganju 80% final-test N",
    wager_rule = "No wager; fixed final analysis",
    n_pairs = n_yu_pairs,
    n_patients = 2 * n_yu_pairs,
    rejection_rate = final_power,
    null_rejection_rate = alpha,
    se = NA_real_,
    median_crossing = NA_real_,
    median_final_evalue = NA_real_,
    alpha = alpha,
    n_sims = n_sims,
    stringsAsFactors = FALSE
  )

  adaptive_alt <- simulate_adaptive_crossings(
    n_sims = n_sims,
    n_pairs = n_yu_pairs,
    true_wr = wr,
    alpha = alpha,
    seed = 20260501 + round(100 * wr)
  )
  adaptive_null <- simulate_adaptive_crossings(
    n_sims = n_sims,
    n_pairs = n_yu_pairs,
    true_wr = 1,
    alpha = alpha,
    seed = 20260551 + round(100 * wr)
  )
  rows[[length(rows) + 1]] <- summarize_eprocess(
    sim = adaptive_alt,
    n_pairs = n_yu_pairs,
    method = "e-RTwr adaptive",
    true_wr = wr,
    design_wr = wr,
    sample_size_rule = "Yu-Ganju 80% final-test N",
    wager_rule = "Agnostic full Kelly, burn-in 10, ramp 50",
    null_rejection_rate = mean(!is.na(adaptive_null$crossings))
  )

  fixed_alt <- simulate_fixed_crossings(
    n_sims = n_sims,
    n_pairs = n_yu_pairs,
    true_wr = wr,
    wager_wr = wr,
    alpha = alpha,
    seed = 20260601 + round(100 * wr)
  )
  fixed_null <- simulate_fixed_crossings(
    n_sims = n_sims,
    n_pairs = n_yu_pairs,
    true_wr = 1,
    wager_wr = wr,
    alpha = alpha,
    seed = 20260651 + round(100 * wr)
  )
  rows[[length(rows) + 1]] <- summarize_eprocess(
    sim = fixed_alt,
    n_pairs = n_yu_pairs,
    method = "e-RTwr fixed/GROW same N",
    true_wr = wr,
    design_wr = wr,
    sample_size_rule = "Yu-Ganju 80% final-test N",
    wager_rule = "Fixed lambda = (WR - 1) / (WR + 1)",
    null_rejection_rate = mean(!is.na(fixed_null$crossings))
  )

  calibrated <- calibrate_fixed_n(
    n_sims = n_sims,
    base_pairs = n_yu_pairs,
    true_wr = wr,
    wager_wr = wr,
    alpha = alpha,
    target_power = target_power,
    seed = 20260701 + round(100 * wr)
  )
  fixed_null_calibrated <- simulate_fixed_crossings(
    n_sims = n_sims,
    n_pairs = calibrated$n_pairs,
    true_wr = 1,
    wager_wr = wr,
    alpha = alpha,
    seed = 20260801 + round(100 * wr)
  )
  cal_row <- summarize_eprocess(
    sim = list(
      crossings = ifelse(calibrated$crossings <= calibrated$n_pairs,
                         calibrated$crossings, NA_integer_),
      final_log_e = rep(NA_real_, n_sims)
    ),
    n_pairs = calibrated$n_pairs,
    method = "Sokolova-style GROW e-design",
    true_wr = wr,
    design_wr = wr,
    sample_size_rule = "N calibrated to 80% anytime power",
    wager_rule = "Fixed GROW lambda from design WR"
  )
  cal_row$null_rejection_rate <- mean(!is.na(fixed_null_calibrated$crossings))
  rows[[length(rows) + 1]] <- cal_row
}

results <- do.call(rbind, rows)
results$yu_ganju_pairs <- design_n_pairs_wr(results$design_wr)
results$n_ratio_to_yu_ganju <- results$n_pairs / results$yu_ganju_pairs
results$null_rejection_rate <- ifelse(
  is.na(results$null_rejection_rate),
  NA_real_,
  results$null_rejection_rate
)

output_file <- sprintf("results/ertwr_sokolova_comparison_%s.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

cat(sprintf("\nSaved %s\n\n", output_file))
print(results)
