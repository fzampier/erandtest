# =============================================================================
# e-RTwr: Win-Ratio / Pairwise-Comparison E-Process
# =============================================================================
#
# First-pass implementation for disjoint treatment-control pairs. Each pair
# contributes D = +1 if treatment wins, D = -1 if control wins, and D = 0 for
# ties. The e-process is W_j = W_{j-1} * (1 + lambda_j * D_j).

wr_to_lambda <- function(wr) {
  if (any(!is.finite(wr)) || any(wr <= 0)) {
    stop("WR must be positive and finite")
  }
  (wr - 1) / (wr + 1)
}

lambda_to_wr <- function(lambda) {
  if (any(!is.finite(lambda)) || any(abs(lambda) >= 1)) {
    stop("lambda must be finite and strictly inside (-1, 1)")
  }
  (1 + lambda) / (1 - lambda)
}

d_to_wr <- function(d) {
  p_win <- pnorm(d / sqrt(2))
  p_win / (1 - p_win)
}

wr_to_d <- function(wr) {
  p_win <- wr / (1 + wr)
  sqrt(2) * qnorm(p_win)
}

simulate_pairwise_continuous <- function(n_pairs, d_true = 0, sd = 1,
                                         higher_better = TRUE,
                                         tie_margin = 0) {
  y_ctrl <- rnorm(n_pairs, mean = 0, sd = sd)
  y_trt <- rnorm(n_pairs, mean = d_true * sd, sd = sd)
  diff <- if (higher_better) y_trt - y_ctrl else y_ctrl - y_trt

  d_pair <- ifelse(
    abs(diff) <= tie_margin,
    0,
    ifelse(diff > 0, 1, -1)
  )

  data.frame(
    pair = seq_len(n_pairs),
    y_trt = y_trt,
    y_ctrl = y_ctrl,
    d_pair = d_pair
  )
}

compute_eRTwr <- function(d_pair, lambda = NULL,
                          wager = c("adaptive", "fixed"),
                          burn_in = 10, ramp = 50,
                          kelly_fraction = 1.0) {
  wager <- match.arg(wager)
  n <- length(d_pair)
  wealth <- numeric(n)

  wins <- 0
  losses <- 0

  for (j in seq_len(n)) {
    if (wager == "adaptive") {
      informative <- wins + losses
      edge_hat <- if (informative > 0) {
        (wins - losses) / informative
      } else {
        0
      }
      ramp_frac <- max(0, min(1, (j - burn_in) / ramp))
      lambda_j <- ramp_frac * kelly_fraction * edge_hat
    } else {
      if (is.null(lambda)) stop("Fixed wager requires lambda")
      lambda_j <- lambda
    }

    lambda_j <- max(-0.999, min(0.999, lambda_j))
    multiplier <- 1 + lambda_j * d_pair[[j]]
    wealth[[j]] <- if (j == 1) multiplier else wealth[[j - 1]] * multiplier

    if (d_pair[[j]] == 1) {
      wins <- wins + 1
    } else if (d_pair[[j]] == -1) {
      losses <- losses + 1
    }
  }

  wealth
}

design_n_pairs_continuous <- function(wr_design, target_power = 0.80,
                                      alpha = 0.05) {
  d_design <- wr_to_d(wr_design)
  ss <- power.t.test(
    delta = d_design,
    sd = 1,
    sig.level = alpha,
    power = target_power,
    type = "two.sample",
    alternative = "two.sided"
  )
  ceiling(ss$n)
}

threshold_crossing <- function(wealth, alpha = 0.05) {
  crossing <- which(wealth >= 1 / alpha)
  if (length(crossing) == 0) NA_integer_ else crossing[[1]]
}
