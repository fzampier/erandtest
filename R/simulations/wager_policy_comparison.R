# =============================================================================
# V8 Wager Policy Comparison: e-RTb and e-RTe
# =============================================================================
#
# Compares adaptive half-Kelly e-RTb and adaptive full-Kelly e-RTe against
# design-fixed full-Kelly wagers. Oracle full-Kelly is included only as a
# simulation benchmark.
#
# Run:
#   Rscript R/simulations/wager_policy_comparison.R 5000
#
# Output:
#   results/wager_policy_<n_sims>_same_n.csv

suppressPackageStartupMessages(source("R/ertb.R"))
suppressPackageStartupMessages(source("R/erte.R"))

dir.create("results", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 5000L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260428)

erte_inflation <- 1

threshold_crossing <- function(wealth, alpha) {
  crossing <- which(wealth >= 1 / alpha)
  if (length(crossing) == 0) NA_integer_ else crossing[[1]]
}

median_na <- function(x) {
  if (all(is.na(x))) NA_real_ else median(x, na.rm = TRUE)
}

quantile_na <- function(x, prob) {
  if (all(is.na(x))) NA_real_ else unname(quantile(x, prob, na.rm = TRUE))
}

summarize_crossings <- function(crossings, finals, n_sims,
                                crossing_effects = rep(NA_real_, n_sims),
                                final_effects = rep(NA_real_, n_sims),
                                true_effect = NA_real_) {
  reject <- !is.na(crossings)
  rate <- mean(reject)

  type_m <- if (is.finite(true_effect) && true_effect != 0) {
    crossing_effects / true_effect
  } else {
    rep(NA_real_, n_sims)
  }

  data.frame(
    rejection_rate = rate,
    se = sqrt(rate * (1 - rate) / n_sims),
    median_crossing = if (any(reject)) median(crossings[reject]) else NA_real_,
    median_final_evalue = median(finals),
    median_crossing_effect = median_na(crossing_effects[reject]),
    median_final_effect = median_na(final_effects),
    median_type_m_at_crossing = median_na(type_m[reject]),
    type_m_q25 = quantile_na(type_m[reject], 0.25),
    type_m_q75 = quantile_na(type_m[reject], 0.75),
    type_m_q90 = quantile_na(type_m[reject], 0.90),
    stringsAsFactors = FALSE
  )
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

arr_estimate <- function(treatment, outcome, upto = length(treatment)) {
  if (is.na(upto) || upto < 1) return(NA_real_)
  upto <- min(length(treatment), as.integer(upto))
  idx <- seq_len(upto)
  trt <- treatment[idx] == 1
  ctrl <- treatment[idx] == 0
  if (!any(trt) || !any(ctrl)) return(NA_real_)
  mean(outcome[idx][ctrl]) - mean(outcome[idx][trt])
}

event_coin_tilt <- function(events, upto = length(events)) {
  if (is.na(upto) || upto < 1) return(NA_real_)
  upto <- min(length(events), as.integer(upto))
  0.5 - mean(events[seq_len(upto)])
}

event_stream_from_trial <- function(trial) {
  event_idx <- which(trial$outcome == 1)
  list(
    arms = trial$treatment[event_idx],
    patient_index = event_idx
  )
}

run_ertb_policy <- function(n_sims, p_ctrl, p_trt, n_patients, alpha,
                            policy, p_ctrl_wager = NULL, p_trt_wager = NULL,
                            burn_in = 50, ramp = 100) {
  crossings <- rep(NA_integer_, n_sims)
  finals <- numeric(n_sims)
  crossing_effects <- rep(NA_real_, n_sims)
  final_effects <- rep(NA_real_, n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)

    wealth <- switch(
      policy,
      adaptive_half_kelly = compute_eRT(
        trial$treatment, trial$outcome,
        burn_in = burn_in, ramp = ramp, wager = "adaptive"
      ),
      design_full_kelly = compute_eRT(
        trial$treatment, trial$outcome,
        burn_in = burn_in, ramp = ramp, wager = "design",
        p_trt_design = p_trt_wager, p_ctrl_design = p_ctrl_wager
      ),
      oracle_full_kelly = compute_eRT(
        trial$treatment, trial$outcome,
        burn_in = burn_in, ramp = ramp, wager = "oracle",
        p_trt_oracle = p_trt, p_ctrl_oracle = p_ctrl
      ),
      stop("Unknown e-RTb policy")
    )

    crossings[[s]] <- threshold_crossing(wealth, alpha)
    finals[[s]] <- tail(wealth, 1)
    final_effects[[s]] <- arr_estimate(trial$treatment, trial$outcome)
    if (!is.na(crossings[[s]])) {
      crossing_effects[[s]] <- arr_estimate(
        trial$treatment,
        trial$outcome,
        upto = crossings[[s]]
      )
    }
  }

  summarize_crossings(
    crossings = crossings,
    finals = finals,
    n_sims = n_sims,
    crossing_effects = crossing_effects,
    final_effects = final_effects,
    true_effect = p_ctrl - p_trt
  )
}

