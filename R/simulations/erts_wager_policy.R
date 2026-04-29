# =============================================================================
# V8 e-RTs Wager Policy Comparison
# =============================================================================
#
# Compares the V7 fixed-sign log-rank e-RTs wager with adaptive and
# design/Sokolova-like risk-set wagers. The design wager uses the prespecified
# hazard ratio to compute the event-arm probability under a proportional hazards
# working alternative, then converts that probability into the GROW-optimal
# multiplier on the e-RTs log-rank increment scale.
#
# Run:
#   Rscript R/simulations/erts_wager_policy.R 1000
#
# Outputs:
#   results/erts_wager_policy_<n_sims>.csv
#   manuscript/erts_wager_policy_table.tex

suppressPackageStartupMessages(source("R/erts.R"))

dir.create("results", showWarnings = FALSE)
dir.create("manuscript", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 500L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260501)

alpha <- 0.05
target_power <- 0.80
burn_in <- 30
ramp <- 50
fixed_lambda <- 0.25
adaptive_kelly_fraction <- 0.5
hr_scenarios <- c(0.90, 0.80, 0.70)

median_na <- function(x) {
  if (length(x) == 0 || all(is.na(x))) NA_real_ else median(x, na.rm = TRUE)
}

quantile_na <- function(x, prob) {
  if (length(x) == 0 || all(is.na(x))) {
    NA_real_
  } else {
    unname(quantile(x, prob, na.rm = TRUE))
  }
}

format_pct <- function(x) {
  ifelse(is.na(x), "--", sprintf("%.1f\\%%", 100 * x))
}

format_num <- function(x, digits = 2) {
  ifelse(is.na(x), "--", sprintf(paste0("%.", digits, "f"), x))
}

format_int <- function(x) {
  ifelse(is.na(x), "--", formatC(as.integer(round(x)), format = "d", big.mark = "{,}"))
}

hr_under <- function(true_hr) {
  (1 + true_hr) / 2
}

hr_over <- function(true_hr) {
  max(0.05, true_hr - (1 - true_hr) / 2)
}

policy_grid <- function(true_hr, include_under_over = TRUE) {
  base <- data.frame(
    policy = c("fixed", "adaptive", "design"),
    policy_display = c("Fixed 0.25", "Adaptive half", "Design matched"),
    wager_misspecification = c("fixed", "adaptive", "matched"),
    hr_wager = c(NA_real_, NA_real_, true_hr),
    stringsAsFactors = FALSE
  )

  if (!include_under_over) return(base)

  rbind(
    base[1:2, ],
    data.frame(
      policy = "design",
      policy_display = "Design under",
      wager_misspecification = "underestimated",
      hr_wager = hr_under(true_hr),
      stringsAsFactors = FALSE
    ),
    base[3, ],
    data.frame(
      policy = "design",
      policy_display = "Design over",
      wager_misspecification = "overestimated",
      hr_wager = hr_over(true_hr),
      stringsAsFactors = FALSE
    ),
    data.frame(
      policy = "oracle",
      policy_display = "Oracle",
      wager_misspecification = "oracle",
      hr_wager = true_hr,
      stringsAsFactors = FALSE
    )
  )
}

run_policy_on_stream <- function(stream, spec, true_hr) {
  switch(
    spec$policy,
    fixed = compute_eRTs_stream(
      stream,
      wager = "fixed",
      fixed_lambda = fixed_lambda,
      burn_in = burn_in,
      ramp = ramp,
      alpha = alpha
    ),
    adaptive = compute_eRTs_stream(
      stream,
      wager = "adaptive",
      kelly_fraction = adaptive_kelly_fraction,
      burn_in = burn_in,
      ramp = ramp,
      alpha = alpha
    ),
    design = compute_eRTs_stream(
      stream,
      wager = "design",
      hr_design = spec$hr_wager,
      burn_in = burn_in,
      ramp = ramp,
      alpha = alpha
    ),
    oracle = compute_eRTs_stream(
      stream,
      wager = "oracle",
      hr_oracle = true_hr,
      burn_in = burn_in,
      ramp = ramp,
      alpha = alpha
    ),
    stop("Unknown policy")
  )
}

summarize_records <- function(records, true_hr, n_events, n_sims) {
  crossed <- !is.na(records$crossing_event)
  rate <- mean(crossed)

  if (is.finite(true_hr) && true_hr != 1) {
    true_beta <- log(true_hr)
    type_m <- abs(records$crossing_log_hr) / abs(true_beta)
    type_s <- sign(records$crossing_log_hr) != sign(true_beta)
  } else {
    type_m <- rep(NA_real_, n_sims)
    type_s <- rep(NA, n_sims)
  }

  data.frame(
    rejection_rate = rate,
    se = sqrt(rate * (1 - rate) / n_sims),
    median_crossing = median_na(records$crossing_event[crossed]),
    median_crossing_frac = median_na(records$crossing_event[crossed] / n_events),
    median_final_evalue = median_na(records$final_evalue),
    median_crossing_log_hr = median_na(records$crossing_log_hr[crossed]),
    median_crossing_hr = median_na(exp(records$crossing_log_hr[crossed])),
    median_final_log_hr = median_na(records$final_log_hr),
    median_final_hr = median_na(exp(records$final_log_hr)),
    median_type_m = median_na(type_m[crossed]),
    type_m_q75 = quantile_na(type_m[crossed], 0.75),
    type_m_q90 = quantile_na(type_m[crossed], 0.90),
    type_s_rate = if (any(crossed) && true_hr != 1) {
      mean(type_s[crossed], na.rm = TRUE)
    } else {
      NA_real_
    },
    n_crossed = sum(crossed),
    stringsAsFactors = FALSE
  )
}

