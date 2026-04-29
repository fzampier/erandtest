# e-RTs: Time-to-Event Sequential Monitoring
#
# The validity engine is the risk-set randomization identity. At each observed
# event, the treatment label of the event is compared with the randomized
# treatment proportion still at risk. Wager policies affect efficiency, not
# validity.

logrank_design_events <- function(design_hr, target_power = 0.80,
                                  alpha = 0.05) {
  if (!is.finite(design_hr) || design_hr <= 0 || design_hr == 1) {
    stop("design_hr must be positive and different from 1")
  }

  z_alpha <- qnorm(1 - alpha / 2)
  z_beta <- qnorm(target_power)
  ceiling(4 * (z_alpha + z_beta)^2 / (log(design_hr)^2))
}

simulate_trial_survival <- function(n, hr = 1, p_trt = 0.5,
                                    baseline_hazard = 1) {
  if (!is.finite(hr) || hr <= 0) stop("hr must be positive")
  if (p_trt <= 0 || p_trt >= 1) stop("p_trt must be in (0, 1)")
  if (!is.finite(baseline_hazard) || baseline_hazard <= 0) {
    stop("baseline_hazard must be positive")
  }

  treatment <- rbinom(n, 1, p_trt)
  hazard <- baseline_hazard * ifelse(treatment == 1, hr, 1)
  time <- rexp(n, rate = hazard)

  data.frame(
    time = time,
    status = 1L,
    treatment = treatment
  )
}

survival_logrank_stream <- function(time, status, treatment) {
  if (length(time) != length(status) || length(time) != length(treatment)) {
    stop("time, status, and treatment must have the same length")
  }
  if (is.factor(treatment)) treatment <- as.numeric(treatment) - 1
  treatment <- as.numeric(treatment)
  status <- as.integer(status)

  if (all(status == 1L)) {
    ord <- order(time, seq_along(time))
    trt <- treatment[ord]
    event_time <- time[ord]
    n <- length(trt)

    risk_total <- rev(seq_len(n))
    risk_trt <- rev(cumsum(rev(trt)))
    p_event_trt <- risk_trt / risk_total
    u <- trt - p_event_trt
    v <- p_event_trt * (1 - p_event_trt)

    out <- data.frame(
      event = seq_len(n),
      time = event_time,
      x = trt,
      p = p_event_trt,
      u = u,
      v = v,
      risk_total = risk_total,
      risk_trt = risk_trt
    )
    return(out[out$v > 0, , drop = FALSE])
  }

  ord <- order(time, 1 - status, seq_along(time))
  time <- time[ord]
  status <- status[ord]
  treatment <- treatment[ord]
  event_rows <- which(status == 1L)

  rows <- lapply(seq_along(event_rows), function(j) {
    idx <- event_rows[[j]]
    at_risk <- time >= time[[idx]]
    risk_total <- sum(at_risk)
    risk_trt <- sum(treatment[at_risk] == 1)
    p_event_trt <- risk_trt / risk_total

    data.frame(
      event = j,
      time = time[[idx]],
      x = treatment[[idx]],
      p = p_event_trt,
      u = treatment[[idx]] - p_event_trt,
      v = p_event_trt * (1 - p_event_trt),
      risk_total = risk_total,
      risk_trt = risk_trt
    )
  })

  out <- do.call(rbind, rows)
  out[out$v > 0, , drop = FALSE]
}

design_event_probability <- function(p, hr) {
  if (!is.finite(hr) || hr <= 0) stop("hr must be positive")
  (hr * p) / (hr * p + (1 - p))
}

design_logrank_lambda <- function(p, hr) {
  q <- design_event_probability(p, hr)
  denom <- p * (1 - p)
  ifelse(denom > 0, (q - p) / denom, 0)
}

compute_eRTs_stream <- function(stream,
                                wager = c("fixed", "adaptive", "design", "oracle"),
                                fixed_lambda = 0.25,
                                hr_design = NULL,
                                hr_oracle = NULL,
                                kelly_fraction = 0.5,
                                burn_in = 30,
                                ramp = 50,
                                alpha = 0.05,
                                lambda_cap = 0.99,
                                ramp_fixed = TRUE) {
  wager <- match.arg(wager)
  if (wager == "design" && is.null(hr_design)) {
    stop("Design wager requires hr_design")
  }
  if (wager == "oracle" && is.null(hr_oracle)) {
    stop("Oracle wager requires hr_oracle")
  }

  n_events <- nrow(stream)
  wealth <- numeric(n_events)
  lambdas <- numeric(n_events)
  multipliers <- numeric(n_events)
  z_cum <- numeric(n_events)
  v_cum <- numeric(n_events)
  beta_hat <- rep(NA_real_, n_events)

  w <- 1
  z_prev <- 0
  v_prev <- 0

  for (j in seq_len(n_events)) {
    c_j <- min(1, max(0, (j - burn_in) / ramp))
    p_j <- stream$p[[j]]

    lambda <- switch(
      wager,
      fixed = {
        if (j <= burn_in || z_prev == 0) {
          0
        } else {
          c_j * fixed_lambda * sign(z_prev)
        }
      },
      adaptive = {
        if (j <= burn_in || v_prev <= 0) {
          0
        } else {
          hr_hat_prev <- exp(z_prev / v_prev)
          c_j * kelly_fraction * design_logrank_lambda(p_j, hr_hat_prev)
        }
      },
      design = {
        target <- design_logrank_lambda(p_j, hr_design)
        if (ramp_fixed) c_j * target else target
      },
      oracle = {
        target <- design_logrank_lambda(p_j, hr_oracle)
        if (ramp_fixed) c_j * target else target
      }
    )

    lambda <- max(-lambda_cap, min(lambda_cap, lambda))
    multiplier <- 1 + lambda * stream$u[[j]]
    multiplier <- max(.Machine$double.eps, multiplier)
    w <- w * multiplier

    z_now <- z_prev + stream$u[[j]]
    v_now <- v_prev + stream$v[[j]]

    wealth[[j]] <- w
    lambdas[[j]] <- lambda
    multipliers[[j]] <- multiplier
    z_cum[[j]] <- z_now
    v_cum[[j]] <- v_now
    beta_hat[[j]] <- if (v_now > 0) z_now / v_now else NA_real_

    z_prev <- z_now
    v_prev <- v_now
  }

  crossing <- which(wealth >= 1 / alpha)
  crossed_at <- if (length(crossing) > 0) crossing[[1]] else NA_integer_

  path <- cbind(
    stream,
    lambda = lambdas,
    multiplier = multipliers,
    wealth = wealth,
    z = z_cum,
    v = v_cum,
    log_hr_hat = beta_hat,
    hr_hat = exp(beta_hat)
  )

  list(
    path = path,
    wealth = wealth,
    crossed_at = crossed_at,
    final_wealth = if (length(wealth) > 0) tail(wealth, 1) else 1,
    final_log_hr = if (length(beta_hat) > 0) tail(beta_hat, 1) else NA_real_,
    final_hr = if (length(beta_hat) > 0) exp(tail(beta_hat, 1)) else NA_real_
  )
}

compute_eRTs <- function(time, status, treatment, ...) {
  stream <- survival_logrank_stream(time, status, treatment)
  compute_eRTs_stream(stream, ...)
}
