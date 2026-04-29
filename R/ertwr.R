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

wr_sigma_sqr_yu_ganju <- function(k = 0.5, p_tie = 0) {
  if (!is.finite(k) || k <= 0 || k >= 1) {
    stop("k must be a treatment-allocation proportion strictly between 0 and 1")
  }
  if (!is.finite(p_tie) || p_tie < 0 || p_tie >= 1) {
    stop("p_tie must be finite and in [0, 1)")
  }
  4 * (1 + p_tie) / (3 * k * (1 - k) * (1 - p_tie))
}

design_n_total_wr <- function(wr_design, target_power = 0.80, alpha = 0.05,
                              k = 0.5, p_tie = 0,
                              prefer_wrestimates = TRUE) {
  if (any(!is.finite(wr_design)) || any(wr_design <= 1)) {
    stop("wr_design must be finite and greater than 1")
  }

  alpha_one_sided <- alpha / 2
  beta <- 1 - target_power

  if (prefer_wrestimates && requireNamespace("WRestimates", quietly = TRUE)) {
    ss <- WRestimates::wr.ss(
      WR.true = wr_design,
      alpha = alpha_one_sided,
      beta = beta,
      k = k,
      p.tie = p_tie
    )
    return(ceiling(ss$N))
  }

  sigma_sqr <- wr_sigma_sqr_yu_ganju(k = k, p_tie = p_tie)
  z_alpha <- qnorm(1 - alpha_one_sided)
  z_beta <- qnorm(1 - beta)
  ceiling(sigma_sqr * (z_alpha + z_beta)^2 / log(wr_design)^2)
}

design_n_pairs_wr <- function(wr_design, target_power = 0.80, alpha = 0.05,
                              k = 0.5, p_tie = 0,
                              prefer_wrestimates = TRUE) {
  ceiling(design_n_total_wr(
    wr_design = wr_design,
    target_power = target_power,
    alpha = alpha,
    k = k,
    p_tie = p_tie,
    prefer_wrestimates = prefer_wrestimates
  ) / 2)
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

wr_from_counts <- function(wins, losses) {
  if (losses == 0) {
    if (wins == 0) NA_real_ else Inf
  } else {
    wins / losses
  }
}

sequential_wr <- function(d_pair, upto = length(d_pair)) {
  if (length(d_pair) == 0 || is.na(upto) || upto < 1) {
    return(list(wins = NA_integer_, losses = NA_integer_, ties = NA_integer_,
                wr = NA_real_))
  }

  upto <- min(length(d_pair), as.integer(upto))
  d_sub <- d_pair[seq_len(upto)]
  wins <- sum(d_sub == 1)
  losses <- sum(d_sub == -1)
  ties <- sum(d_sub == 0)

  list(
    wins = wins,
    losses = losses,
    ties = ties,
    wr = wr_from_counts(wins, losses)
  )
}

all_pairs_wr_continuous <- function(y_trt, y_ctrl, higher_better = TRUE,
                                    tie_margin = 0) {
  if (length(y_trt) == 0 || length(y_ctrl) == 0) {
    return(list(wins = NA_real_, losses = NA_real_, ties = NA_real_,
                wr = NA_real_))
  }

  if (!higher_better) {
    y_trt <- -y_trt
    y_ctrl <- -y_ctrl
  }

  ctrl_sorted <- sort(y_ctrl)
  lower <- y_trt - tie_margin
  upper <- y_trt + tie_margin

  wins_by_trt <- findInterval(lower, ctrl_sorted, left.open = TRUE)
  le_upper <- findInterval(upper, ctrl_sorted)
  ties_by_trt <- pmax(0, le_upper - wins_by_trt)

  wins <- sum(wins_by_trt)
  ties <- sum(ties_by_trt)
  losses <- length(y_trt) * length(y_ctrl) - wins - ties

  list(
    wins = wins,
    losses = losses,
    ties = ties,
    wr = wr_from_counts(wins, losses)
  )
}

buysetest_wr_continuous <- function(y_trt, y_ctrl, higher_better = TRUE,
                                    tie_margin = 0, trace = 0,
                                    return_fit = FALSE) {
  if (!requireNamespace("BuyseTest", quietly = TRUE)) {
    out <- list(
      wins = NA_real_,
      losses = NA_real_,
      ties = NA_real_,
      wr = NA_real_,
      available = FALSE
    )
    if (return_fit) out$fit <- NULL
    return(out)
  }

  if (length(y_trt) == 0 || length(y_ctrl) == 0) {
    out <- list(
      wins = NA_real_,
      losses = NA_real_,
      ties = NA_real_,
      wr = NA_real_,
      available = TRUE
    )
    if (return_fit) out$fit <- NULL
    return(out)
  }

  suppressPackageStartupMessages(
    require("BuyseTest", quietly = TRUE, character.only = TRUE)
  )

  score <- c(y_trt, y_ctrl)
  if (!higher_better) score <- -score

  df <- data.frame(
    treatment = factor(
      c(rep(1, length(y_trt)), rep(0, length(y_ctrl))),
      levels = c(0, 1)
    ),
    score = score
  )

  fit <- suppressWarnings(BuyseTest::BuyseTest(
    treatment ~ C(score, threshold = tie_margin),
    data = df,
    trace = trace
  ))

  wr <- as.numeric(BuyseTest::coef(fit, statistic = "winRatio")[[1]])
  counts <- all_pairs_wr_continuous(
    y_trt = y_trt,
    y_ctrl = y_ctrl,
    higher_better = higher_better,
    tie_margin = tie_margin
  )

  out <- list(
    wins = counts$wins,
    losses = counts$losses,
    ties = counts$ties,
    wr = wr,
    available = TRUE
  )
  if (return_fit) out$fit <- fit
  out
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
