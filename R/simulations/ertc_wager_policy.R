# =============================================================================
# V8 e-RTc Wager Policy Comparison
# =============================================================================
#
# Compares the adaptive continuous e-RTc wager with a parametric normal-shift
# design wager. The design wager is a working-model efficiency choice, not a
# validity assumption.
#
# Run:
#   Rscript R/simulations/ertc_wager_policy.R 1000
#
# Outputs:
#   results/ertc_wager_policy_<n_sims>.csv
#   manuscript/ertc_wager_policy_table.tex

suppressPackageStartupMessages(source("R/ertc.R"))

dir.create("results", showWarnings = FALSE)
dir.create("manuscript", showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 500L
if (is.na(n_sims) || n_sims < 1) stop("n_sims must be a positive integer")

set.seed(20260430)

alpha <- 0.05
target_power <- 0.80
mu_ctrl <- 0
sd_true <- 1
burn_in <- 20
ramp <- 50
c_max <- 0.6

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

summarize_crossings <- function(crossings, finals, crossing_effects,
                                final_effects, true_d, n_sims) {
  reject <- !is.na(crossings)
  rate <- mean(reject)
  type_m <- if (is.finite(true_d) && true_d != 0) {
    abs(crossing_effects) / abs(true_d)
  } else {
    rep(NA_real_, n_sims)
  }

  data.frame(
    rejection_rate = rate,
    se = sqrt(rate * (1 - rate) / n_sims),
    median_crossing = if (any(reject)) median(crossings[reject]) else NA_real_,
    median_final_evalue = median(finals),
    median_crossing_d = median_na(crossing_effects[reject]),
    median_final_d = median_na(final_effects),
    median_type_m_at_crossing = median_na(type_m[reject]),
    type_m_q75 = quantile_na(type_m[reject], 0.75),
    type_m_q90 = quantile_na(type_m[reject], 0.90),
    stringsAsFactors = FALSE
  )
}

run_ertc_policy <- function(n_sims, true_d, n_patients, policy,
                            design_d = NA_real_) {
  crossings <- rep(NA_integer_, n_sims)
  finals <- numeric(n_sims)
  crossing_effects <- rep(NA_real_, n_sims)
  final_effects <- rep(NA_real_, n_sims)

  for (s in seq_len(n_sims)) {
    trial <- simulate_trial_continuous(
      n_patients,
      mu_ctrl = mu_ctrl,
      mu_trt = mu_ctrl + true_d * sd_true,
      sd = sd_true
    )

    wealth <- switch(
      policy,
      adaptive = compute_eRTc(
        trial$treatment, trial$outcome,
        burn_in = burn_in, ramp = ramp, c_max = c_max,
        wager = "adaptive"
      ),
      design = compute_eRTc(
        trial$treatment, trial$outcome,
        burn_in = burn_in, ramp = ramp, c_max = c_max,
        wager = "design",
        mu_ctrl_design = mu_ctrl,
        mu_trt_design = mu_ctrl + design_d * sd_true,
        sd_design = sd_true
      ),
      oracle = compute_eRTc(
        trial$treatment, trial$outcome,
        burn_in = burn_in, ramp = ramp, c_max = c_max,
        wager = "oracle",
        mu_ctrl_oracle = mu_ctrl,
        mu_trt_oracle = mu_ctrl + true_d * sd_true,
        sd_oracle = sd_true
      ),
      stop("Unknown policy")
    )

    crossings[[s]] <- threshold_crossing(wealth, alpha)
    finals[[s]] <- tail(wealth, 1)
    final_effects[[s]] <- cohens_d_estimate(trial$treatment, trial$outcome)
    if (!is.na(crossings[[s]])) {
      crossing_effects[[s]] <- cohens_d_estimate(
        trial$treatment,
        trial$outcome,
        upto = crossings[[s]]
      )
    }
  }

  summarize_crossings(
    crossings = crossings,
    finals = finals,
    crossing_effects = crossing_effects,
    final_effects = final_effects,
    true_d = true_d,
    n_sims = n_sims
  )
}

run_scenario <- function(design_d, true_d) {
  n_patients <- design_n_continuous(
    design_d,
    target_power = target_power,
    alpha = alpha,
    sd = sd_true
  )
  scenario_type <- if (true_d == 0) "null" else "alternative"

  cat(sprintf(
    "\nScenario: design d=%.2f true d=%.2f N=%d (%s)\n",
    design_d, true_d, n_patients, scenario_type
  ))

  policies <- if (true_d == 0) {
    data.frame(
      policy = c("adaptive", "design"),
      design_d_wager = c(NA_real_, design_d),
      wager_misspecification = c("adaptive", "design_under_null")
    )
  } else {
    data.frame(
      policy = c("adaptive", "design", "design", "design", "oracle"),
      design_d_wager = c(NA_real_, true_d / 2, true_d, true_d * 2, true_d),
      wager_misspecification = c(
        "adaptive", "underestimated", "matched", "overestimated", "oracle"
      )
    )
  }

  rows <- lapply(seq_len(nrow(policies)), function(j) {
    cat(sprintf("  e-RTc: %s\n", policies$wager_misspecification[[j]]))
    res <- run_ertc_policy(
      n_sims = n_sims,
      true_d = true_d,
      n_patients = n_patients,
      policy = policies$policy[[j]],
      design_d = policies$design_d_wager[[j]]
    )

    cbind(
      endpoint = "e-RTc",
      policy = policies$policy[[j]],
      wager_misspecification = policies$wager_misspecification[[j]],
      design_d = design_d,
      true_d = true_d,
      design_d_wager = policies$design_d_wager[[j]],
      n_patients = n_patients,
      res,
      scenario_type = scenario_type,
      target_power = target_power,
      alpha = alpha,
      n_sims = n_sims,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, rows)
}

design_ds <- c(0.20, 0.40, 0.60)
results <- do.call(
  rbind,
  c(
    lapply(design_ds, function(d) run_scenario(design_d = d, true_d = 0)),
    lapply(design_ds, function(d) run_scenario(design_d = d, true_d = d))
  )
)

output_file <- sprintf("results/ertc_wager_policy_%s.csv", n_sims)
write.csv(results, output_file, row.names = FALSE)

format_pct <- function(x) sprintf("%.1f\\%%", 100 * x)
format_num <- function(x, digits = 2) {
  ifelse(is.na(x), "--", sprintf(paste0("%.", digits, "f"), x))
}
format_int <- function(x) {
  ifelse(is.na(x), "--", formatC(as.integer(round(x)), format = "d", big.mark = "{,}"))
}

type1 <- subset(results, scenario_type == "null")
type1$policy_display <- ifelse(
  type1$wager_misspecification == "adaptive",
  "Adaptive",
  "Design"
)
type1 <- type1[order(type1$design_d, type1$policy_display), ]

power <- subset(
  results,
  scenario_type == "alternative" &
    wager_misspecification %in% c("adaptive", "underestimated", "matched", "overestimated")
)
power$policy_display <- ifelse(
  power$wager_misspecification == "adaptive",
  "Adaptive",
  ifelse(
    power$wager_misspecification == "underestimated",
    "Design under",
    ifelse(power$wager_misspecification == "matched", "Design matched", "Design over")
  )
)
power$policy_order <- match(
  power$policy_display,
  c("Adaptive", "Design under", "Design matched", "Design over")
)
power <- power[order(power$true_d, power$policy_order), ]

type1_rows <- vapply(seq_len(nrow(type1)), function(i) {
  x <- type1[i, ]
  sprintf(
    "%.2f & %s & %s & %s & %s \\\\",
    x$design_d,
    x$policy_display,
    format_int(x$n_patients),
    format_pct(x$rejection_rate),
    format_num(x$median_final_evalue, 2)
  )
}, character(1))

power_rows <- vapply(seq_len(nrow(power)), function(i) {
  x <- power[i, ]
  sprintf(
    "%.2f & %s & %s & %s & %s & %s & %s & %s \\\\",
    x$true_d,
    x$policy_display,
    format_num(x$design_d_wager, 2),
    format_int(x$n_patients),
    format_pct(x$rejection_rate),
    format_int(x$median_crossing),
    format_num(x$median_crossing_d, 2),
    format_num(x$median_type_m_at_crossing, 2)
  )
}, character(1))

table_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Type I error for e-RTc adaptive and parametric design wagers. Each row summarizes 1{,}000 simulated null trials. Sample sizes use the usual fixed-sample two-sample $t$-test with 80\\% power and $\\alpha = 0.05$.}",
  "\\label{tab:ertc_design_type1}",
  "\\begin{tabular}{@{}llrrr@{}}",
  "\\toprule",
  "Design $d$ & Policy & $N$ & Type I & Median final e-value \\\\",
  "\\midrule",
  type1_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}",
  "",
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Power and Type M error for e-RTc adaptive and parametric design wagers. The effect scale is Cohen's $d$; Type M is computed among trials that crossed.}",
  "\\label{tab:ertc_design_power_type_m}",
  "\\begin{tabular}{@{}lllrrrrr@{}}",
  "\\toprule",
  "True $d$ & Policy & Wager $d$ & $N$ & Power & Median crossing & Crossing $d$ & Median M \\\\",
  "\\midrule",
  power_rows,
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(table_lines, "manuscript/ertc_wager_policy_table.tex")

cat(sprintf("\nSaved %s\n", output_file))
cat("Saved manuscript/ertc_wager_policy_table.tex\n\n")
print(results)
