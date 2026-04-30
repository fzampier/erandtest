# =============================================================================
# Composite e-RTwr / BuyseTest Simulation
# =============================================================================
#
# Uses BuyseTest::simBuyseTest() to generate a prioritized composite endpoint:
#
#   1. time to event: eventtime/status, higher eventtime favorable;
#   2. binary toxicity: "no" toxicity favorable;
#   3. continuous score: higher score favorable.
#
# BuyseTest supplies the final all-pairs GPC/win-ratio analysis and pair-level
# scores. A disjoint random treatment-control matching is then pulled from those
# pair scores to run an e-RTwr-style sequential monitor on the same composite
# endpoint definition.
#
# Run:
#   Rscript explorations/ertwr/R/simulations/ertwr_composite_buysetest.R 300 250
#
# Output:
#   explorations/ertwr/results/ertwr_composite_buysetest_<n_sims>_<n_per_arm>.csv

suppressPackageStartupMessages({
  source("explorations/ertwr/R/ertwr.R")
  library(BuyseTest)
})

dir.create("results", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 300L
n_per_arm <- if (length(args) >= 2) as.integer(args[[2]]) else 250L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")
if (is.na(n_per_arm) || n_per_arm < 10) stop("n_per_arm must be at least 10")

set.seed(20260502)

alpha <- 0.05
design_wr <- 1.30
lambda_design <- wr_to_lambda(design_wr)

scenario_specs <- list(
  null = list(
    scale.T = 1.00,
    scale.C = 1.00,
    tox.T = 0.30,
    tox.C = 0.30,
    mu.T = 0.00,
    mu.C = 0.00
  ),
  composite_alt = list(
    scale.T = 1.30,
    scale.C = 1.00,
    tox.T = 0.20,
    tox.C = 0.30,
    mu.T = 0.25,
    mu.C = 0.00
  )
)

simulate_composite_data <- function(spec, n_per_arm) {
  BuyseTest::simBuyseTest(
    n.T = n_per_arm,
    n.C = n_per_arm,
    argsTTE = list(
      scale.T = spec$scale.T,
      scale.C = spec$scale.C,
      scale.censoring.T = 6,
      scale.censoring.C = 6,
      name = "eventtime",
      name.censoring = "status"
    ),
    argsBin = list(
      p.T = list(c(yes = spec$tox.T, no = 1 - spec$tox.T)),
      p.C = list(c(yes = spec$tox.C, no = 1 - spec$tox.C)),
      name = "toxicity"
    ),
    argsCont = list(
      mu.T = spec$mu.T,
      mu.C = spec$mu.C,
      sigma.T = 1,
      sigma.C = 1,
      name = "score"
    ),
    format = "data.frame"
  )
}

fit_composite_buyse <- function(dat) {
  suppressWarnings(BuyseTest::BuyseTest(
    treatment ~
      TTE(eventtime, status = status, threshold = 0) +
      B(toxicity) +
      C(score, threshold = 0),
    data = dat,
    hierarchical = TRUE,
    scoring.rule = "Gehan",
    method.inference = "u-statistic",
    keep.pairScore = TRUE,
    trace = 0
  ))
}

extract_global_wr <- function(fit) {
  unname(tail(BuyseTest::coef(fit, statistic = "winRatio"), 1))
}

extract_global_p <- function(fit) {
  ci <- BuyseTest::confint(
    fit,
    statistic = "winRatio",
    alternative = "greater"
  )
  unname(tail(ci$p.value, 1))
}

extract_disjoint_scores <- function(fit, dat) {
  pair_scores <- BuyseTest::getPairScore(
    fit,
    cumulative = TRUE,
    trace = 0
  )
  final_scores <- pair_scores[[length(pair_scores)]]

  c_index <- which(dat$treatment == "C")
  t_index <- which(dat$treatment == "T")
  t_index <- sample(t_index, length(c_index), replace = FALSE)

  selected <- data.frame(
    index.C = c_index,
    index.T = t_index
  )

  merged <- merge(
    selected,
    final_scores,
    by = c("index.C", "index.T"),
    all.x = TRUE,
    sort = FALSE
  )

  d_pair <- merged$favorable - merged$unfavorable
  d_pair[is.na(d_pair)] <- 0
  d_pair
}

compute_numeric_eprocess <- function(d_pair, wager = c("adaptive", "fixed"),
                                     lambda = NULL, burn_in = 10, ramp = 50,
                                     kelly_fraction = 1.0) {
  wager <- match.arg(wager)
  n <- length(d_pair)
  wealth <- numeric(n)
  sum_d <- 0
  n_seen <- 0

  for (j in seq_len(n)) {
    if (wager == "adaptive") {
      edge_hat <- if (n_seen > 0) sum_d / n_seen else 0
      ramp_frac <- max(0, min(1, (j - burn_in) / ramp))
      lambda_j <- ramp_frac * kelly_fraction * edge_hat
    } else {
      if (is.null(lambda)) stop("Fixed wager requires lambda")
      lambda_j <- lambda
    }

    lambda_j <- max(-0.999, min(0.999, lambda_j))
    multiplier <- 1 + lambda_j * d_pair[[j]]
    wealth[[j]] <- if (j == 1) multiplier else wealth[[j - 1]] * multiplier

    sum_d <- sum_d + d_pair[[j]]
    n_seen <- n_seen + 1
  }

  wealth
}

summarize_vector <- function(x, fun) {
  if (all(is.na(x))) NA_real_ else fun(x, na.rm = TRUE)
}

run_one <- function(scenario_name, spec) {
  dat <- simulate_composite_data(spec, n_per_arm)
  fit <- fit_composite_buyse(dat)

  global_wr <- extract_global_wr(fit)
  global_p <- extract_global_p(fit)
  d_pair <- extract_disjoint_scores(fit, dat)

  adaptive_wealth <- compute_numeric_eprocess(d_pair, wager = "adaptive")
  fixed_wealth <- compute_numeric_eprocess(
    d_pair,
    wager = "fixed",
    lambda = lambda_design
  )

  adaptive_crossing <- threshold_crossing(adaptive_wealth, alpha)
  fixed_crossing <- threshold_crossing(fixed_wealth, alpha)

  data.frame(
    scenario = scenario_name,
    n_per_arm = n_per_arm,
    design_wr = design_wr,
    buysetest_wr = global_wr,
    buysetest_p = global_p,
    buysetest_reject = is.finite(global_p) && global_p <= alpha,
    disjoint_wins = sum(d_pair > 0),
    disjoint_losses = sum(d_pair < 0),
    disjoint_neutral = sum(d_pair == 0),
    disjoint_wr = wr_from_counts(sum(d_pair > 0), sum(d_pair < 0)),
    adaptive_reject = !is.na(adaptive_crossing),
    adaptive_crossing = adaptive_crossing,
    adaptive_final_evalue = tail(adaptive_wealth, 1),
    fixed_reject = !is.na(fixed_crossing),
    fixed_crossing = fixed_crossing,
    fixed_final_evalue = tail(fixed_wealth, 1),
    stringsAsFactors = FALSE
  )
}

rows <- vector("list", n_sims * length(scenario_specs))
idx <- 1

for (scenario_name in names(scenario_specs)) {
  for (s in seq_len(n_sims)) {
    if (s %% 25 == 0) {
      cat(sprintf("%s: simulation %s / %s\n", scenario_name, s, n_sims))
    }
    rows[[idx]] <- run_one(scenario_name, scenario_specs[[scenario_name]])
    rows[[idx]]$sim <- s
    idx <- idx + 1
  }
}

results <- do.call(rbind, rows)
output_file <- sprintf(
  "explorations/ertwr/results/ertwr_composite_buysetest_%s_%s.csv",
  n_sims,
  n_per_arm
)
write.csv(results, output_file, row.names = FALSE)

summary <- do.call(
  rbind,
  lapply(split(results, results$scenario), function(x) {
    data.frame(
      scenario = x$scenario[[1]],
      buysetest_rejection_rate = mean(x$buysetest_reject),
      adaptive_rejection_rate = mean(x$adaptive_reject),
      fixed_rejection_rate = mean(x$fixed_reject),
      median_buysetest_wr = median(x$buysetest_wr, na.rm = TRUE),
      median_disjoint_wr = median(x$disjoint_wr, na.rm = TRUE),
      median_adaptive_crossing = summarize_vector(x$adaptive_crossing, median),
      median_fixed_crossing = summarize_vector(x$fixed_crossing, median),
      median_adaptive_final_evalue = median(x$adaptive_final_evalue, na.rm = TRUE),
      median_fixed_final_evalue = median(x$fixed_final_evalue, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
)

cat(sprintf("\nSaved %s\n\n", output_file))
print(summary, row.names = FALSE)