run_erte_policy <- function(n_sims, p_ctrl, p_trt, n_patients, alpha,
                            policy, p_ctrl_wager = NULL, p_trt_wager = NULL,
                            burn_in = 30, ramp = 50) {
  n_events <- expected_events(n_patients, p_ctrl, p_trt)
  p_coin <- event_coin(p_ctrl, p_trt)
  crossings <- rep(NA_integer_, n_sims)
  finals <- numeric(n_sims)
  crossing_effects <- rep(NA_real_, n_sims)
  final_effects <- rep(NA_real_, n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_trial(n_patients, rate_trt = p_trt, rate_ctrl = p_ctrl)
    event_stream <- event_stream_from_trial(trial)
    events <- event_stream$arms
    final_effects[[s]] <- arr_estimate(trial$treatment, trial$outcome)

    if (length(events) == 0) {
      crossings[[s]] <- NA_integer_
      finals[[s]] <- 1
      next
    }

    res <- switch(
      policy,
      adaptive_full_kelly = compute_eRTe(
        events,
        burn_in = burn_in, ramp = ramp, threshold = 1 / alpha,
        wager = "adaptive"
      ),
      design_full_kelly = compute_eRTe(
        events,
        burn_in = burn_in, ramp = ramp, threshold = 1 / alpha,
        wager = "design",
        p_trt_design = p_trt_wager, p_ctrl_design = p_ctrl_wager
      ),
      oracle_full_kelly = compute_eRTe(
        events,
        burn_in = burn_in, ramp = ramp, threshold = 1 / alpha,
        wager = "oracle",
        p_trt_oracle = p_trt, p_ctrl_oracle = p_ctrl
      ),
      stop("Unknown e-RTe policy")
    )

    crossings[[s]] <- res$crossed_at
    finals[[s]] <- tail(res$wealth, 1)
    if (!is.na(crossings[[s]])) {
      crossing_patient <- event_stream$patient_index[[crossings[[s]]]]
      crossing_effects[[s]] <- arr_estimate(
        trial$treatment,
        trial$outcome,
        upto = crossing_patient
      )
    }
  }

  out <- summarize_crossings(
    crossings = crossings,
    finals = finals,
    n_sims = n_sims,
    crossing_effects = crossing_effects,
    final_effects = final_effects,
    true_effect = p_ctrl - p_trt
  )
  out$n_events <- n_events
  out$event_coin <- p_coin
  out
}

