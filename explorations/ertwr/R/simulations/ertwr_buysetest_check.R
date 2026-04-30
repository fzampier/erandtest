# =============================================================================
# e-RTwr BuyseTest Cross-Check
# =============================================================================
#
# Confirms that the internal all-pairs continuous WR agrees with BuyseTest for
# small simulated continuous-endpoint trials. This is a validation check, not the
# main simulation engine: BuyseTest is deliberately not called inside each
# manuscript-grade e-RTwr replicate because that would be much slower.
#
# Run:
#   Rscript explorations/ertwr/R/simulations/ertwr_buysetest_check.R 100 80
#
# Output:
#   explorations/ertwr/results/ertwr_buysetest_check_<n_sims>.csv

suppressPackageStartupMessages(source("explorations/ertwr/R/ertwr.R"))

dir.create("results", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 100L
n_pairs <- if (length(args) >= 2) as.integer(args[[2]]) else 80L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")
if (is.na(n_pairs) || n_pairs < 2) stop("n_pairs must be at least 2")

if (!requireNamespace("BuyseTest", quietly = TRUE)) {
  stop("BuyseTest is required for this check")
}

set.seed(20260430)

wr_grid <- c(1.00, 1.10, 1.20, 1.30, 1.50)

rows <- list()
for (true_wr in wr_grid) {
  d_true <- if (true_wr == 1) 0 else wr_to_d(true_wr)

  for (s in seq_len(n_sims)) {
    trial <- simulate_pairwise_continuous(n_pairs, d_true = d_true)

    internal <- all_pairs_wr_continuous(trial$y_trt, trial$y_ctrl)
    buyse <- buysetest_wr_continuous(trial$y_trt, trial$y_ctrl)

    rows[[length(rows) + 1]] <- data.frame(
      true_wr = true_wr,
      sim = s,
      n_pairs = n_pairs,
      internal_wr = internal$wr,
      buysetest_wr = buyse$wr,
      abs_diff = abs(internal$wr - buyse$wr),
      log_ratio = log(internal$wr / buyse$wr),
      wins = internal$wins,
      losses = internal$losses,
      ties = internal$ties,
      stringsAsFactors = FALSE
    )
  }
}

results <- do.call(rbind, rows)
output_file <- sprintf("explorations/ertwr/results/ertwr_buysetest_check_%s.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

summary <- aggregate(
  cbind(abs_diff, abs_log_ratio = abs(log_ratio)) ~ true_wr,
  data = results,
  FUN = max
)

cat(sprintf("\nSaved %s\n\n", output_file))
print(summary, row.names = FALSE)