run_scenario <- function(true_hr, planning_hr, scenario_type) {
  n_events <- logrank_design_events(
    planning_hr,
    target_power = target_power,
    alpha = alpha
  )
  specs <- policy_grid(planning_hr, include_under_over = scenario_type != "null")

  cat(sprintf(
    "\nScenario: %s true HR=%.2f planning HR=%.2f events=%d\n",
    scenario_type, true_hr, planning_hr, n_events
  ))

  records <- lapply(seq_len(nrow(specs)), function(i) {
    data.frame(
      sim = integer(),
      crossing_event = integer(),
      crossing_log_hr = numeric(),
      final_evalue = numeric(),
      final_log_hr = numeric()
    )
  })

  for (s in seq_len(n_sims)) {
    if (s %% 100 == 0) {
      cat(sprintf("  simulated %d / %d\n", s, n_sims))
    }
    trial <- simulate_trial_survival(n_events, hr = true_hr)
    stream <- survival_logrank_stream(trial$time, trial$status, trial$treatment)

    for (i in seq_len(nrow(specs))) {
      res <- run_policy_on_stream(stream, specs[i, ], true_hr = true_hr)
      crossing_log_hr <- if (is.na(res$crossed_at)) {
        NA_real_
      } else {
        res$path$log_hr_hat[[res$crossed_at]]
      }

      records[[i]] <- rbind(
        records[[i]],
        data.frame(
          sim = s,
          crossing_event = res$crossed_at,
          crossing_log_hr = crossing_log_hr,
          final_evalue = res$final_wealth,
          final_log_hr = res$final_log_hr
        )
      )
    }
  }

  rows <- lapply(seq_len(nrow(specs)), function(i) {
    res <- summarize_records(
      records[[i]],
      true_hr = true_hr,
      n_events = n_events,
      n_sims = n_sims
    )

    cbind(
      endpoint = "e-RTs",
      scenario_type = scenario_type,
      true_hr = true_hr,
      planning_hr = planning_hr,
      policy = specs$policy[[i]],
      policy_display = specs$policy_display[[i]],
      wager_misspecification = specs$wager_misspecification[[i]],
      hr_wager = specs$hr_wager[[i]],
      n_events = n_events,
      n_patients = n_events,
      res,
      target_power = target_power,
      alpha = alpha,
      n_sims = n_sims,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

type1_results <- do.call(
  rbind,
  lapply(hr_scenarios, function(planning_hr) {
    rows <- run_scenario(true_hr = 1, planning_hr = planning_hr, scenario_type = "null")
    subset(rows, policy_display %in% c("Fixed 0.25", "Adaptive half", "Design matched"))
  })
)

power_results <- do.call(
  rbind,
  lapply(hr_scenarios, function(true_hr) {
    rows <- run_scenario(true_hr = true_hr, planning_hr = true_hr, scenario_type = "alternative")
    subset(rows, policy_display != "Oracle")
  })
)

results <- rbind(type1_results, power_results)
output_file <- sprintf("results/erts_wager_policy_%s.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

type1 <- type1_results[
  order(
    type1_results$planning_hr,
    match(type1_results$policy_display, c("Fixed 0.25", "Adaptive half", "Design matched"))
  ),
]
power <- power_results[
  order(
    power_results$true_hr,
    match(
      power_results$policy_display,
      c("Fixed 0.25", "Adaptive half", "Design under", "Design matched", "Design over")
    )
  ),
]

type1_rows <- vapply(seq_len(nrow(type1)), function(i) {
  x <- type1[i, ]
  sprintf(
    "%.2f & %s & %s & %s & %s \\\\",
    x$planning_hr,
    x$policy_display,
    format_int(x$n_events),
    format_pct(x$rejection_rate),
    format_num(x$median_final_evalue, 2)
  )
}, character(1))

power_rows <- vapply(seq_len(nrow(power)), function(i) {
  x <- power[i, ]
  sprintf(
    "%.2f & %s & %s & %s & %s & %s & %s & %s \\\\",
    x$true_hr,
    x$policy_display,
    ifelse(is.na(x$hr_wager), "--", sprintf("%.2f", x$hr_wager)),
    format_pct(x$rejection_rate),
    format_int(x$median_crossing),
    format_num(x$median_crossing_hr, 2),
    format_num(x$median_type_m, 2),
    format_pct(x$type_s_rate)
  )
}, character(1))

table_text <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{e-RTs Type I error simulations under HR $=1$. Planning event counts use the Schoenfeld log-rank event formula for 80\\% fixed-sample power at two-sided $\\alpha=0.05$.}",
  "\\label{tab:erts_wager_policy_type1}",
  "\\small",
  "\\begin{tabular}{@{}llrrr@{}}",
  "\\toprule",
  "Planning HR & Policy & Events & Type I error & Median final e-value \\\\",
  "\\midrule",
  type1_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}",
  "",
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{e-RTs power and crossing diagnostics. Sample sizes use the Schoenfeld log-rank event formula for 80\\% fixed-sample power at two-sided $\\alpha=0.05$. Type M and Type S are summarized among trials that crossed the e-value threshold. Type M is computed on the $|\\log(\\mathrm{HR})|$ scale.}",
  "\\label{tab:erts_wager_policy_power}",
  "\\small",
  "\\begin{tabular}{@{}llrrrrrr@{}}",
  "\\toprule",
  "True HR & Policy & Wager HR & Power & Crossing & HR at crossing & Type M & Type S \\\\",
  "\\midrule",
  power_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(table_text, "manuscript/erts_wager_policy_table.tex")

cat(sprintf("\nWrote %s and manuscript/erts_wager_policy_table.tex\n", output_file))