run_scenario <- function(p_ctrl, sample_size_arr, true_arr,
                         target_power = 0.80, alpha = 0.05,
                         erte_inflation = 1) {
  p_trt_true <- p_ctrl - true_arr
  n_freq <- design_n_binary(p_ctrl, sample_size_arr, target_power, alpha)
  n_ertb <- n_freq
  n_erte <- ceiling(n_freq * erte_inflation)

  scenario_type <- if (true_arr == 0) {
    "null"
  } else {
    "alternative"
  }

  cat(sprintf(
    "\nScenario: p_ctrl=%.2f sample-size ARR=%.2f true ARR=%.2f (%s)\n",
    p_ctrl, sample_size_arr, true_arr, scenario_type
  ))

  rows <- list()

  if (true_arr == 0) {
    fixed_wagers <- data.frame(
      policy = c("fixed_5pp_full_kelly", "fixed_10pp_full_kelly"),
      wager_arr = c(0.05, 0.10),
      wager_misspecification = c("fixed_5pp_under_null", "fixed_10pp_under_null")
    )
  } else {
    fixed_wagers <- data.frame(
      policy = c("fixed_under_full_kelly", "fixed_matched_full_kelly", "fixed_over_full_kelly"),
      wager_arr = c(true_arr / 2, true_arr, min(0.15, true_arr * 2)),
      wager_misspecification = c("underestimated", "matched", "overestimated")
    )
  }

  ertb_policies <- rbind(
    data.frame(policy = "adaptive_half_kelly", wager_arr = NA_real_,
               wager_misspecification = "adaptive"),
    fixed_wagers,
    if (true_arr > 0) {
      data.frame(policy = "oracle_full_kelly", wager_arr = true_arr,
                 wager_misspecification = "oracle")
    }
  )

  for (j in seq_len(nrow(ertb_policies))) {
    policy_label <- ertb_policies$policy[[j]]
    engine_policy <- if (policy_label == "adaptive_half_kelly") {
      "adaptive_half_kelly"
    } else if (policy_label == "oracle_full_kelly") {
      "oracle_full_kelly"
    } else {
      "design_full_kelly"
    }
    wager_arr <- ertb_policies$wager_arr[[j]]
    p_trt_wager <- if (is.na(wager_arr)) NULL else p_ctrl - wager_arr

    cat(sprintf("  e-RTb: %s\n", policy_label))
    res <- run_ertb_policy(
      n_sims = n_sims,
      p_ctrl = p_ctrl,
      p_trt = p_trt_true,
      n_patients = n_ertb,
      alpha = alpha,
      policy = engine_policy,
      p_ctrl_wager = p_ctrl,
      p_trt_wager = p_trt_wager
    )
    rows[[length(rows) + 1]] <- cbind(
      endpoint = "e-RTb",
      policy = policy_label,
      wager_arr = wager_arr,
      wager_misspecification = ertb_policies$wager_misspecification[[j]],
      res,
      n_patients = n_ertb,
      n_events = NA_real_,
      event_coin = NA_real_,
      effect_scale = "ARR",
      true_effect = true_arr,
      stringsAsFactors = FALSE
    )
  }

  erte_policies <- rbind(
    data.frame(policy = "adaptive_full_kelly", wager_arr = NA_real_,
               wager_misspecification = "adaptive"),
    fixed_wagers,
    if (true_arr > 0) {
      data.frame(policy = "oracle_full_kelly", wager_arr = true_arr,
                 wager_misspecification = "oracle")
    }
  )

  for (j in seq_len(nrow(erte_policies))) {
    policy_label <- erte_policies$policy[[j]]
    engine_policy <- if (policy_label == "adaptive_full_kelly") {
      "adaptive_full_kelly"
    } else if (policy_label == "oracle_full_kelly") {
      "oracle_full_kelly"
    } else {
      "design_full_kelly"
    }
    wager_arr <- erte_policies$wager_arr[[j]]
    p_trt_wager <- if (is.na(wager_arr)) NULL else p_ctrl - wager_arr

    cat(sprintf("  e-RTe: %s\n", policy_label))
    res <- run_erte_policy(
      n_sims = n_sims,
      p_ctrl = p_ctrl,
      p_trt = p_trt_true,
      n_patients = n_erte,
      alpha = alpha,
      policy = engine_policy,
      p_ctrl_wager = p_ctrl,
      p_trt_wager = p_trt_wager
    )
    rows[[length(rows) + 1]] <- cbind(
      endpoint = "e-RTe",
      policy = policy_label,
      wager_arr = wager_arr,
      wager_misspecification = erte_policies$wager_misspecification[[j]],
      res,
      n_patients = n_erte,
      effect_scale = "ARR_at_crossing_snapshot",
      true_effect = true_arr,
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, rows)
  out$p_ctrl <- p_ctrl
  out$p_trt_true <- p_trt_true
  out$sample_size_arr <- sample_size_arr
  out$true_arr <- true_arr
  out$scenario_type <- scenario_type
  out$n_freq <- n_freq
  out$erte_inflation <- erte_inflation
  out$target_power <- target_power
  out$alpha <- alpha
  out$n_sims <- n_sims
  out
}

p_ctrl <- 0.40
scenarios <- data.frame(
  sample_size_arr = c(0.05, 0.10, 0.05, 0.10),
  true_arr = c(0.00, 0.00, 0.05, 0.10)
)

results <- do.call(
  rbind,
  lapply(seq_len(nrow(scenarios)), function(i) {
    run_scenario(
      p_ctrl = p_ctrl,
      sample_size_arr = scenarios$sample_size_arr[[i]],
      true_arr = scenarios$true_arr[[i]],
      erte_inflation = erte_inflation
    )
  })
)

results <- results[, c(
  "endpoint", "policy", "scenario_type",
  "p_ctrl", "p_trt_true", "sample_size_arr", "true_arr",
  "wager_arr", "wager_misspecification",
  "n_patients", "n_events", "event_coin",
  "effect_scale", "true_effect",
  "rejection_rate", "se", "median_crossing", "median_final_evalue",
  "median_crossing_effect", "median_final_effect",
  "median_type_m_at_crossing", "type_m_q25", "type_m_q75", "type_m_q90",
  "n_freq", "erte_inflation", "target_power", "alpha", "n_sims"
)]

output_file <- sprintf("results/wager_policy_%s_same_n.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

cat(sprintf("\nSaved %s\n\n", output_file))
print(results)
